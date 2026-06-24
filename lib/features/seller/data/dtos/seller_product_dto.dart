import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/seller_product.dart';

class SellerProductDto {
  final String id;
  final String storeId;
  final String title;
  final String description;
  final String type;
  final String status;
  final double basePrice;
  final String currency;
  final List<String> imageUrls;
  final Map<String, dynamic> metadata;
  final double avgRating;
  final int reviewCount;
  final List<ProductVariant> variants;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const SellerProductDto({
    required this.id,
    required this.storeId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.basePrice,
    required this.currency,
    required this.imageUrls,
    required this.metadata,
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.variants = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory SellerProductDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return SellerProductDto(
      id: data['id'] as String? ?? '',
      storeId: data['storeId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: data['type'] as String? ?? 'product',
      status: data['status'] as String? ?? 'active',
      basePrice: (data['basePrice'] as num? ?? 0).toDouble(),
      currency: data['currency'] as String? ?? 'INR',
      imageUrls: List<String>.from(
        (data['imageUrls'] as List<dynamic>? ?? []).cast<String>(),
      ),
      metadata: Map<String, dynamic>.from(
        (data['metadata'] as Map<dynamic, dynamic>? ?? {})
            .cast<String, dynamic>(),
      ),
      avgRating: (data['avgRating'] as num? ?? 0).toDouble(),
      reviewCount: data['reviewCount'] as int? ?? 0,
      variants: (data['variants'] as List<dynamic>? ?? [])
          .map((e) => ProductVariant.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  SellerProduct toDomain() {
    final metadata = this.metadata;
    return SellerProduct(
      id: id,
      storeId: storeId,
      title: title,
      description: description,
      type: type,
      status: status,
      basePrice: basePrice,
      currency: currency,
      imageUrls: imageUrls,
      category: metadata['category'] as String? ?? '',
      stock: metadata['stock'] as int? ?? 0,
      metadata: metadata,
      avgRating: avgRating,
      reviewCount: reviewCount,
      variants: variants,
      createdAt: createdAt?.toDate(),
      updatedAt: updatedAt?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'storeId': storeId,
      'title': title,
      'description': description,
      'type': type,
      'status': status,
      'basePrice': basePrice,
      'currency': currency,
      'imageUrls': imageUrls,
      'metadata': metadata,
      'avgRating': avgRating,
      'reviewCount': reviewCount,
      'variants': variants.map((v) => v.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  SellerProductDto copyWith({
    String? id,
    String? storeId,
    String? title,
    String? description,
    String? type,
    String? status,
    double? basePrice,
    String? currency,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
    double? avgRating,
    int? reviewCount,
    List<ProductVariant>? variants,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return SellerProductDto(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      basePrice: basePrice ?? this.basePrice,
      currency: currency ?? this.currency,
      imageUrls: imageUrls ?? this.imageUrls,
      metadata: metadata ?? this.metadata,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
      variants: variants ?? this.variants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SellerProductDto &&
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
          metadata == other.metadata &&
          avgRating == other.avgRating &&
          reviewCount == other.reviewCount &&
          variants == other.variants &&
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
      metadata.hashCode ^
      avgRating.hashCode ^
      reviewCount.hashCode ^
      variants.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'SellerProductDto(id: $id, title: $title, status: $status, '
        'stock: ${metadata['stock'] ?? 0})';
  }
}
