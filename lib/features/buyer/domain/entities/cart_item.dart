class CartItem {
  final String id;
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

  CartItem copyWith({
    String? id,
    String? productId,
    String? title,
    String? storeId,
    String? storeName,
    double? unitPrice,
    String? imageUrl,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      title: title ?? this.title,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      unitPrice: unitPrice ?? this.unitPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'storeId': storeId,
      'storeName': storeName,
      'unitPrice': unitPrice,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }
}