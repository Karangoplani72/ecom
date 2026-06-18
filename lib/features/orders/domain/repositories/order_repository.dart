import 'package:fpdart/fpdart.dart';

import '../entities/order.dart';
import '../entities/order_status.dart';

abstract class OrderRepository {
  /// Atomic checkout: validates stock, deducts stock, creates orders.
  Future<Either<String, List<String>>> checkout({
    required List<AppOrder> orders,
  });

  Stream<List<AppOrder>> watchBuyerOrders({required String buyerId});

  Stream<List<AppOrder>> watchSellerOrders({required String storeId});

  Future<Either<String, Unit>> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  });

  Future<Either<String, AppOrder>> getOrderById(String orderId);

  Future<Either<String, Unit>> cancelOrder({
    required String orderId,
    required String userId,
    required bool isSeller,
  });
}
