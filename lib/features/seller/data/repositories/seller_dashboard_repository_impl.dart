import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/seller_dashboard_data.dart';
import '../../domain/repositories/seller_dashboard_repository.dart';

class SellerDashboardRepositoryImpl implements SellerDashboardRepository {
  final FirebaseFirestore firestore;

  SellerDashboardRepositoryImpl({required this.firestore});

  @override
  Future<SellerDashboardData> getDashboardData({
    required String sellerId,
  }) async {
    final productsSnapshot = await firestore
        .collection('stores')
        .doc(sellerId)
        .collection('products')
        .get();

    final ordersSnapshot = await firestore
        .collection('orders')
        .where('storeId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final products = productsSnapshot.docs;
    final orders = ordersSnapshot.docs;

    int activeProducts = 0;
    int lowStockProducts = 0;
    int outOfStockProducts = 0;
    int pendingOrders = 0;

    double totalRevenue = 0;

    final List<Map<String, dynamic>> lowStockItems = [];
    final List<Map<String, dynamic>> recentOrders = [];

    for (final doc in products) {
      final data = doc.data();

      final status = (data['status'] ?? 'inactive').toString();

      final metadata = Map<String, dynamic>.from(data['metadata'] ?? {});

      final stock = (metadata['stock'] ?? 0) as int;

      if (status == 'active') {
        activeProducts++;
      }

      if (stock <= 0) {
        outOfStockProducts++;
      } else if (stock <= 5) {
        lowStockProducts++;

        lowStockItems.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'stock': stock,
          'imageUrl': ((data['imageUrls'] ?? []) as List).isNotEmpty
              ? data['imageUrls'][0]
              : null,
        });
      }
    }

    for (final doc in orders) {
      final data = doc.data();

      final amount = (data['totalAmount'] ?? 0).toDouble();

      final status = (data['status'] ?? '').toString();

      totalRevenue += amount;

      if (status == 'pending') {
        pendingOrders++;
      }

      recentOrders.add({'id': doc.id, ...data});
    }

    recentOrders.sort((a, b) {
      final aDate = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;

      final bDate = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;

      return bDate.compareTo(aDate);
    });

    return SellerDashboardData(
      totalRevenue: totalRevenue,
      totalOrders: orders.length,
      totalProducts: products.length,
      pendingOrders: pendingOrders,
      activeProducts: activeProducts,
      lowStockProducts: lowStockProducts,
      outOfStockProducts: outOfStockProducts,
      recentOrders: recentOrders.take(5).toList(),
      lowStockItems: lowStockItems,
    );
  }
}
