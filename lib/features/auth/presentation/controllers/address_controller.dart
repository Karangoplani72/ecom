import 'dart:async';

import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/auth/data/repositories/address_repository_impl.dart';
import 'package:ecom/features/auth/domain/entities/user_address.dart';
import 'package:ecom/features/auth/domain/repositories/address_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'address_controller.g.dart';

@riverpod
AddressRepository addressRepository(Ref ref) {
  return AddressRepositoryImpl(firestore: ref.watch(firebaseFirestoreProvider));
}

@riverpod
Stream<List<UserAddress>> userAddresses(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(addressRepositoryProvider).watchAddresses(userId);
}

@riverpod
class AddressController extends _$AddressController {
  @override
  FutureOr<void> build() {}

  Future<void> addAddress(UserAddress address) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    final result = await ref
        .read(addressRepositoryProvider)
        .addAddress(userId, address);

    state = result.fold(
      (error) => AsyncError(error, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> updateAddress(UserAddress address) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    final result = await ref
        .read(addressRepositoryProvider)
        .updateAddress(userId, address);

    state = result.fold(
      (error) => AsyncError(error, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> deleteAddress(String addressId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    final result = await ref
        .read(addressRepositoryProvider)
        .deleteAddress(userId, addressId);

    state = result.fold(
      (error) => AsyncError(error, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> setDefault(String addressId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    final result = await ref
        .read(addressRepositoryProvider)
        .setDefaultAddress(userId, addressId);

    state = result.fold(
      (error) => AsyncError(error, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}
