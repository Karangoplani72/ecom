import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/seller_analytics.dart';
import '../../domain/repositories/seller_analytics_repository.dart';

class SellerAnalyticsRepositoryImpl implements SellerAnalyticsRepository {
  final FirebaseFirestore firestore;

  SellerAnalyticsRepositoryImpl({required this.firestore});

  @override
  Future<SellerAnalytics> getAnalytics({required String sellerId}) async {
    final productsSnapshot = await firestore
        .collection('stores')
        .doc(sellerId)
        .collection('products')
        .get();

    final ordersSnapshot = await firestore
        .collection('orders')
        .where('storeId', isEqualTo: sellerId)
        .get();

    int activeProducts = 0;
    int pendingOrders = 0;
    double revenue = 0;

    for (final doc in productsSnapshot.docs) {
      final data = doc.data();

      if (data['status'] == 'active') {
        activeProducts++;
      }
    }

    for (final doc in ordersSnapshot.docs) {
      final data = doc.data();

      if (data['status'] == 'pending') {
        pendingOrders++;
      }

      revenue += (data['totalAmount'] ?? 0).toDouble();
    }

    return SellerAnalytics(
      totalProducts: productsSnapshot.docs.length,
      activeProducts: activeProducts,
      totalOrders: ordersSnapshot.docs.length,
      pendingOrders: pendingOrders,
      totalRevenue: revenue,
    );
  }
}
