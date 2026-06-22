import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'razorpay_result.dart';

// ── JS interop binding for window.Razorpay ───────────────────────────────────
// checkout.js is pre-loaded in web/index.html — window.Razorpay is available.
@JS('Razorpay')
extension type _JsRazorpay._(JSObject _) implements JSObject {
  external _JsRazorpay(JSAny options);
  external void open();
  external void on(String event, JSFunction callback);
}

/// Web implementation — opens the Razorpay JS checkout modal directly via
/// JS interop. Returns a [RazorpayResult] when the modal is done.
Future<RazorpayResult> launchRazorpay(Map<String, dynamic> options) async {
  debugPrint('[RAZORPAY][WEB] launchRazorpay called. order_id=${options["order_id"]}');

  final completer = Completer<RazorpayResult>();

  // Build the JS options object from the Dart map
  final jsOptions = options.jsify() as JSObject;

  // ── Success handler ────────────────────────────────────────────────────────
  jsOptions.setProperty(
    'handler'.toJS,
    (JSObject response) {
      debugPrint('[RAZORPAY][WEB][SUCCESS] Payment succeeded.');
      if (completer.isCompleted) return;

      final paymentId =
          response.getProperty('razorpay_payment_id'.toJS).dartify() as String? ?? '';
      final orderId =
          response.hasProperty('razorpay_order_id'.toJS).toDart
              ? (response.getProperty('razorpay_order_id'.toJS).dartify() as String? ?? '')
              : (options['order_id'] as String? ?? '');
      final signature =
          response.hasProperty('razorpay_signature'.toJS).toDart
              ? (response.getProperty('razorpay_signature'.toJS).dartify() as String? ?? '')
              : '';

      debugPrint('[RAZORPAY][WEB][SUCCESS] paymentId=$paymentId orderId=$orderId signaturePresent=${signature.isNotEmpty}');
      completer.complete(RazorpaySuccess(
        paymentId: paymentId,
        orderId: orderId,
        signature: signature,
      ));
    }.toJS,
  );

  // ── Modal dismiss / cancel handler ────────────────────────────────────────
  // Must be nested under a "modal" JS object so Razorpay picks it up correctly.
  final modalObj = JSObject();
  modalObj.setProperty(
    'ondismiss'.toJS,
    () {
      debugPrint('[RAZORPAY][WEB] Modal dismissed by user.');
      if (!completer.isCompleted) {
        completer.complete(RazorpayCancelled());
      }
    }.toJS,
  );
  jsOptions.setProperty('modal'.toJS, modalObj);

  // ── Initialise and open ────────────────────────────────────────────────────
  debugPrint('[RAZORPAY][WEB] Opening Razorpay JS checkout modal...');
  try {
    final rzp = _JsRazorpay(jsOptions);

    // ── Payment failure listener ─────────────────────────────────────────────
    rzp.on(
      'payment.failed',
      (JSObject response) {
        debugPrint('[RAZORPAY][WEB][ERROR] payment.failed fired.');
        if (completer.isCompleted) return;

        final error = response.getProperty('error'.toJS) as JSObject;
        final message =
            error.getProperty('description'.toJS).dartify() as String? ??
                'Payment failed';
        debugPrint('[RAZORPAY][WEB][ERROR] $message');
        completer.complete(RazorpayFailure(code: -1, message: message));
      }.toJS,
    );

    rzp.open();
    debugPrint('[RAZORPAY][WEB] Razorpay.open() called successfully. Awaiting user action...');
  } catch (e) {
    debugPrint('[RAZORPAY][WEB][ERROR] Failed to open Razorpay: $e');
    if (!completer.isCompleted) {
      completer.complete(RazorpayFailure(code: -99, message: e.toString()));
    }
  }

  return completer.future;
}
