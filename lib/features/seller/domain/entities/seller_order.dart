class SellerOrderItem {
  final String productId;
  final String title;
  final int quantity;
  final double unitPrice;

  const SellerOrderItem({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
  });
}

class SellerOrder {
  final String id;
  final String buyerId;
  final String buyerName;
  final String storeId;
  final String status;
  final List<SellerOrderItem> items;
  final double totalAmount;
  final String deliveryAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SellerOrder({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.storeId,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == 'pending';

  bool get isProcessing => status == 'processing';

  bool get isShipped => status == 'shipped';

  bool get isDelivered => status == 'delivered';

  bool get isCancelled => status == 'cancelled';
}
