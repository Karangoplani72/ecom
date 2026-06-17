import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/seller_order_repository_impl.dart';
import '../../domain/entities/seller_order.dart';
import '../../domain/repositories/seller_order_repository.dart';

part 'seller_orders_controller.g.dart';

@riverpod
SellerOrderRepository sellerOrderRepository(Ref ref) {
  return SellerOrderRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
Stream<List<SellerOrder>> sellerOrders(Ref ref) {
  final sellerId = FirebaseAuth.instance.currentUser?.uid;

  if (sellerId == null) {
    return Stream.value([]);
  }

  return ref
      .watch(sellerOrderRepositoryProvider)
      .watchOrders(sellerId: sellerId);
}

@riverpod
class SellerOrdersController extends _$SellerOrdersController {
  @override
  FutureOr<void> build() {}

  Future<void> updateStatus({
    required String orderId,
    required String status,
  }) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(sellerOrderRepositoryProvider)
          .updateOrderStatus(orderId: orderId, status: status);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
