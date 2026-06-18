import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/seller_analytics_repository_impl.dart';
import '../../domain/entities/seller_analytics.dart';
import '../../domain/repositories/seller_analytics_repository.dart';

part 'seller_analytics_controller.g.dart';

@riverpod
SellerAnalyticsRepository sellerAnalyticsRepository(Ref ref) {
  return SellerAnalyticsRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
String? currentSellerId(Ref ref) {
  return FirebaseAuth.instance.currentUser?.uid;
}

@riverpod
Future<SellerAnalytics> sellerAnalytics(Ref ref) async {
  final sellerId = ref.watch(currentSellerIdProvider);

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
    final sellerId = ref.watch(currentSellerIdProvider);

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

    final sellerId = ref.read(currentSellerIdProvider);

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
