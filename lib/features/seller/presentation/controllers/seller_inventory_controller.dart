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
FirebaseFirestore _firebaseFirestoreProvider(Ref ref) {
  return FirebaseFirestore.instance;
}

@riverpod
String? currentSellerId(Ref ref) {
  return FirebaseAuth.instance.currentUser?.uid;
}

@riverpod
Stream<List<SellerProduct>> sellerProducts(Ref ref) {
  final sellerId = ref.watch(currentSellerIdProvider);

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
    final sellerId = ref.read(currentSellerIdProvider);

    if (sellerId == null) {
      state = AsyncValue.error(
        Exception('Seller not authenticated'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    final result = await ref
        .read(sellerProductRepositoryProvider)
        .deleteProduct(sellerId: sellerId, productId: productId);

    state = result.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> updateStock({
    required String productId,
    required int stock,
  }) async {
    final sellerId = ref.read(currentSellerIdProvider);

    if (sellerId == null) {
      state = AsyncValue.error(
        Exception('Seller not authenticated'),
        StackTrace.current,
      );
      return;
    }

    if (stock < 0) {
      state = AsyncValue.error(
        Exception('Stock cannot be negative'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    final result = await ref
        .read(sellerProductRepositoryProvider)
        .updateStock(sellerId: sellerId, productId: productId, stock: stock);

    state = result.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> updateStatus({
    required String productId,
    required String status,
  }) async {
    final sellerId = ref.read(currentSellerIdProvider);

    if (sellerId == null) {
      state = AsyncValue.error(
        Exception('Seller not authenticated'),
        StackTrace.current,
      );
      return;
    }

    if (status.isEmpty) {
      state = AsyncValue.error(
        Exception('Status cannot be empty'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    final result = await ref
        .read(sellerProductRepositoryProvider)
        .updateStatus(sellerId: sellerId, productId: productId, status: status);

    state = result.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }
}
