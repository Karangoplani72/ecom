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
  final double? compareAtPrice;
  final String currency;
  final List<String> imageUrls;
  final Map<String, dynamic> metadata;
  final double avgRating;
  final int reviewCount;
  final List<VariantAttribute> variantAttributes;
  final List<VariantSku> variantSkus;
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
    this.compareAtPrice,
    required this.currency,
    required this.imageUrls,
    required this.metadata,
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.variantAttributes = const [],
    this.variantSkus = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory SellerProductDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return SellerProductDto.fromMap(data, id: doc.id);
  }

  factory SellerProductDto.fromMap(Map<String, dynamic> data, {String? id}) {
    // New-style structured variants
    final rawAttrs = data['variantAttributes'] as List<dynamic>?;
    final rawSkus = data['variantSkus'] as List<dynamic>?;

    List<VariantAttribute> attrs = [];
    List<VariantSku> skus = [];

    if (rawAttrs != null && rawAttrs.isNotEmpty) {
      attrs = rawAttrs
          .map(
            (e) =>
                VariantAttribute.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }

    if (rawSkus != null && rawSkus.isNotEmpty) {
      skus = rawSkus
          .map((e) => VariantSku.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return SellerProductDto(
      id: (data['id'] as String?) ?? id ?? '',
      storeId: data['storeId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: data['type'] as String? ?? 'product',
      status: data['status'] as String? ?? 'active',
      basePrice: (data['basePrice'] as num? ?? 0).toDouble(),
      compareAtPrice: (data['compareAtPrice'] as num?)?.toDouble(),
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
      variantAttributes: attrs,
      variantSkus: skus,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  SellerProduct toDomain() {
    final m = metadata;
    return SellerProduct(
      id: id,
      storeId: storeId,
      title: title,
      description: description,
      type: type,
      status: status,
      basePrice: basePrice,
      compareAtPrice: compareAtPrice,
      currency: currency,
      imageUrls: imageUrls,
      category: m['category'] as String? ?? '',
      brand: m['brand'] as String?,
      tags: List<String>.from((m['tags'] as List<dynamic>?) ?? []),
      stock: m['stock'] as int? ?? 0,
      metadata: m,
      avgRating: avgRating,
      reviewCount: reviewCount,
      variantAttributes: variantAttributes,
      variantSkus: variantSkus,
      createdAt: createdAt?.toDate(),
      updatedAt: updatedAt?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'storeId': storeId,
    'title': title,
    'description': description,
    'type': type,
    'status': status,
    'basePrice': basePrice,
    if (compareAtPrice != null) 'compareAtPrice': compareAtPrice,
    'currency': currency,
    'imageUrls': imageUrls,
    'metadata': metadata,
    'avgRating': avgRating,
    'reviewCount': reviewCount,
    'variantAttributes': variantAttributes.map((a) => a.toMap()).toList(),
    'variantSkus': variantSkus.map((s) => s.toMap()).toList(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    // Indexed top-level fields for catalog queries
    'isActive': status == 'active',
    'category': metadata['category'] ?? '',
  };

  static Map<String, dynamic> domainToFirestore(SellerProduct p) {
    return {
      'id': p.id,
      'storeId': p.storeId,
      'title': p.title,
      'description': p.description,
      'type': p.type,
      'status': p.status,
      'basePrice': p.basePrice,
      if (p.compareAtPrice != null) 'compareAtPrice': p.compareAtPrice,
      'currency': p.currency,
      'imageUrls': p.imageUrls,
      'metadata': {
        'category': p.category,
        'brand': p.brand ?? '',
        'tags': p.tags,
        'stock': p.stock,
      },
      'avgRating': p.avgRating,
      'reviewCount': p.reviewCount,
      'variantAttributes': p.variantAttributes.map((a) => a.toMap()).toList(),
      'variantSkus': p.variantSkus.map((s) => s.toMap()).toList(),
      'isActive': p.status == 'active',
      'category': p.category,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
