import 'dart:async';

import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/buyer/data/repositories/wishlist_repository_impl.dart';
import 'package:ecom/features/buyer/domain/repositories/wishlist_repository.dart';
import 'package:ecom/features/buyer/presentation/controllers/guest_wishlist_controller.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wishlist_controller.g.dart';

@riverpod
WishlistRepository wishlistRepository(Ref ref) {
  return WishlistRepositoryImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@riverpod
Stream<List<CatalogItem>> wishlistStream(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    final guestItems = ref.watch(guestWishlistControllerProvider);
    return Stream.value(guestItems);
  }
  return ref
      .watch(wishlistRepositoryProvider)
      .watchWishlist(userId: userId)
      .map((either) => either.fold((_) => <CatalogItem>[], (items) => items));
}

@riverpod
class WishlistController extends _$WishlistController {
  @override
  FutureOr<void> build() {}

  Future<void> addToWishlist(CatalogItem item) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ref.read(guestWishlistControllerProvider.notifier).addItem(item);
      return;
    }
    final result = await ref
        .read(wishlistRepositoryProvider)
        .addToWishlist(userId: userId, item: item);
    result.fold(
      (error) => state = AsyncError(error, StackTrace.current),
      (_) => state = const AsyncData(null),
    );
  }

  Future<void> removeFromWishlist(String productId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ref.read(guestWishlistControllerProvider.notifier).removeItem(productId);
      return;
    }
    final result = await ref
        .read(wishlistRepositoryProvider)
        .removeFromWishlist(userId: userId, productId: productId);
    result.fold(
      (error) => state = AsyncError(error, StackTrace.current),
      (_) => state = const AsyncData(null),
    );
  }

  Future<bool> isInWishlist(String productId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return ref.read(guestWishlistControllerProvider.notifier).isInWishlist(productId);
    }
    return ref
        .read(wishlistRepositoryProvider)
        .isInWishlist(userId: userId, productId: productId);
  }
}
