import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/seller_analytics.dart';
import '../../domain/repositories/seller_analytics_repository.dart';

class SellerAnalyticsRepositoryImpl implements SellerAnalyticsRepository {
  final FirebaseFirestore _firestore;
  static const String _storesCollection = 'stores';
  static const String _productsSubcollection = 'products';
  static const String _ordersCollection = 'orders';

  SellerAnalyticsRepositoryImpl({required this._firestore});

  @override
  Future<Either<Exception, SellerAnalytics>> getAnalytics({
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
            .get(),
      ]);

      final productsSnapshot = results[0];
      final ordersSnapshot = results[1];

      int activeProducts = 0;
      int pendingOrders = 0;
      double totalRevenue = 0;

      for (final doc in productsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'inactive';

        if (status == 'active') {
          activeProducts++;
        }
      }

      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        final amount = (data['totalAmount'] as num? ?? 0).toDouble();

        if (status == 'pending') {
          pendingOrders++;
        }

        totalRevenue += amount;
      }

      return Right(
        SellerAnalytics(
          totalProducts: productsSnapshot.docs.length,
          activeProducts: activeProducts,
          totalOrders: ordersSnapshot.docs.length,
          pendingOrders: pendingOrders,
          totalRevenue: totalRevenue,
        ),
      );
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get analytics: $e'));
    }
  }

  @override
  Future<Either<Exception, Map<String, dynamic>>> getRevenueByDate({
    required String sellerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('storeId', isEqualTo: sellerId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double totalRevenue = 0;
      int totalOrders = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['totalAmount'] as num? ?? 0).toDouble();
        totalOrders++;
      }

      return Right({
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
      });
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get revenue data: $e'));
    }
  }

  @override
  Future<Either<Exception, Map<String, dynamic>>> getProductAnalytics({
    required String sellerId,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      final snapshot = await _firestore
          .collection(_storesCollection)
          .doc(sellerId)
          .collection(_productsSubcollection)
          .get();

      int active = 0;
      int inactive = 0;
      int lowStock = 0;
      int outOfStock = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'inactive';
        final metadata = Map<String, dynamic>.from(
          data['metadata'] as Map? ?? {},
        );
        final stock = metadata['stock'] as int? ?? 0;

        if (status == 'active') {
          active++;
        } else {
          inactive++;
        }

        if (stock <= 0) {
          outOfStock++;
        } else if (stock <= 5) {
          lowStock++;
        }
      }

      return Right({
        'totalProducts': snapshot.docs.length,
        'activeProducts': active,
        'inactiveProducts': inactive,
        'lowStockProducts': lowStock,
        'outOfStockProducts': outOfStock,
      });
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get product analytics: $e'));
    }
  }

  @override
  Future<Either<Exception, Map<String, dynamic>>> getCustomerAnalytics({
    required String sellerId,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('storeId', isEqualTo: sellerId)
          .get();

      final uniqueCustomers = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final buyerId = data['buyerId'] as String?;

        if (buyerId != null && buyerId.isNotEmpty) {
          uniqueCustomers.add(buyerId);
        }
      }

      return Right({
        'totalOrders': snapshot.docs.length,
        'uniqueCustomers': uniqueCustomers.length,
        'repeatCustomerPercentage':
            uniqueCustomers.isNotEmpty && snapshot.docs.isNotEmpty
            ? ((snapshot.docs.length - uniqueCustomers.length) /
                      snapshot.docs.length) *
                  100
            : 0,
      });
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get customer analytics: $e'));
    }
  }
}
