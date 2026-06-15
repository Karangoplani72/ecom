import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/buyer/domain/repositories/payment_repository.dart';
import 'package:ecom/features/buyer/data/dtos/payment_transaction_dto.dart';
import 'package:ecom/features/buyer/domain/entities/payment_transaction.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFirestore _firestore;

  PaymentRepositoryImpl({required this._firestore});

  @override
  Future<Either<String, String>> initializePaymentIntent({
    required String orderId,
    required double expectedAmount,
    required String currency,
  }) async {
    try {
      // Security Enforcement: Payment intent tracking items are written via client markers
      // but evaluated through severe schema conditions to prevent transaction tempering.
      final intentRef = await _firestore.collection('payment_intents').add({
        'orderId': orderId,
        'grossAmount': expectedAmount,
        'currency': currency,
        'status': 'initiated',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return Right(intentRef.id);
    } catch (e) {
      return Left("Payment Intent Creation Aborted: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, PaymentTransaction>> verifyTransactionStatus(String externalTxId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('externalTransactionId', isEqualTo: externalTxId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Left("Target ledger transaction signature not located on state infrastructure.");
      }

      return Right(PaymentTransactionDto.fromFirestore(snapshot.docs.first).toDomain());
    } catch (e) {
      return Left("Verification Protocol Timeout: ${e.toString()}");
    }
  }
}