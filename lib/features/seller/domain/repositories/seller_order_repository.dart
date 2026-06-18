import 'package:fpdart/fpdart.dart';

import '../entities/seller_order.dart';

abstract class SellerOrderRepository {
  Stream<List<SellerOrder>> watchOrders({required String sellerId});

  Future<Either<Exception, SellerOrder>> getOrderById({
    required String orderId,
  });

  Future<Either<Exception, Unit>> updateOrderStatus({
    required String orderId,
    required String status,
  });

  Future<Either<Exception, Unit>> batchUpdateOrderStatus({
    required List<String> orderIds,
    required String status,
  });

  Future<Either<Exception, List<SellerOrder>>> getOrdersByStatus({
    required String sellerId,
    required String status,
  });

  Future<Either<Exception, List<SellerOrder>>> getOrdersInDateRange({
    required String sellerId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
