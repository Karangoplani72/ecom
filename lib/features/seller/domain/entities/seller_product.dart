class SellerProduct {
  final String id;
  final String storeId;
  final String title;
  final String description;
  final String type;
  final String status;
  final double basePrice;
  final String currency;
  final List<String> imageUrls;
  final String category;
  final int stock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SellerProduct({
    required this.id,
    required this.storeId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.basePrice,
    required this.currency,
    required this.imageUrls,
    required this.category,
    required this.stock,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active';

  bool get isOutOfStock => stock <= 0;

  SellerProduct copyWith({
    String? id,
    String? storeId,
    String? title,
    String? description,
    String? type,
    String? status,
    double? basePrice,
    String? currency,
    List<String>? imageUrls,
    String? category,
    int? stock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SellerProduct(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      basePrice: basePrice ?? this.basePrice,
      currency: currency ?? this.currency,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
