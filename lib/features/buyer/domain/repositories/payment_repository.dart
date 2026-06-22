import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/auth/domain/entities/user_address.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/domain/entities/payment_transaction.dart';

abstract class PaymentRepository {
  /// Fetches the public Razorpay key ID from the Cloud Function.
  Future<Either<String, String>> fetchRazorpayKey();

  /// Creates a server-side Razorpay order via Cloud Function.
  /// [amountInPaise] must be an integer >= 100.
  /// Returns the raw Razorpay order map: { id, amount, currency }.
  Future<Either<String, Map<String, dynamic>>> createOrder({
    required int amountInPaise,
    required String idToken,
    String currency,
    String? receipt,
  });

  /// Verifies HMAC signature and atomically creates Firestore orders.
  /// Returns the list of created order IDs on success.
  Future<Either<String, List<String>>> verifyAndFinalize({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required String buyerId,
    required String idToken,
    required UserAddress deliveryAddress,
    required List<CartItem> cartItems,
    required double platformCommissionRate,
  });

  /// Records a failed or cancelled payment attempt in Firestore for audit.
  Future<void> recordPaymentFailure({
    required String buyerId,
    required String razorpayOrderId,
    required int code,
    required String message,
  });

  /// Reads a verified transaction from Firestore by its external Razorpay
  /// payment ID.
  Future<Either<String, PaymentTransaction>> getTransactionByPaymentId(
      String paymentId,);
}