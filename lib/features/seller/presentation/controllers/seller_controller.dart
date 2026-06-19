import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/seller/data/repositories/seller_repository_impl.dart';
import 'package:ecom/features/seller/domain/entities/store_profile.dart';
import 'package:ecom/features/seller/domain/repositories/seller_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'seller_controller.g.dart';

@riverpod
SellerRepository sellerRepository(Ref ref) {
  return SellerRepositoryImpl(firestore: ref.watch(firebaseFirestoreProvider));
}

@riverpod
class SellerController extends _$SellerController {
  @override
  FutureOr<StoreProfile?> build() async {
    final sellerId = ref.watch(currentUserIdProvider);
    if (sellerId == null || sellerId.isEmpty) {
      return null;
    }

    final repo = ref.read(sellerRepositoryProvider);
    final result = await repo.getStoreProfileBySeller(sellerId);

    return result.fold(
      (error) => throw error,
      (profile) => profile,
    );
  }

  Future<void> patchStoreSettings(Map<String, dynamic> updateData) async {
    final activeProfile = state.value;

    if (activeProfile == null) {
      state = AsyncValue.error(
        Exception('No active store profile: store profile not loaded'),
        StackTrace.current,
      );
      return;
    }

    if (updateData.isEmpty) {
      state = AsyncValue.error(
        Exception('No updates provided: update data cannot be empty'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    final repo = ref.read(sellerRepositoryProvider);
    final result = await repo.updateStorefrontMetadata(
      activeProfile.id,
      updateData,
    );

    state = await result.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (_) async {
        final profile = await repo.getStoreProfileBySeller(activeProfile.sellerId);
        return profile.fold(
          (err) => AsyncValue.error(err, StackTrace.current),
          (p) => AsyncValue.data(p),
        );
      },
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.data(null);
  }
}
