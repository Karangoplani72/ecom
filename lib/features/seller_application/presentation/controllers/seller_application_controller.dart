import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/seller_application/data/dtos/seller_application_dto.dart';
import 'package:ecom/features/seller_application/data/repositories/seller_application_repository_impl.dart';
import 'package:ecom/features/seller_application/domain/entities/seller_application.dart';
import 'package:ecom/features/seller_application/domain/repositories/seller_application_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'seller_application_controller.g.dart';

@riverpod
SellerApplicationRepository sellerApplicationRepository(Ref ref) {
  return SellerApplicationRepositoryImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@riverpod
Future<SellerApplication?> userSellerApplication(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final firestore = ref.watch(firebaseFirestoreProvider);
  final doc = await firestore
      .collection(SellerApplicationDto.collectionPath)
      .doc(userId)
      .get();

  if (!doc.exists) return null;
  return SellerApplicationDto.fromFirestore(doc).toDomain();
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
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return const Left('You must be logged in to apply as a seller.');
    }

    state = const AsyncValue.loading();

    final application = SellerApplication(
      userId: userId,
      fullName: fullName,
      phoneNumber: phoneNumber,
      storeName: storeName,
      storeDescription: description,
      businessCategory: businessCategory,
      gstNumber: gstNumber?.trim().isEmpty == true ? null : gstNumber?.trim(),
      status: 'pending',
      submittedAt: DateTime.now(),
      bankName: bankName.trim(),
      accountNumber: accountNumber.trim(),
      ifscCode: ifscCode.trim(),
      accountHolderName: accountHolderName.trim(),
    );

    final repo = ref.read(sellerApplicationRepositoryProvider);
    final result = await repo.submitApplication(application);

    result.fold(
      (error) => state = AsyncValue.error(error, StackTrace.current),
      (_) {
        ref.invalidate(userSellerApplicationProvider);
        state = const AsyncValue.data(null);
      },
    );

    return result;
  }
}
