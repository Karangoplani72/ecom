import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ecom/features/buyer/data/repositories/payment_repository_impl.dart';
import 'package:ecom/features/buyer/domain/entities/payment_transaction.dart';
import 'package:ecom/features/buyer/domain/repositories/payment_repository.dart';

part 'payment_controller.g.dart';

@riverpod
PaymentRepository paymentRepository(Ref ref) {
  return PaymentRepositoryImpl(
    firestore: FirebaseFirestore.instance,
  );
}

@riverpod
class PaymentController extends _$PaymentController {
  @override
  FutureOr<PaymentTransaction?> build() {
    return null;
  }

  Future<String?> requestCheckoutIntent(
      String orderId,
      double totalBill,
      ) async {
    state = const AsyncValue.loading();

    final repo = ref.read(
      paymentRepositoryProvider,
    );

    final result = await repo.initializePaymentIntent(
      orderId: orderId,
      expectedAmount: totalBill,
      currency: 'INR',
    );

    return result.fold(
          (failure) {
        state = AsyncValue.error(
          failure,
          StackTrace.current,
        );
        return null;
      },
          (intentId) {
        state = const AsyncValue.data(null);
        return intentId;
      },
    );
  }

  Future<void> confirmPaymentSuccess(
      String trackingToken,
      ) async {
    state = const AsyncValue.loading();

    final repo = ref.read(
      paymentRepositoryProvider,
    );

    final result = await repo.verifyTransactionStatus(
      trackingToken,
    );

    result.fold(
          (error) {
        state = AsyncValue.error(
          error,
          StackTrace.current,
        );
      },
          (transaction) {
        state = AsyncValue.data(
          transaction,
        );
      },
    );
  }
}