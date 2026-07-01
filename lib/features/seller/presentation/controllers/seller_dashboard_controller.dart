import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/seller/data/repositories/seller_dashboard_repository_impl.dart';
import 'package:ecom/features/seller/domain/entities/seller_dashboard_data.dart';
import 'package:ecom/features/seller/domain/repositories/seller_dashboard_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'seller_dashboard_controller.g.dart';

@riverpod
SellerDashboardRepository sellerDashboardRepository(Ref ref) {
  return SellerDashboardRepositoryImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@riverpod
class SellerDashboardController extends _$SellerDashboardController {
  @override
  Future<SellerDashboardData> build() async {
    final sellerId = (ref.watch(currentUserProfileProvider).value?.storeId ?? ref.watch(currentUserProfileProvider).value?.uid);

    if (sellerId == null || sellerId.isEmpty) {
      throw Exception('Seller not authenticated');
    }

    final result = await ref
        .read(sellerDashboardRepositoryProvider)
        .getDashboardData(sellerId: sellerId);

    return result.fold((error) => throw error, (data) => data);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();

    final sellerId = (ref.read(currentUserProfileProvider).value?.storeId ?? ref.read(currentUserProfileProvider).value?.uid);

    if (sellerId == null || sellerId.isEmpty) {
      state = AsyncValue.error(
        Exception('Seller not authenticated'),
        StackTrace.current,
      );
      return;
    }

    try {
      final result = await ref
          .read(sellerDashboardRepositoryProvider)
          .getDashboardData(sellerId: sellerId);

      result.fold(
        (error) {
          state = AsyncValue.error(error, StackTrace.current);
        },
        (data) {
          state = AsyncValue.data(data);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
