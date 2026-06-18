import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/seller_order_repository_impl.dart';
import '../../domain/entities/seller_order.dart';
import '../../domain/repositories/seller_order_repository.dart';

part 'seller_orders_controller.g.dart';

@riverpod
FirebaseFirestore firebaseFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

@riverpod
String? currentSellerId(Ref ref) {
  return FirebaseAuth.instance.currentUser?.uid;
}

@riverpod
SellerOrderRepository sellerOrderRepository(Ref ref) {
  return SellerOrderRepositoryImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@riverpod
Stream<List<SellerOrder>> sellerOrders(Ref ref) {
  final sellerId = ref.watch(currentSellerIdProvider);

  if (sellerId == null || sellerId.isEmpty) {
    return Stream.value(<SellerOrder>[]);
  }

  return ref
      .watch(sellerOrderRepositoryProvider)
      .watchOrders(sellerId: sellerId);
}

@riverpod
class SellerOrdersController extends _$SellerOrdersController {
  @override
  FutureOr<void> build() {}

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    state = const AsyncLoading();

    final result = await ref
        .read(sellerOrderRepositoryProvider)
        .updateOrderStatus(orderId: orderId, status: status);

    state = result.fold(
      (error) => AsyncError(error, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> batchUpdateOrderStatus({
    required List<String> orderIds,
    required String status,
  }) async {
    state = const AsyncLoading();

    final result = await ref
        .read(sellerOrderRepositoryProvider)
        .batchUpdateOrderStatus(orderIds: orderIds, status: status);

    state = result.fold(
      (error) => AsyncError(error, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}
