// lib/features/seller/presentation/controllers/seller_application_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/seller_application_repository_impl.dart';
import '../../domain/entities/seller_application.dart';
import '../../domain/repositories/seller_application_repository.dart';

part 'seller_application_controller.g.dart';

@riverpod
SellerApplicationRepository sellerApplicationRepository(Ref ref) {
  return SellerApplicationRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
class SellerApplicationController extends _$SellerApplicationController {
  @override
  FutureOr<void> build() {}

  Future<Either<String, Unit>> submit({
    required String fullName,
    required String phoneNumber,
    required String storeName,
    required String businessCategory,
    String? gstNumber,
    required String description,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Left('You must be logged in to apply as a seller.');
    }

    state = const AsyncValue.loading();

    final application = SellerApplication(
      sellerId: currentUser.uid,
      fullName: fullName,
      phoneNumber: phoneNumber,
      storeName: storeName,
      businessCategory: businessCategory,
      gstNumber: gstNumber?.trim().isEmpty == true ? null : gstNumber?.trim(),
      description: description,
      status: 'pending',
      submittedAt: DateTime.now(),
    );

    final repo = ref.read(sellerApplicationRepositoryProvider);
    final result = await repo.submitApplication(application);

    result.fold(
      (error) => state = AsyncValue.error(error, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );

    return result;
  }
}
