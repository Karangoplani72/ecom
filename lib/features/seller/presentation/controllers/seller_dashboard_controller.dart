import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/seller_dashboard_repository_impl.dart';
import '../../domain/entities/seller_dashboard_data.dart';
import '../../domain/repositories/seller_dashboard_repository.dart';

part 'seller_dashboard_controller.g.dart';

@riverpod
SellerDashboardRepository sellerDashboardRepository(Ref ref) {
  return SellerDashboardRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
String? currentSellerId(Ref ref) {
  return FirebaseAuth.instance.currentUser?.uid;
}

@riverpod
Future<Object> sellerDashboard(Ref ref) async {
  final sellerId = ref.watch(currentSellerIdProvider);

  if (sellerId == null || sellerId.isEmpty) {
    return Future.error(Exception('Seller not authenticated'));
  }

  try {
    return await ref
        .read(sellerDashboardRepositoryProvider)
        .getDashboardData(sellerId: sellerId);
  } catch (e) {
    return Future.error(Exception('Failed to load dashboard data: $e'));
  }
}

@riverpod
class SellerDashboardController extends _$SellerDashboardController {
  @override
  Future<SellerDashboardData> build() async {
    final sellerId = ref.watch(currentSellerIdProvider);

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

    final sellerId = ref.read(currentSellerIdProvider);

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
