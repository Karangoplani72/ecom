import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/seller/domain/entities/seller_product.dart';

abstract final class CatalogItemDto {
  CatalogItemDto._();

  static CatalogItem fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return fromMap(doc.id, d);
  }

  static CatalogItem fromMap(String id, Map<String, dynamic> d) {
    // variantAttributes — gracefully handle missing / malformed
    final rawAttrs = d['variantAttributes'] as List<dynamic>?;
    final variantAttributes = rawAttrs == null
        ? <VariantAttribute>[]
        : rawAttrs
              .whereType<Map>()
              .map(
                (e) => VariantAttribute.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList();

    // variantSkus — gracefully handle missing / malformed
    final rawSkus = d['variantSkus'] as List<dynamic>?;
    final variantSkus = rawSkus == null
        ? <VariantSku>[]
        : rawSkus
              .whereType<Map>()
              .map((e) => VariantSku.fromMap(Map<String, dynamic>.from(e)))
              .toList();

    // metadata sub-map — may be absent in older docs
    final meta = d['metadata'] is Map
        ? Map<String, dynamic>.from(d['metadata'] as Map)
        : <String, dynamic>{};

    // Merge top-level convenience fields into metadata
    if (d['brand'] != null && !meta.containsKey('brand')) {
      meta['brand'] = d['brand'];
    }
    if (d['tags'] != null && !meta.containsKey('tags')) {
      meta['tags'] = d['tags'];
    }

    return CatalogItem(
      id: id,
      storeId: d['storeId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      type: d['type'] as String? ?? 'physical',
      status: d['status'] as String? ?? 'active',
      isActive: d['isActive'] as bool? ?? true,
      basePrice: (d['basePrice'] as num?)?.toDouble() ?? 0.0,
      compareAtPrice: (d['compareAtPrice'] as num?)?.toDouble(),
      currency: d['currency'] as String? ?? 'INR',
      imageUrls: _parseStringList(d['imageUrls']),
      category: d['category'] as String? ?? meta['category'] as String? ?? '',
      metadata: meta,
      avgRating: (d['avgRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: d['reviewCount'] as int? ?? 0,
      variantAttributes: variantAttributes,
      variantSkus: variantSkus,
      createdAt: _toDateTime(d['createdAt']),
      updatedAt: _toDateTime(d['updatedAt']),
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  static DateTime? _toDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
