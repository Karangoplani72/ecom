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
Future<SellerAnalytics> sellerAnalytics(Ref ref) async {
  final sellerId = FirebaseAuth.instance.currentUser?.uid;

  if (sellerId == null) {
    return SellerAnalytics.empty();
  }

  return ref
      .watch(sellerAnalyticsRepositoryProvider)
      .getAnalytics(sellerId: sellerId);
}
