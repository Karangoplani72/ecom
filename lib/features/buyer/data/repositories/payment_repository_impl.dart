import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/admin/domain/entities/platform_config.dart';
import 'package:ecom/features/auth/domain/entities/user_address.dart';
import 'package:ecom/features/buyer/data/dtos/payment_transaction_dto.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/domain/entities/payment_transaction.dart';
import 'package:ecom/features/buyer/domain/repositories/payment_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFirestore _firestore;
  final http.Client _httpClient;

  PaymentRepositoryImpl({required this._firestore, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  // ── fetchRazorpayKey ────────────────────────────────────────────────────────

  @override
  Future<Either<String, String>> fetchRazorpayKey() async {
    try {
      debugPrint('[PAYMENT_REPO] fetchRazorpayKey → $getRazorpayKeyUrl');
      final response = await _httpClient
          .get(Uri.parse(getRazorpayKeyUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final key = data['key'] as String?;
        if (key == null || key.trim().isEmpty) {
          return const Left(
            'Payment system returned an empty key. Contact support.',
          );
        }
        return Right(key.trim());
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final err = body['error'] as String? ?? 'HTTP ${response.statusCode}';
      debugPrint('[PAYMENT_REPO][ERROR] fetchRazorpayKey: $err');
      return Left('Payment system unavailable: $err');
    } catch (e) {
      debugPrint('[PAYMENT_REPO][ERROR] fetchRazorpayKey exception: $e');
      return Left(
        'Cannot connect to payment system. Check your internet connection.',
      );
    }
  }

  // ── createOrder ─────────────────────────────────────────────────────────────

  @override
  Future<Either<String, Map<String, dynamic>>> createOrder({
    required int amountInPaise,
    required String idToken,
    String currency = 'INR',
    String? receipt,
  }) async {
    try {
      debugPrint('[PAYMENT_REPO] createOrder: amount=$amountInPaise paise');
      final body = <String, dynamic>{
        'amount': amountInPaise,
        'currency': currency,
        'receipt': ?receipt,
      };

      final response = await _httpClient
          .post(
            Uri.parse(createRazorpayOrderUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        debugPrint('[PAYMENT_REPO] createOrder success: ${data['id']}');
        return Right(data);
      }

      final err = data['error'] as String? ?? 'Order creation failed';
      debugPrint('[PAYMENT_REPO][ERROR] createOrder: $err');
      return Left(err);
    } catch (e) {
      debugPrint('[PAYMENT_REPO][ERROR] createOrder exception: $e');
      return Left('Network error while creating payment order.');
    }
  }

  // ── verifyAndFinalize ───────────────────────────────────────────────────────

  @override
  Future<Either<String, List<String>>> verifyAndFinalize({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required String buyerId,
    required String idToken,
    required UserAddress deliveryAddress,
    required List<CartItem> cartItems,
    required double platformCommissionRate,
  }) async {
    try {
      debugPrint(
        '[PAYMENT_REPO] verifyAndFinalize: paymentId=$razorpayPaymentId buyerId=$buyerId',
      );

      // Build grouped orders payload
      final grouped = <String, List<CartItem>>{};
      for (final item in cartItems) {
        grouped.putIfAbsent(item.storeId, () => []).add(item);
      }

      final ordersPayload = <Map<String, dynamic>>[];
      for (final entry in grouped.entries) {
        final items = entry.value;
        final sub = items.fold<double>(
          0,
          (s, i) => s + (i.unitPrice * i.quantity),
        );
        final delFee = sub < 1000 ? 99.0 : 0.0;
        final platFee = sub * platformCommissionRate;

        ordersPayload.add({
          'storeId': entry.key,
          'storeName': items.first.storeName,
          'items': items
              .map(
                (i) => {
                  'productId': i.productId,
                  'title': i.title,
                  'imageUrl': i.imageUrl,
                  'quantity': i.quantity,
                  'unitPrice': i.unitPrice,
                },
              )
              .toList(),
          'subtotal': sub,
          'deliveryFee': delFee,
          'platformFee': platFee,
          'totalAmount': sub + delFee + platFee,
          'paymentMethod': 'Online (Razorpay)',
        });
      }

      final requestBody = {
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': razorpaySignature,
        'buyerId': buyerId,
        'buyerName': deliveryAddress.fullName,
        'deliveryAddress': deliveryAddress.fullAddress,
        'orders': ordersPayload,
      };

      final response = await _httpClient
          .post(
            Uri.parse(verifyAndFinalizePaymentUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final orderIds = List<String>.from(data['orderIds'] as List? ?? []);
        debugPrint(
          '[PAYMENT_REPO] verifyAndFinalize success: ${orderIds.join(', ')}',
        );
        return Right(orderIds);
      }

      final err = data['error'] as String? ?? 'Payment finalization failed';
      debugPrint('[PAYMENT_REPO][ERROR] verifyAndFinalize: $err');
      return Left(err);
    } catch (e) {
      debugPrint('[PAYMENT_REPO][ERROR] verifyAndFinalize exception: $e');
      return Left(
        'Network error during payment finalization. Please contact support.',
      );
    }
  }

  // ── recordPaymentFailure ────────────────────────────────────────────────────

  @override
  Future<void> recordPaymentFailure({
    required String buyerId,
    required String razorpayOrderId,
    required int code,
    required String message,
  }) async {
    try {
      await _firestore.collection('payment_failures').add({
        'buyerId': buyerId,
        'razorpayOrderId': razorpayOrderId,
        'errorCode': code,
        'errorMessage': message,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint(
        '[PAYMENT_REPO] recordPaymentFailure logged: orderId=$razorpayOrderId code=$code',
      );
    } catch (e) {
      // Non-fatal — log only
      debugPrint('[PAYMENT_REPO][WARN] recordPaymentFailure failed: $e');
    }
  }

  // ── getTransactionByPaymentId ───────────────────────────────────────────────

  @override
  Future<Either<String, PaymentTransaction>> getTransactionByPaymentId(
    String paymentId,
  ) async {
    try {
      final snap = await _firestore
          .collection('transactions')
          .where('externalTransactionId', isEqualTo: paymentId)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 15));

      if (snap.docs.isEmpty) {
        return Left('Transaction not found for paymentId: $paymentId');
      }

      return Right(
        PaymentTransactionDto.fromFirestore(snap.docs.first).toDomain(),
      );
    } catch (e) {
      debugPrint('[PAYMENT_REPO][ERROR] getTransactionByPaymentId: $e');
      return Left('Failed to fetch transaction: ${e.toString()}');
    }
  }
}

// ---------------------------------------------------------------------------
// Fallback PlatformConfig used when the Riverpod provider hasn't loaded yet.
// Mirrors the inline fallback in checkout_screen.dart.
// ---------------------------------------------------------------------------
const _fallbackConfig = PlatformConfig(
  defaultCommissionRate: 0.085,
  categoryCommissionOverrides: {},
  maintenanceModeActive: false,
  globalRateLimitPerMinute: 600,
  razorpayKey: 'managed_via_functions',
);

// Expose the fallback so the controller can reference it without importing
// checkout_screen.
PlatformConfig get defaultPlatformConfig => _fallbackConfig;
