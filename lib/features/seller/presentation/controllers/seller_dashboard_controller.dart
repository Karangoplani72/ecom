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
Future<SellerDashboardData> sellerDashboard(Ref ref) async {
  final sellerId = FirebaseAuth.instance.currentUser?.uid;

  if (sellerId == null) {
    return SellerDashboardData.empty();
  }

  return ref
      .read(sellerDashboardRepositoryProvider)
      .getDashboardData(sellerId: sellerId);
}
