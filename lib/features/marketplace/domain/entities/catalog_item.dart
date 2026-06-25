import 'package:ecom/features/seller/domain/entities/seller_product.dart';
import 'package:flutter/foundation.dart';

@immutable
class CatalogItem {
  final String id;
  final String storeId;
  final String title;
  final String description;
  final String type;
  final String status;
  final bool isActive;

  final double basePrice;
  final double? compareAtPrice;
  final String currency;

  /// Product-level gallery (fallback when no SKU image)
  final List<String> imageUrls;

  final String category;
  final Map<String, dynamic> metadata;

  final double avgRating;
  final int reviewCount;

  final List<VariantAttribute> variantAttributes;
  final List<VariantSku> variantSkus;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CatalogItem({
    required this.id,
    required this.storeId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.isActive,
    required this.basePrice,
    this.compareAtPrice,
    required this.currency,
    required this.imageUrls,
    required this.category,
    required this.metadata,
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.variantAttributes = const [],
    this.variantSkus = const [],
    this.createdAt,
    this.updatedAt,
  });

  // ── Computed ──────────────────────────────────────────────────────────────

  bool get hasVariants => variantAttributes.isNotEmpty;

  String? get brand => metadata['brand'] as String?;

  List<String> get tags => ((metadata['tags'] as List<dynamic>?) ?? [])
      .map((e) => e.toString())
      .toList();

  int get totalStock {
    if (hasVariants && variantSkus.isNotEmpty) {
      return variantSkus.fold(0, (sum, s) => sum + s.stock);
    }
    return (metadata['stock'] as int?) ?? 0;
  }

  bool get isOutOfStock => totalStock <= 0;

  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > basePrice;

  int? get discountPercent {
    if (!hasDiscount) return null;
    return (((compareAtPrice! - basePrice) / compareAtPrice!) * 100).round();
  }

  String get coverImage => imageUrls.isNotEmpty ? imageUrls.first : '';

  /// Returns all images for a given combination:
  /// 1. SKU-specific imageUrl (highest priority)
  /// 2. First matching option imageUrl (e.g. color variant image)
  /// 3. Product-level gallery as fallback
  List<String> imagesForCombination(Map<String, String> combination) {
    if (!hasVariants || combination.isEmpty) return imageUrls;

    final sku = selectedSku(combination);
    if (sku?.imageUrl != null && sku!.imageUrl!.isNotEmpty) {
      // SKU image first, then product gallery
      return [sku.imageUrl!, ...imageUrls.where((u) => u != sku.imageUrl)];
    }

    // Try to find a matching option image (e.g. Color attribute)
    for (final attr in variantAttributes) {
      final selectedValue = combination[attr.name];
      if (selectedValue == null) continue;
      final opt = attr.options
          .where((o) => o.value == selectedValue)
          .firstOrNull;
      if (opt?.imageUrl != null && opt!.imageUrl!.isNotEmpty) {
        return [opt.imageUrl!, ...imageUrls.where((u) => u != opt.imageUrl)];
      }
    }

    return imageUrls;
  }

  /// Returns cover image for a specific combination
  String coverImageForCombination(Map<String, String> combination) {
    final imgs = imagesForCombination(combination);
    return imgs.isNotEmpty ? imgs.first : '';
  }

  /// Returns the effective unit price for a given variant combination.
  /// With new absolute SKU prices, returns sku.price directly.
  double effectivePrice(Map<String, String> combination) {
    if (!hasVariants || combination.isEmpty) return basePrice;
    final sku = selectedSku(combination);
    if (sku == null) return basePrice;
    // If sku.price > 0 use it (new absolute model), else fall back to basePrice
    return sku.price > 0 ? sku.price : basePrice;
  }

  /// Returns the compareAtPrice for a given combination
  double? compareAtPriceForCombination(Map<String, String> combination) {
    if (!hasVariants || combination.isEmpty) return compareAtPrice;
    final sku = selectedSku(combination);
    return sku?.compareAtPrice ?? compareAtPrice;
  }

  /// Minimum price across all SKUs (for "from ₹X" display)
  double get minVariantPrice {
    if (!hasVariants || variantSkus.isEmpty) return basePrice;
    return variantSkus
        .map((s) => s.price > 0 ? s.price : basePrice)
        .reduce((a, b) => a < b ? a : b);
  }

  double get maxVariantPrice {
    if (!hasVariants || variantSkus.isEmpty) return basePrice;
    return variantSkus
        .map((s) => s.price > 0 ? s.price : basePrice)
        .reduce((a, b) => a > b ? a : b);
  }

  bool get hasPriceRange => hasVariants && minVariantPrice != maxVariantPrice;

  /// Finds the matching SKU for a combination map.
  VariantSku? selectedSku(Map<String, String> combination) {
    if (!hasVariants || combination.isEmpty) return null;
    try {
      return variantSkus.firstWhere(
        (s) => mapEquals(s.combination, combination),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns whether a specific combination is in stock
  bool isSkuInStock(Map<String, String> combination) {
    if (!hasVariants) return totalStock > 0;
    final sku = selectedSku(combination);
    return (sku?.stock ?? 0) > 0;
  }
}
