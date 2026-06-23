import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ecom/features/orders/data/dtos/order_dto.dart';
import 'package:ecom/features/orders/domain/entities/order.dart';
import 'package:ecom/features/orders/domain/entities/order_status.dart';
import 'package:ecom/features/orders/domain/repositories/order_repository.dart';
import 'package:fpdart/fpdart.dart';

class OrderRepositoryImpl implements OrderRepository {
  final FirebaseFirestore firestore;

  OrderRepositoryImpl({required this.firestore});

  @override
  Future<Either<String, List<String>>> checkout({
    required List<AppOrder> orders,
  }) async {
    debugPrint('[CHECKOUT] OrderRepositoryImpl.checkout: Beginning Firestore Transaction...');
    try {
      return await firestore.runTransaction((transaction) async {
        final orderIds = <String>[];

        // 1. Validate Stock for all items in all orders
        for (final order in orders) {
          debugPrint('[CHECKOUT] OrderRepositoryImpl.checkout: Validating items for order from buyer: ${order.buyerId}, storeId: ${order.storeId}');
          for (final item in order.items) {
            debugPrint('[CHECKOUT] OrderRepositoryImpl.checkout: Validating stock for productId: ${item.productId}, requested qty: ${item.quantity}');
            final productRef = firestore
                .collection('catalog')
                .doc(item.productId);
            final storeProductRef = firestore
                .collection('stores')
                .doc(order.storeId)
                .collection('products')
                .doc(item.productId);

            final productDoc = await transaction.get(productRef);

            if (!productDoc.exists) {
              debugPrint('[CHECKOUT] OrderRepositoryImpl.checkout Error: Product ${item.productId} not found in catalog');
              throw Exception('Product ${item.title} not found in catalog');
            }

            final data = productDoc.data() as Map<String, dynamic>;
            final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
            final currentStock = (metadata['stock'] as num?) ?? 0;
            debugPrint('[CHECKOUT] OrderRepositoryImpl.checkout: Product stock in DB: $currentStock');

            if (currentStock < item.quantity) {
              debugPrint('[CHECKOUT] OrderRepositoryImpl.checkout Error: Insufficient stock for ${item.title}');
              throw Exception('Insufficient stock for ${item.title}');
            }

            final newStock = currentStock - item.quantity;
            final newStatus = newStock <= 0 ? 'outOfStock' : data['status'];

            final stockUpdate = {
              'metadata.stock': newStock,
              'status': newStatus,
              'updatedAt': FieldValue.serverTimestamp(),
            };

            // 2. Deduct Stock in both collections
            debugPrint('[CHECKOUT] OrderRepositoryImpl.checkout: Deducting stock. New stock: $newStock, new status: $newStatus');
            transaction.update(productRef, stockUpdate);
            transaction.update(storeProductRef, stockUpdate);
          }
        }

        // 3. Create Order Documents
        for (final order in orders) {
          final docRef = firestore.collection('orders').doc();
          orderIds.add(docRef.id);
          debugPrint('[CHECKOUT] OrderRepositoryImpl.checkout: Creating order document with ID: ${docRef.id}');

          final dto = OrderDto(
            orderId: docRef.id,
            buyerId: order.buyerId,
            buyerName: order.buyerName,
            storeId: order.storeId,
            storeName: order.storeName,
            status: order.status.name,
            items: order.items
                .map(
                  (item) => OrderItemDto(
                    productId: item.productId,
                    title: item.title,
                    imageUrl: item.imageUrl,
                    quantity: item.quantity,
                    unitPrice: item.unitPrice,
                  ),
                )
                .toList(),
            subtotal: order.subtotal,
            deliveryFee: order.deliveryFee,
            platformFee: order.platformFee,
            totalAmount: order.totalAmount,
            paymentMethod: order.paymentMethod,
            paymentStatus: order.paymentStatus,
            deliveryAddress: order.deliveryAddress,
            createdAt: Timestamp.fromDate(order.createdAt),
            updatedAt: Timestamp.fromDate(order.updatedAt),
          );

          transaction.set(docRef, dto.toFirestore());

          // 4. Create Notifications (Atomic within transaction)
          debugPrint('[CHECKOUT] OrderRepositoryImpl.checkout: Dispatching notifications for buyer and seller');
          _addNotification(
            transaction,
            order.buyerId,
            'Order Placed',
            'Your order #${docRef.id.substring(0, 8)} has been placed successfully.',
            '/buyer/orders/${docRef.id}',
          );

          _addNotification(
            transaction,
            order.storeId,
            'New Order Received',
            'You have a new order from ${order.buyerName}.',
            '/seller/orders/${docRef.id}',
          );
        }

        debugPrint('[CHECKOUT] OrderRepositoryImpl.checkout: Transaction complete. Returning order IDs: $orderIds');
        return Right(orderIds);
      });
    } catch (e) {
      debugPrint('[CHECKOUT] OrderRepositoryImpl.checkout Exception caught: $e');
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _addNotification(
    Transaction transaction,
    String userId,
    String title,
    String body,
    String path,
  ) {
    final notifRef = firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc();
    transaction.set(notifRef, {
      'title': title,
      'body': body,
      'deepLinkPath': path,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<AppOrder>> watchBuyerOrders({required String buyerId}) {
    return firestore
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderDto.fromFirestore(doc).toDomain())
              .toList();
        });
  }

  @override
  Stream<List<AppOrder>> watchSellerOrders({required String storeId}) {
    return firestore
        .collection('orders')
        .where('storeId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderDto.fromFirestore(doc).toDomain())
              .toList();
        });
  }

  @override
  Future<Either<String, Unit>> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    try {
      await firestore.runTransaction((transaction) async {
        final orderRef = firestore.collection('orders').doc(orderId);
        final orderDoc = await transaction.get(orderRef);

        if (!orderDoc.exists) throw Exception('Order not found');

        final order = OrderDto.fromFirestore(orderDoc).toDomain();

        // Validate transition
        if (!_isValidTransition(order.status, status)) {
          throw Exception(
            'Invalid status transition from ${order.status.name} to ${status.name}',
          );
        }

        transaction.update(orderRef, {
          'status': status.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Add notification for status change
        _addNotification(
          transaction,
          order.buyerId,
          'Order Status Updated',
          'Your order #${orderId.substring(0, 8)} is now ${status.name.toUpperCase()}.',
          '/buyer/orders/$orderId',
        );
      });

      return const Right(unit);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      return Left('Failed to update order status: $message');
    }
  }

  bool _isValidTransition(OrderStatus current, OrderStatus next) {
    if (current == OrderStatus.cancelled ||
        current == OrderStatus.refunded ||
        current == OrderStatus.delivered) {
      return false;
    }

    switch (next) {
      case OrderStatus.confirmed:
        return current == OrderStatus.pending;
      case OrderStatus.packed:
        return current == OrderStatus.confirmed;
      case OrderStatus.shipped:
        return current == OrderStatus.packed;
      case OrderStatus.outForDelivery:
        return current == OrderStatus.shipped;
      case OrderStatus.delivered:
        return current == OrderStatus.outForDelivery;
      case OrderStatus.cancelled:
        return current == OrderStatus.pending ||
            current == OrderStatus.confirmed;
      case OrderStatus.refunded:
        return current == OrderStatus.delivered ||
            current == OrderStatus.cancelled;
      default:
        return false;
    }
  }

  @override
  Future<Either<String, AppOrder>> getOrderById(String orderId) async {
    try {
      final doc = await firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) return const Left('Order not found');
      return Right(OrderDto.fromFirestore(doc).toDomain());
    } catch (e) {
      return Left('Failed to fetch order: $e');
    }
  }

  @override
  Future<Either<String, Unit>> cancelOrder({
    required String orderId,
    required String userId,
    required bool isSeller,
  }) async {
    return updateOrderStatus(orderId: orderId, status: OrderStatus.cancelled);
  }
}
