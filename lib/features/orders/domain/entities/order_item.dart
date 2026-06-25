class OrderItem {
  final String productId;
  final String title;
  final String imageUrl;
  final int quantity;
  final double unitPrice;
  final String? skuId;
  final Map<String, String>? selectedCombination;

  const OrderItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    this.skuId,
    this.selectedCombination,
  });

  double get totalPrice => unitPrice * quantity;
}
