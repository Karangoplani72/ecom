import 'order_item.dart';
import 'order_status.dart';

class AppOrder {
  final String orderId;
  final String buyerId;
  final String buyerName;
  final String storeId;
  final String storeName;
  final OrderStatus status;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double platformFee;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  // Razorpay payment identifiers — null for non-Razorpay orders
  final String? paymentId;
  final String? razorpayOrderId;
  final String deliveryAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppOrder({
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.storeId,
    required this.storeName,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.platformFee,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentId,
    this.razorpayOrderId,
    required this.deliveryAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get canCancel =>
      status == OrderStatus.pending ||
      status == OrderStatus.confirmed ||
      status == OrderStatus.packed;

  bool get isCompleted => status == OrderStatus.delivered;

  bool get isPaid => paymentStatus == 'completed';
}
