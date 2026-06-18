import 'package:flutter/foundation.dart';

@immutable
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

  static const int lowStockThreshold = 5;
  static const Set<String> validStatuses = {
    'active',
    'inactive',
    'archived',
    'deleted',
  };

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

  /// Check if product is currently active and available for sale
  bool get isActive => status == 'active';

  /// Check if product stock is zero or negative
  bool get isOutOfStock => stock <= 0;

  /// Check if product stock is below threshold for low-stock warnings
  bool get isLowStock => stock > 0 && stock <= lowStockThreshold;

  /// Check if product has at least one image
  bool get hasImages => imageUrls.isNotEmpty;

  /// Check if product metadata is complete
  bool get isMetadataComplete =>
      title.isNotEmpty &&
      description.isNotEmpty &&
      category.isNotEmpty &&
      basePrice > 0 &&
      imageUrls.isNotEmpty;

  /// Get total inventory value
  double get inventoryValue => basePrice * stock;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SellerProduct &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          storeId == other.storeId &&
          title == other.title &&
          description == other.description &&
          type == other.type &&
          status == other.status &&
          basePrice == other.basePrice &&
          currency == other.currency &&
          imageUrls == other.imageUrls &&
          category == other.category &&
          stock == other.stock &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      storeId.hashCode ^
      title.hashCode ^
      description.hashCode ^
      type.hashCode ^
      status.hashCode ^
      basePrice.hashCode ^
      currency.hashCode ^
      imageUrls.hashCode ^
      category.hashCode ^
      stock.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

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

  @override
  String toString() {
    return 'SellerProduct(id: $id, storeId: $storeId, title: $title, '
        'status: $status, stock: $stock, basePrice: $basePrice)';
  }
}
