import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/orders/data/repositories/order_repository_impl.dart';
import 'package:ecom/features/orders/domain/entities/order.dart';
import 'package:ecom/features/orders/domain/entities/order_status.dart';
import 'package:ecom/features/orders/domain/repositories/order_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_controller.g.dart';

@riverpod
OrderRepository orderRepository(Ref ref) {
  return OrderRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
Stream<List<AppOrder>> buyerOrders(Ref ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return ref.watch(orderRepositoryProvider).watchBuyerOrders(buyerId: user.uid);
}

@riverpod
Stream<List<AppOrder>> sellerOrders(Ref ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return ref
      .watch(orderRepositoryProvider)
      .watchSellerOrders(storeId: user.uid);
}

@riverpod
class OrderController extends _$OrderController {
  @override
  FutureOr<void> build() {}

  Future<void> checkout({
    required List<AppOrder> orders,
    required void Function(String) onFailure,
    required void Function() onSuccess,
  }) async {
    state = const AsyncLoading();

    final result = await ref
        .read(orderRepositoryProvider)
        .checkout(orders: orders);

    result.fold(
      (error) {
        state = AsyncError(error, StackTrace.current);
        onFailure(error);
      },
      (orderIds) {
        state = const AsyncData(null);
        onSuccess();
      },
    );
  }

  Future<void> updateStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    state = const AsyncLoading();

    final result = await ref
        .read(orderRepositoryProvider)
        .updateOrderStatus(orderId: orderId, status: status);

    state = result.fold(
      (error) => AsyncError(error, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> cancelOrder({required String orderId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = const AsyncLoading();

    final result = await ref
        .read(orderRepositoryProvider)
        .cancelOrder(orderId: orderId, userId: user.uid, isSeller: false);

    state = result.fold(
      (error) => AsyncError(error, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}
