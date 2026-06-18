import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/auth/data/repositories/address_repository_impl.dart';
import 'package:ecom/features/auth/domain/entities/user_address.dart';
import 'package:ecom/features/auth/domain/repositories/address_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'address_controller.g.dart';

@riverpod
AddressRepository addressRepository(Ref ref) {
  return AddressRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
Stream<List<UserAddress>> userAddresses(Ref ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(addressRepositoryProvider).watchAddresses(user.uid);
}

@riverpod
class AddressController extends _$AddressController {
  @override
  FutureOr<void> build() {}

  Future<void> addAddress(UserAddress address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    final result = await ref
        .read(addressRepositoryProvider)
        .addAddress(user.uid, address);

    state = result.fold(
      (error) => AsyncError(error, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> updateAddress(UserAddress address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    final result = await ref
        .read(addressRepositoryProvider)
        .updateAddress(user.uid, address);

    state = result.fold(
      (error) => AsyncError(error, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> deleteAddress(String addressId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    final result = await ref
        .read(addressRepositoryProvider)
        .deleteAddress(user.uid, addressId);

    state = result.fold(
      (error) => AsyncError(error, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> setDefault(String addressId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    final result = await ref
        .read(addressRepositoryProvider)
        .setDefaultAddress(user.uid, addressId);

    state = result.fold(
      (error) => AsyncError(error, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}
