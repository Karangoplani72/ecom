/// Razorpay service - platform-aware launcher.
///
/// Usage:
///   final result = await RazorpayService.launch(options);
///
/// On Web:    direct JS interop with window.Razorpay (checkout.js in index.html)
/// On mobile: razorpay_flutter native SDK wrapped in a Completer Future
library;

export 'razorpay_result.dart';

import 'razorpay_result.dart';

// dart.library.js_interop is true on all Flutter Web targets (JS + Wasm).
// dart.library.html was true only on the legacy DDC web target and is now
// false on CanvasKit / Wasm builds — using it caused the stub to load on web.
import 'razorpay_launcher_stub.dart'
if (dart.library.js_interop) 'razorpay_web_launcher.dart'
if (dart.library.io) 'razorpay_mobile_launcher.dart';

abstract final class RazorpayService {
  /// Launches the Razorpay checkout UI and returns a [RazorpayResult].
  ///
  /// [options] must contain at minimum:
  ///   key, amount (paise int), order_id, name, description
  static Future<RazorpayResult> launch(Map<String, dynamic> options) =>
      launchRazorpay(options);
}