import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/buyer/domain/entities/payment_transaction.dart';

abstract class PaymentRepository {
  Future<Either<String, String>> initializePaymentIntent({
    required String orderId,
    required double expectedAmount,
    required String currency,
  });

  Future<Either<String, PaymentTransaction>> verifyTransactionStatus(String externalTxId);
}