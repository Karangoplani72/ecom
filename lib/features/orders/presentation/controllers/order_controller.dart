import 'dart:async';

import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/orders/data/repositories/order_repository_impl.dart';
import 'package:ecom/features/orders/domain/entities/order.dart';
import 'package:ecom/features/orders/domain/entities/order_status.dart';
import 'package:ecom/features/orders/domain/repositories/order_repository.dart';
import 'package:ecom/features/seller/data/repositories/seller_repository_impl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_controller.g.dart';

@riverpod
OrderRepository orderRepository(Ref ref) {
  return OrderRepositoryImpl(firestore: ref.watch(firebaseFirestoreProvider));
}

@riverpod
Stream<List<AppOrder>> buyerOrders(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return ref.watch(orderRepositoryProvider).watchBuyerOrders(buyerId: userId);
}

@riverpod
Stream<List<AppOrder>> sellerOrders(Ref ref) async* {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    yield [];
    return;
  }

  final sellerRepo = SellerRepositoryImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );

  final profileResult = await sellerRepo.getStoreProfileBySeller(userId);

  yield* profileResult.fold(
    (_) => Stream.value(<AppOrder>[]),
    (profile) => ref
        .watch(orderRepositoryProvider)
        .watchSellerOrders(storeId: profile.id),
  );
}

@riverpod
Future<AppOrder?> orderById(Ref ref, String orderId) async {
  final result = await ref.watch(orderRepositoryProvider).getOrderById(orderId);
  return result.fold((_) => null, (order) => order);
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
        if (!ref.mounted) return;
        state = AsyncError(error, StackTrace.current);
        onFailure(error);
      },
      (orderIds) {
        if (!ref.mounted) return;
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
