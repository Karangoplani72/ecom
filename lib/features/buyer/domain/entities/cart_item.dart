class CartItem {
  final String id;
  final String productId;
  final String title;
  final String storeId;
  final String storeName;
  final double unitPrice;
  final String imageUrl;
  final int quantity;
  final String? skuId;
  final Map<String, String>? selectedCombination;

  const CartItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.storeId,
    required this.storeName,
    required this.unitPrice,
    required this.imageUrl,
    required this.quantity,
    this.skuId,
    this.selectedCombination,
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
    String? skuId,
    Map<String, String>? selectedCombination,
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
      skuId: skuId ?? this.skuId,
      selectedCombination: selectedCombination ?? this.selectedCombination,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'title': title,
      'storeId': storeId,
      'storeName': storeName,
      'unitPrice': unitPrice,
      'imageUrl': imageUrl,
      'quantity': quantity,
      if (skuId != null) 'skuId': skuId,
      if (selectedCombination != null)
        'selectedCombination': selectedCombination,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      storeId: map['storeId'] ?? '',
      storeName: map['storeName'] ?? '',
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity']?.toInt() ?? 1,
      skuId: map['skuId'] as String?,
      selectedCombination: (map['selectedCombination'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ),
    );
  }
}
