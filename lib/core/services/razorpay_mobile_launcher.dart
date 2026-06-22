import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'razorpay_result.dart';

/// Mobile (Android/iOS) implementation using the native razorpay_flutter SDK.
/// Returns a [RazorpayResult] via a [Completer] — the Razorpay callbacks
/// complete the completer exactly once.
Future<RazorpayResult> launchRazorpay(Map<String, dynamic> options) async {
  debugPrint('[RAZORPAY][MOBILE] launchRazorpay called. order_id=${options["order_id"]}');

  final completer = Completer<RazorpayResult>();
  late final Razorpay rzp;

  void onSuccess(PaymentSuccessResponse r) {
    debugPrint('[RAZORPAY][MOBILE][SUCCESS] paymentId=${r.paymentId} orderId=${r.orderId}');
    rzp.clear();
    if (!completer.isCompleted) {
      completer.complete(RazorpaySuccess(
        paymentId: r.paymentId ?? '',
        orderId: r.orderId ?? (options['order_id'] as String? ?? ''),
        signature: r.signature ?? '',
      ));
    }
  }

  void onError(PaymentFailureResponse r) {
    debugPrint('[RAZORPAY][MOBILE][ERROR] code=${r.code} message=${r.message}');
    rzp.clear();
    if (!completer.isCompleted) {
      if (r.code == 2) {
        completer.complete(RazorpayCancelled());
      } else {
        completer.complete(RazorpayFailure(
          code: r.code ?? -1,
          message: r.message ?? 'Unknown error',
        ));
      }
    }
  }

  void onWallet(ExternalWalletResponse r) {
    debugPrint('[RAZORPAY][MOBILE] External wallet: ${r.walletName}');
    rzp.clear();
    if (!completer.isCompleted) {
      completer.complete(RazorpayCancelled());
    }
  }

  rzp = Razorpay();
  rzp.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
  rzp.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
  rzp.on(Razorpay.EVENT_EXTERNAL_WALLET, onWallet);

  debugPrint('[RAZORPAY][MOBILE] Opening Razorpay checkout...');
  rzp.open(options);

  return completer.future;
}
