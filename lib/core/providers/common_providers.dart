import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'common_providers.g.dart';

// ---------------------------------------------------------------------------
// Cloud Function base URLs — derived from the Firebase project (ecom-750fc).
// Update if functions are re-deployed to a different region.
// ---------------------------------------------------------------------------
const getRazorpayKeyUrl =
    'https://us-central1-ecom-750fc.cloudfunctions.net/getRazorpayKey';
const createRazorpayOrderUrl =
    'https://us-central1-ecom-750fc.cloudfunctions.net/createRazorpayOrder';
const verifyAndFinalizePaymentUrl =
    'https://us-central1-ecom-750fc.cloudfunctions.net/verifyAndFinalizePayment';

// ---------------------------------------------------------------------------
// App Check token helper — never throws.
// App Check is defence-in-depth; a missing/expired token must never block
// payment flows. Rate-limit errors, "activate() not called", and any other
// App Check failure are swallowed here and the caller simply omits the header.
// ---------------------------------------------------------------------------
Future<String?> _safeAppCheckToken() async {
  try {
    return await FirebaseAppCheck.instance.getToken();
  } catch (e) {
    debugPrint('[APP_CHECK] getToken() failed (non-fatal): $e');
    return null;
  }
}

// ---------------------------------------------------------------------------
// Core Firebase Providers
// ---------------------------------------------------------------------------

@riverpod
FirebaseFirestore firebaseFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

@riverpod
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
}

@riverpod
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

/// The single source of truth for Firebase Auth's authentication state.
/// Backed directly by [FirebaseAuth.authStateChanges], so it updates
/// immediately on sign-in/sign-out — including the very first emission,
/// when Firebase resolves whatever session was persisted on disk.
///
/// Until that first emission arrives this provider is in its loading
/// state (`AsyncLoading`). Callers that need to tell "still resolving"
/// apart from "definitely signed out" should watch this provider
/// directly instead of [currentUserIdProvider], which collapses both
/// cases to `null`.
@riverpod
Stream<User?> firebaseAuthState(Ref ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
}

/// The current Firebase Auth user id, derived from
/// [firebaseAuthStateProvider]. Returns null both while the auth state is
/// still loading AND when the user is signed out — screens that must not
/// flash a "guest" UI during startup should watch
/// [firebaseAuthStateProvider] directly rather than relying on this.
@riverpod
String? currentUserId(Ref ref) {
  return ref.watch(firebaseAuthStateProvider).value?.uid;
}

// ---------------------------------------------------------------------------
// Store name resolution — uses ref.read (not ref.watch) inside FutureProvider
// to avoid reactive re-triggering on firestore instance rebuild.
// ---------------------------------------------------------------------------
final storeNameProvider = FutureProvider.family<String, String>((
  ref,
  storeId,
) async {
  if (storeId.isEmpty) return 'Official Store';
  try {
    final doc = await ref
        .read(firebaseFirestoreProvider) // FIX BUG #10: ref.read, not ref.watch
        .collection('stores')
        .doc(storeId)
        .get()
        .timeout(const Duration(seconds: 10));
    if (doc.exists) {
      return doc.data()?['storeName'] as String? ?? 'Official Store';
    }
  } catch (e) {
    debugPrint(
      '[FIRESTORE][ERROR] storeNameProvider: Failed to fetch store name for $storeId: $e',
    );
  }
  return 'Official Store';
});

// ---------------------------------------------------------------------------
// Razorpay Key Provider — fetches the PUBLIC key ID from Cloud Function.
// Throws on failure so the UI shows an actionable error instead of silently
// proceeding with a placeholder key (which causes Razorpay to reject the key).
// ---------------------------------------------------------------------------
final razorpayKeyProvider = FutureProvider<String>((ref) async {
  final url = getRazorpayKeyUrl;
  debugPrint('[RAZORPAY] razorpayKeyProvider: Fetching key from $url');

  try {
    final appCheckToken = await _safeAppCheckToken();
    final response = await http
        .get(Uri.parse(url), headers: {'X-Firebase-AppCheck': ?appCheckToken})
        .timeout(
          const Duration(seconds: 15),
        ); // Increased: CF cold start can take ~10s

    debugPrint(
      '[RAZORPAY] razorpayKeyProvider: HTTP status: ${response.statusCode}',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final key = data['key'] as String?;

      if (key == null || key.trim().isEmpty) {
        debugPrint(
          '[RAZORPAY][ERROR] Key is null or empty in Cloud Function response.',
        );
        throw Exception(
          'Payment system returned an empty key. Contact support.',
        );
      }

      debugPrint(
        '[RAZORPAY] Key fetched successfully (prefix): ${key.substring(0, 12)}...',
      );
      return key.trim();
    } else {
      final body = response.body;
      debugPrint(
        '[RAZORPAY][ERROR] Cloud Function error. status=${response.statusCode}, body=$body',
      );
      throw Exception(
        'Payment system unavailable (HTTP ${response.statusCode}). Please try again.',
      );
    }
  } catch (e) {
    debugPrint('[RAZORPAY][ERROR] razorpayKeyProvider network error: $e');
    final errStr = e.toString();
    if (errStr.contains('Payment system unavailable') ||
        errStr.contains('empty key') ||
        errStr.contains('Contact support')) {
      rethrow;
    }
    throw Exception(
      'Cannot connect to payment system. Check your internet connection.',
    );
  }
});

// ---------------------------------------------------------------------------
// createRazorpayOrder — calls the Cloud Function to create a server-side
// Razorpay order. Returns { id, amount, currency }.
// Requires the caller to pass the Firebase ID token for auth.
// ---------------------------------------------------------------------------
Future<Map<String, dynamic>> createRazorpayOrder({
  required int amountInPaise,
  required String idToken,
  String currency = 'INR',
  String? receipt,
}) async {
  final url = createRazorpayOrderUrl;
  debugPrint(
    '[RAZORPAY] createRazorpayOrder: POST $url | amount=$amountInPaise paise',
  );

  try {
    final Map<String, dynamic> bodyPayload = {
      'amount': amountInPaise,
      'currency': currency,
    };
    if (receipt != null) {
      bodyPayload['receipt'] = receipt;
    }

    final appCheckToken = await _safeAppCheckToken();
    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
            'X-Firebase-AppCheck': ?appCheckToken,
          },
          body: json.encode(bodyPayload),
        )
        .timeout(const Duration(seconds: 30));

    debugPrint(
      '[RAZORPAY] createRazorpayOrder: HTTP status=${response.statusCode}',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      debugPrint('[RAZORPAY][SUCCESS] Razorpay order created: ${data['id']}');
      return data;
    } else {
      final errBody = json.decode(response.body) as Map<String, dynamic>;
      final errMsg = errBody['error'] as String? ?? 'Unknown error';
      debugPrint('[RAZORPAY][ERROR] createRazorpayOrder failed: $errMsg');
      throw Exception('Failed to create payment order: $errMsg');
    }
  } on Exception {
    rethrow;
  } catch (e) {
    debugPrint('[RAZORPAY][ERROR] createRazorpayOrder network error: $e');
    throw Exception(
      'Network error while creating payment order. Check your connection.',
    );
  }
}

// ---------------------------------------------------------------------------
// verifyAndFinalizePayment — calls the Cloud Function to verify Hmac signature
// and atomically create Firestore orders + deduct stock + clear cart.
// Returns { success: true, orderIds: [...] }.
// ---------------------------------------------------------------------------
Future<Map<String, dynamic>> verifyAndFinalizePayment({
  required String razorpayPaymentId,
  required String razorpayOrderId,
  required String razorpaySignature,
  required String buyerId,
  required String buyerName,
  required String deliveryAddress,
  required List<Map<String, dynamic>> orders,
  required String idToken,
  String? couponCode,
}) async {
  final url = verifyAndFinalizePaymentUrl;
  debugPrint(
    '[PAYMENT] verifyAndFinalizePayment: POST $url'
    ' | paymentId=$razorpayPaymentId | buyerId=$buyerId | coupon=$couponCode',
  );

  try {
    final appCheckToken = await _safeAppCheckToken();
    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
            'X-Firebase-AppCheck': ?appCheckToken,
          },
          body: json.encode({
            'razorpay_payment_id': razorpayPaymentId,
            'razorpay_order_id': razorpayOrderId,
            'razorpay_signature': razorpaySignature,
            'buyerId': buyerId,
            'buyerName': buyerName,
            'deliveryAddress': deliveryAddress,
            'orders': orders,
            'couponCode': ?couponCode,
          }),
        )
        .timeout(const Duration(seconds: 60));

    debugPrint(
      '[PAYMENT] verifyAndFinalizePayment: HTTP status=${response.statusCode}',
    );

    final responseBody = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && responseBody['success'] == true) {
      final orderIds = List<String>.from(
        responseBody['orderIds'] as List? ?? [],
      );
      debugPrint('[PAYMENT][SUCCESS] Orders finalized: ${orderIds.join(', ')}');
      return responseBody;
    } else {
      final errMsg =
          responseBody['error'] as String? ?? 'Payment finalization failed';
      debugPrint('[PAYMENT][ERROR] verifyAndFinalizePayment: $errMsg');
      throw Exception(errMsg);
    }
  } on Exception {
    rethrow;
  } catch (e) {
    debugPrint('[PAYMENT][ERROR] verifyAndFinalizePayment network error: $e');
    throw Exception(
      'Network error during payment finalization. Please contact support.',
    );
  }
}
