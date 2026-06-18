import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/seller_repository_impl.dart';
import '../../domain/entities/store_profile.dart';
import '../../domain/repositories/seller_repository.dart';

part 'seller_controller.g.dart';

@riverpod
SellerRepository sellerRepository(Ref ref) {
  return SellerRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
String? _currentSellerIdProvider(Ref ref) {
  return FirebaseAuth.instance.currentUser?.uid;
}

@riverpod
class SellerController extends _$SellerController {
  @override
  FutureOr<StoreProfile?> build() {
    return null;
  }

  Future<void> initializeMerchantSession(String sellerId) async {
    if (sellerId.isEmpty) {
      state = AsyncValue.error(
        Exception('Invalid seller ID: seller ID cannot be empty'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    final repo = ref.read(sellerRepositoryProvider);
    final result = await repo.getStoreProfileBySeller(sellerId);

    state = result.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (profile) => AsyncValue.data(profile),
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

    result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
      },
      (_) async {
        await initializeMerchantSession(activeProfile.sellerId);
      },
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.data(null);
  }
}
