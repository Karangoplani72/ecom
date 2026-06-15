import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ecom/features/seller/data/repositories/seller_repository_impl.dart';
import 'package:ecom/features/seller/domain/entities/store_profile.dart';
import 'package:ecom/features/seller/domain/repositories/seller_repository.dart';

part 'seller_controller.g.dart';

@riverpod
SellerRepository sellerRepository(Ref ref) {
  return SellerRepositoryImpl(
    firestore: FirebaseFirestore.instance,
  );
}

@riverpod
class SellerController extends _$SellerController {
  @override
  FutureOr<StoreProfile?> build() {
    return null;
  }

  Future<void> initializeMerchantSession(String sellerId) async {
    state = const AsyncValue.loading();

    final repo = ref.read(sellerRepositoryProvider);

    final result = await repo.getStoreProfileBySeller(
      sellerId,
    );

    result.fold(
          (error) {
        state = AsyncValue.error(
          error,
          StackTrace.current,
        );
      },
          (profile) {
        state = AsyncValue.data(profile);
      },
    );
  }

  Future<void> patchStoreSettings(
      Map<String, dynamic> parametersDelta,
      ) async {
    final activeProfile = state.value;

    if (activeProfile == null) {
      return;
    }

    final repo = ref.read(
      sellerRepositoryProvider,
    );

    final result = await repo.updateStorefrontMetadata(
      activeProfile.id,
      parametersDelta,
    );

    result.fold(
          (error) {
        state = AsyncValue.error(
          error,
          StackTrace.current,
        );
      },
          (_) async {
        await initializeMerchantSession(
          activeProfile.sellerId,
        );
      },
    );
  }
}