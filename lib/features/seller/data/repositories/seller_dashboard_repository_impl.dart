import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/seller_dashboard_data.dart';
import '../../domain/repositories/seller_dashboard_repository.dart';

class SellerDashboardRepositoryImpl implements SellerDashboardRepository {
  final FirebaseFirestore _firestore;
  static const String _storesCollection = 'stores';
  static const String _productsSubcollection = 'products';
  static const String _ordersCollection = 'orders';
  static const int _recentOrdersLimit = 5;
  static const int _allOrdersLimit = 50;

  SellerDashboardRepositoryImpl({required this._firestore});

  @override
  Future<Either<Exception, SellerDashboardData>> getDashboardData({
    required String sellerId,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      final results = await Future.wait([
        _firestore
            .collection(_storesCollection)
            .doc(sellerId)
            .collection(_productsSubcollection)
            .get(),
        _firestore
            .collection(_ordersCollection)
            .where('storeId', isEqualTo: sellerId)
            .orderBy('createdAt', descending: true)
            .limit(_allOrdersLimit)
            .get(),
      ]);

      final productsSnapshot = results[0];
      final ordersSnapshot = results[1];

      int activeProducts = 0;
      int lowStockProducts = 0;
      int outOfStockProducts = 0;
      int pendingOrders = 0;
      double totalRevenue = 0;

      final lowStockItems = <DashboardProductSummary>[];

      for (final doc in productsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'inactive';
        final metadata = Map<String, dynamic>.from(
          data['metadata'] as Map? ?? {},
        );
        final stock = metadata['stock'] as int? ?? 0;

        if (status == 'active') {
          activeProducts++;
        }

        if (stock <= 0) {
          outOfStockProducts++;
        } else if (stock <= 5) {
          lowStockProducts++;
          lowStockItems.add(
            DashboardProductSummary(
              productId: doc.id,
              title: data['title'] as String? ?? 'Unnamed Product',
              stock: stock,
              price: (data['basePrice'] as num? ?? 0).toDouble(),
            ),
          );
        }
      }

      final recentOrders = <DashboardOrderSummary>[];

      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        final amount = (data['totalAmount'] as num? ?? 0).toDouble();
        final createdAt = data['createdAt'] as Timestamp?;

        totalRevenue += amount;

        if (status == 'pending') {
          pendingOrders++;
        }

        if (recentOrders.length < _recentOrdersLimit) {
          recentOrders.add(
            DashboardOrderSummary(
              orderId: doc.id,
              amount: amount,
              status: status,
              createdAt: createdAt?.toDate(),
            ),
          );
        }
      }

      return Right(
        SellerDashboardData(
          totalRevenue: totalRevenue,
          totalOrders: ordersSnapshot.docs.length,
          totalProducts: productsSnapshot.docs.length,
          pendingOrders: pendingOrders,
          activeProducts: activeProducts,
          lowStockProducts: lowStockProducts,
          outOfStockProducts: outOfStockProducts,
          recentOrders: recentOrders,
          lowStockItems: lowStockItems,
        ),
      );
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get dashboard data: $e'));
    }
  }

  @override
  Future<Either<Exception, Map<String, dynamic>>> getDashboardMetrics({
    required String sellerId,
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      var query = _firestore
          .collection(_ordersCollection)
          .where('storeId', isEqualTo: sellerId);

      if (startDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final snapshot = await query.get();

      double totalRevenue = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['totalAmount'] as num? ?? 0).toDouble();

        final status = data['status'] as String? ?? '';
        if (status == 'delivered') {
          completedOrders++;
        } else if (status == 'cancelled') {
          cancelledOrders++;
        }
      }

      return Right({
        'totalOrders': snapshot.docs.length,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'totalRevenue': totalRevenue,
        'averageOrderValue': snapshot.docs.isNotEmpty
            ? totalRevenue / snapshot.docs.length
            : 0,
        'completionRate': snapshot.docs.isNotEmpty
            ? (completedOrders / snapshot.docs.length) * 100
            : 0,
      });
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get dashboard metrics: $e'));
    }
  }
}
