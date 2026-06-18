class OrderItem {
  final String productId;
  final String title;
  final String imageUrl;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => unitPrice * quantity;
}
