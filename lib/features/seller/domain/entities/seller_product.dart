import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Industry-grade variant model
//
// Architecture:
//   Product → VariantAttribute[] (e.g. "Color", "Size")
//             Each VariantAttribute → VariantOption[] (e.g. "Red", "M")
//             Each VariantOption   → optional imageUrl (variant hero image)
//   Cross-product of all options  → VariantSku[] (each SKU = one unique combo)
//   Each VariantSku               → own price, stock, skuCode, imageUrl
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class VariantOption {
  final String value; // e.g. "M", "Red", "128GB"
  final String? colorHex; // optional, for color swatches
  final String? imageUrl; // optional per-option image (e.g. color swatch photo)

  const VariantOption({required this.value, this.colorHex, this.imageUrl});

  Map<String, dynamic> toMap() => {
    'value': value,
    if (colorHex != null) 'colorHex': colorHex,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  factory VariantOption.fromMap(Map<String, dynamic> m) => VariantOption(
    value: m['value'] as String? ?? '',
    colorHex: m['colorHex'] as String?,
    imageUrl: m['imageUrl'] as String?,
  );

  VariantOption copyWith({String? value, String? colorHex, String? imageUrl}) =>
      VariantOption(
        value: value ?? this.value,
        colorHex: colorHex ?? this.colorHex,
        imageUrl: imageUrl ?? this.imageUrl,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariantOption &&
          value == other.value &&
          colorHex == other.colorHex &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => value.hashCode ^ colorHex.hashCode ^ imageUrl.hashCode;
}

@immutable
class VariantAttribute {
  final String name; // e.g. "Size", "Color", "Storage"
  final List<VariantOption> options;

  const VariantAttribute({required this.name, required this.options});

  Map<String, dynamic> toMap() => {
    'name': name,
    'options': options.map((o) => o.toMap()).toList(),
  };

  factory VariantAttribute.fromMap(Map<String, dynamic> m) => VariantAttribute(
    name: m['name'] as String? ?? '',
    options: ((m['options'] as List<dynamic>?) ?? [])
        .map((e) => VariantOption.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariantAttribute &&
          name == other.name &&
          listEquals(options, other.options);

  @override
  int get hashCode => name.hashCode ^ options.hashCode;
}

/// A single SKU — the intersection of one option from each attribute group.
/// e.g. { "Color": "Red", "Size": "M" } => price: 999, stock: 10
@immutable
class VariantSku {
  final String skuId; // auto-generated composite key
  final Map<String, String> combination; // {"Color": "Red", "Size": "M"}
  final double price; // absolute selling price for this SKU
  final double? compareAtPrice; // MRP / strike-through for this SKU
  final int stock;
  final String? skuCode; // optional external SKU reference
  final String? imageUrl; // per-SKU image (overrides product gallery)

  const VariantSku({
    required this.skuId,
    required this.combination,
    required this.price,
    this.compareAtPrice,
    this.stock = 0,
    this.skuCode,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
    'skuId': skuId,
    'combination': combination,
    'price': price,
    if (compareAtPrice != null) 'compareAtPrice': compareAtPrice,
    'stock': stock,
    if (skuCode != null) 'skuCode': skuCode,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  factory VariantSku.fromMap(Map<String, dynamic> m) {
    // Support both old priceAdjustment-based docs and new absolute price docs
    double resolvedPrice;
    if (m.containsKey('price')) {
      resolvedPrice = (m['price'] as num?)?.toDouble() ?? 0.0;
    } else {
      // Legacy: treat priceAdjustment as absolute price fallback
      resolvedPrice = (m['priceAdjustment'] as num?)?.toDouble() ?? 0.0;
    }
    return VariantSku(
      skuId: m['skuId'] as String? ?? '',
      combination: Map<String, String>.from(
        (m['combination'] as Map<dynamic, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
      ),
      price: resolvedPrice,
      compareAtPrice: (m['compareAtPrice'] as num?)?.toDouble(),
      stock: m['stock'] as int? ?? 0,
      skuCode: m['skuCode'] as String?,
      imageUrl: m['imageUrl'] as String?,
    );
  }

  String get displayLabel => combination.values.join(' / ');

  bool get hasDiscount =>
      compareAtPrice != null && compareAtPrice! > price && compareAtPrice! > 0;

  int? get discountPercent {
    if (!hasDiscount) return null;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  VariantSku copyWith({
    double? price,
    double? compareAtPrice,
    int? stock,
    String? skuCode,
    String? imageUrl,
  }) => VariantSku(
    skuId: skuId,
    combination: combination,
    price: price ?? this.price,
    compareAtPrice: compareAtPrice ?? this.compareAtPrice,
    stock: stock ?? this.stock,
    skuCode: skuCode ?? this.skuCode,
    imageUrl: imageUrl ?? this.imageUrl,
  );

  /// Returns a copy with compareAtPrice cleared
  VariantSku withoutComparePrice() => VariantSku(
    skuId: skuId,
    combination: combination,
    price: price,
    compareAtPrice: null,
    stock: stock,
    skuCode: skuCode,
    imageUrl: imageUrl,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariantSku &&
          skuId == other.skuId &&
          mapEquals(combination, other.combination) &&
          price == other.price &&
          stock == other.stock;

  @override
  int get hashCode =>
      skuId.hashCode ^ combination.hashCode ^ price.hashCode ^ stock.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy ProductVariant — kept for backward-compat with old documents
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class ProductVariant {
  final String id;
  final String name;
  final String value;
  final double extraPrice;
  final int stock;

  const ProductVariant({
    required this.id,
    required this.name,
    required this.value,
    this.extraPrice = 0.0,
    this.stock = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'value': value,
    'extraPrice': extraPrice,
    'stock': stock,
  };

  factory ProductVariant.fromMap(Map<String, dynamic> map) => ProductVariant(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    value: map['value'] as String? ?? '',
    extraPrice: (map['extraPrice'] as num?)?.toDouble() ?? 0.0,
    stock: map['stock'] as int? ?? 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SellerProduct
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class SellerProduct {
  final String id;
  final String storeId;
  final String title;
  final String description;
  final String type;
  final String status;

  /// Base price used for simple (no-variant) products.
  /// For variant products the price lives on each VariantSku.
  final double basePrice;
  final double? compareAtPrice;
  final String currency;

  /// Product-level gallery (shown when no SKU-specific image is available)
  final List<String> imageUrls;

  final String category;
  final String? brand;
  final List<String> tags;

  /// Simple product stock (0 when using variant SKUs)
  final int stock;
  final Map<String, dynamic> metadata;

  final double avgRating;
  final int reviewCount;

  final List<VariantAttribute> variantAttributes;
  final List<VariantSku> variantSkus;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const int lowStockThreshold = 5;
  static const Set<String> validStatuses = {
    'active',
    'inactive',
    'archived',
    'draft',
  };

  const SellerProduct({
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
    required this.category,
    this.brand,
    this.tags = const [],
    required this.stock,
    required this.metadata,
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.variantAttributes = const [],
    this.variantSkus = const [],
    this.createdAt,
    this.updatedAt,
  });

  // ── Computed ───────────────────────────────────────────────────────────────

  bool get hasVariants => variantAttributes.isNotEmpty;

  bool get isActive => status == 'active';

  bool get isOutOfStock => totalStock <= 0;

  bool get isLowStock => totalStock > 0 && totalStock <= lowStockThreshold;

  bool get hasImages => imageUrls.isNotEmpty;

  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > basePrice;

  int get totalStock {
    if (hasVariants && variantSkus.isNotEmpty) {
      return variantSkus.fold(0, (sum, s) => sum + s.stock);
    }
    return stock;
  }

  double get inventoryValue => basePrice * totalStock;

  int? get discountPercent {
    if (!hasDiscount) return null;
    return (((compareAtPrice! - basePrice) / compareAtPrice!) * 100).round();
  }

  /// Returns the minimum SKU price for display purposes
  double get minVariantPrice {
    if (!hasVariants || variantSkus.isEmpty) return basePrice;
    return variantSkus.map((s) => s.price).reduce((a, b) => a < b ? a : b);
  }

  /// Returns the maximum SKU price for display purposes
  double get maxVariantPrice {
    if (!hasVariants || variantSkus.isEmpty) return basePrice;
    return variantSkus.map((s) => s.price).reduce((a, b) => a > b ? a : b);
  }

  SellerProduct copyWith({
    String? id,
    String? storeId,
    String? title,
    String? description,
    String? type,
    String? status,
    double? basePrice,
    double? compareAtPrice,
    String? currency,
    List<String>? imageUrls,
    String? category,
    String? brand,
    List<String>? tags,
    int? stock,
    Map<String, dynamic>? metadata,
    double? avgRating,
    int? reviewCount,
    List<VariantAttribute>? variantAttributes,
    List<VariantSku>? variantSkus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SellerProduct(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    status: status ?? this.status,
    basePrice: basePrice ?? this.basePrice,
    compareAtPrice: compareAtPrice ?? this.compareAtPrice,
    currency: currency ?? this.currency,
    imageUrls: imageUrls ?? this.imageUrls,
    category: category ?? this.category,
    brand: brand ?? this.brand,
    tags: tags ?? this.tags,
    stock: stock ?? this.stock,
    metadata: metadata ?? this.metadata,
    avgRating: avgRating ?? this.avgRating,
    reviewCount: reviewCount ?? this.reviewCount,
    variantAttributes: variantAttributes ?? this.variantAttributes,
    variantSkus: variantSkus ?? this.variantSkus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  String toString() =>
      'SellerProduct(id: $id, title: $title, status: $status, stock: $totalStock)';
}
