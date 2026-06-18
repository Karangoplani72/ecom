import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/seller_order.dart';
import '../../domain/repositories/seller_order_repository.dart';
import '../dtos/seller_order_dto.dart';

class SellerOrderRepositoryImpl implements SellerOrderRepository {
  final FirebaseFirestore _firestore;
  static const String _ordersCollection = 'orders';
  static const Set<String> _validStatuses = {
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded',
  };

  SellerOrderRepositoryImpl({required this._firestore});

  @override
  Future<Either<Exception, List<SellerOrder>>> getOrdersByStatus({
    required String sellerId,
    required String status,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('storeId', isEqualTo: sellerId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      final orders = snapshot.docs
          .map((doc) => SellerOrderDto.fromFirestore(doc).toDomain())
          .toList();

      return Right(orders);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get orders by status: $e'));
    }
  }

  @override
  Future<Either<Exception, List<SellerOrder>>> getOrdersInDateRange({
    required String sellerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('storeId', isEqualTo: sellerId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      final orders = snapshot.docs
          .map((doc) => SellerOrderDto.fromFirestore(doc).toDomain())
          .toList();

      return Right(orders);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get orders in date range: $e'));
    }
  }

  @override
  Stream<List<SellerOrder>> watchOrders({required String sellerId}) {
    try {
      if (sellerId.isEmpty) {
        return Stream.error(
          Exception('Invalid seller ID: seller ID cannot be empty'),
        );
      }

      return _firestore
          .collection(_ordersCollection)
          .where('storeId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => SellerOrderDto.fromFirestore(doc).toDomain())
                .toList(),
          )
          .handleError(
            (error) => throw Exception('Failed to watch orders: $error'),
          );
    } catch (e) {
      return Stream.error(Exception('Watch orders error: $e'));
    }
  }

  @override
  Future<Either<Exception, SellerOrder>> getOrderById({
    required String orderId,
  }) async {
    try {
      if (orderId.isEmpty) {
        return Left(Exception('Invalid order ID: order ID cannot be empty'));
      }

      final doc = await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .get();

      if (!doc.exists) {
        return Left(Exception('Order not found: $orderId'));
      }

      final order = SellerOrderDto.fromFirestore(doc).toDomain();
      return Right(order);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get order: $e'));
    }
  }

  @override
  Future<Either<Exception, Unit>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      if (orderId.isEmpty) {
        return Left(Exception('Invalid order ID: order ID cannot be empty'));
      }

      if (status.isEmpty) {
        return Left(Exception('Invalid status: status cannot be empty'));
      }

      if (!_validStatuses.contains(status)) {
        return Left(
          Exception(
            'Invalid status: "$status" is not a valid order status. '
            'Valid statuses are: ${_validStatuses.join(", ")}',
          ),
        );
      }

      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(
        Exception('Firestore error during status update: ${e.message}'),
      );
    } catch (e) {
      return Left(Exception('Failed to update order status: $e'));
    }
  }

  @override
  Future<Either<Exception, Unit>> batchUpdateOrderStatus({
    required List<String> orderIds,
    required String status,
  }) async {
    try {
      if (orderIds.isEmpty) {
        return Left(
          Exception('Invalid order IDs: order ID list cannot be empty'),
        );
      }

      if (status.isEmpty) {
        return Left(Exception('Invalid status: status cannot be empty'));
      }

      if (!_validStatuses.contains(status)) {
        return Left(
          Exception(
            'Invalid status: "$status" is not a valid order status. '
            'Valid statuses are: ${_validStatuses.join(", ")}',
          ),
        );
      }

      final batch = _firestore.batch();
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      for (final orderId in orderIds) {
        batch.update(
          _firestore.collection(_ordersCollection).doc(orderId),
          updateData,
        );
      }

      await batch.commit();
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(
        Exception('Firestore error during batch status update: ${e.message}'),
      );
    } catch (e) {
      return Left(Exception('Failed to batch update order statuses: $e'));
    }
  }
}
