import '../entities/seller_order.dart';

abstract class SellerOrderRepository {
  Stream<List<SellerOrder>> watchOrders({required String sellerId});

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  });
}
