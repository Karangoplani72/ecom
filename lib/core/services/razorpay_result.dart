/// The unified result of a Razorpay checkout session — same on all platforms.
sealed class RazorpayResult {}

class RazorpaySuccess extends RazorpayResult {
  final String paymentId;
  final String orderId;
  final String signature;
  RazorpaySuccess({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });
}

class RazorpayFailure extends RazorpayResult {
  final int code;
  final String message;
  RazorpayFailure({required this.code, required this.message});
}

class RazorpayCancelled extends RazorpayResult {}
