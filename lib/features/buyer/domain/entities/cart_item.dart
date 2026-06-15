class CartItem {
  final String id; // Unique cart item ID
  final String productId;
  final String title;
  final String storeId;
  final String storeName;
  final double unitPrice;
  final String imageUrl;
  final int quantity;

  const CartItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.storeId,
    required this.storeName,
    required this.unitPrice,
    required this.imageUrl,
    required this.quantity,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      productId: productId,
      title: title,
      storeId: storeId,
      storeName: storeName,
      unitPrice: unitPrice,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }
}