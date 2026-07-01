import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'dart:async';

import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/seller/data/repositories/seller_analytics_repository_impl.dart';
import 'package:ecom/features/seller/domain/entities/seller_analytics.dart';
import 'package:ecom/features/seller/domain/repositories/seller_analytics_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'seller_analytics_controller.g.dart';

@riverpod
SellerAnalyticsRepository sellerAnalyticsRepository(Ref ref) {
  return SellerAnalyticsRepositoryImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@riverpod
Future<SellerAnalytics> sellerAnalytics(Ref ref) async {
  final sellerId = (ref.watch(currentUserProfileProvider).value?.storeId ?? ref.watch(currentUserProfileProvider).value?.uid);

  if (sellerId == null || sellerId.isEmpty) {
    throw Exception('Seller not authenticated');
  }

  final result = await ref
      .read(sellerAnalyticsRepositoryProvider)
      .getAnalytics(sellerId: sellerId);

  return result.fold((error) => throw error, (analytics) => analytics);
}

@riverpod
class SellerAnalyticsController extends _$SellerAnalyticsController {
  @override
  Future<SellerAnalytics> build() async {
    final sellerId = (ref.watch(currentUserProfileProvider).value?.storeId ?? ref.watch(currentUserProfileProvider).value?.uid);

    if (sellerId == null || sellerId.isEmpty) {
      throw Exception('Seller not authenticated');
    }

    final result = await ref
        .read(sellerAnalyticsRepositoryProvider)
        .getAnalytics(sellerId: sellerId);

    return result.fold((error) => throw error, (analytics) => analytics);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    final sellerId = (ref.read(currentUserProfileProvider).value?.storeId ?? ref.read(currentUserProfileProvider).value?.uid);

    if (sellerId == null || sellerId.isEmpty) {
      state = AsyncError(
        Exception('Seller not authenticated'),
        StackTrace.current,
      );
      return;
    }

    final result = await ref
        .read(sellerAnalyticsRepositoryProvider)
        .getAnalytics(sellerId: sellerId);

    result.fold(
      (error) {
        state = AsyncError(error, StackTrace.current);
      },
      (analytics) {
        state = AsyncData(analytics);
      },
    );
  }
}
