import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/seller_product_repository_impl.dart';
import '../../domain/entities/seller_product.dart';
import '../../domain/repositories/seller_product_repository.dart';

part 'seller_inventory_controller.g.dart';

@riverpod
SellerProductRepository sellerProductRepository(Ref ref) {
  return SellerProductRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
Stream<List<SellerProduct>> sellerProducts(Ref ref) {
  final sellerId = FirebaseAuth.instance.currentUser?.uid;

  if (sellerId == null) {
    return Stream.value([]);
  }

  return ref
      .watch(sellerProductRepositoryProvider)
      .watchProducts(sellerId: sellerId);
}

@riverpod
class SellerInventoryController extends _$SellerInventoryController {
  @override
  FutureOr<void> build() {}

  Future<void> deleteProduct({required String productId}) async {
    final sellerId = FirebaseAuth.instance.currentUser?.uid;

    if (sellerId == null) {
      throw Exception('Seller not authenticated');
    }

    state = const AsyncLoading();

    try {
      await ref
          .read(sellerProductRepositoryProvider)
          .deleteProduct(sellerId: sellerId, productId: productId);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateStock({
    required String productId,
    required int stock,
  }) async {
    final sellerId = FirebaseAuth.instance.currentUser?.uid;

    if (sellerId == null) {
      throw Exception('Seller not authenticated');
    }

    state = const AsyncLoading();

    try {
      await ref
          .read(sellerProductRepositoryProvider)
          .updateStock(sellerId: sellerId, productId: productId, stock: stock);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateStatus({
    required String productId,
    required String status,
  }) async {
    final sellerId = FirebaseAuth.instance.currentUser?.uid;

    if (sellerId == null) {
      throw Exception('Seller not authenticated');
    }

    state = const AsyncLoading();

    try {
      await ref
          .read(sellerProductRepositoryProvider)
          .updateStatus(
            sellerId: sellerId,
            productId: productId,
            status: status,
          );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
