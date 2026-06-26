import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/utils/price_helper.dart';
import 'package:ecom/core/widgets/app_network_image.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/seller/domain/entities/seller_product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Public API ──────────────────────────────────────────────────────────────

/// Single entry-point for adding any [product] to the cart.
///
/// • No variants  → adds immediately and shows a snackbar.
/// • Has variants → opens an Amazon/Flipkart-style bottom sheet so the buyer
///   picks a valid, in-stock combination first.
///
/// Returns `true` if the item actually ended up in the cart.
Future<bool> handleAddToCart(
    BuildContext context,
    WidgetRef ref,
    CatalogItem product,
    ) async {
  if (!product.hasVariants) {
    return _addSimpleItem(context, ref, product);
  }

  final added = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => VariantSelectorSheet(product: product),
  );

  if (added == true && context.mounted) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.title} added to cart'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  return added ?? false;
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

Future<bool> _addSimpleItem(
    BuildContext context,
    WidgetRef ref,
    CatalogItem product,
    ) async {
  try {
    final price = PriceHelper.getEffectivePrice(product);
    final cartItem = CartItem(
      id: product.id,
      productId: product.id,
      title: product.title,
      storeId: product.storeId,
      storeName: product.metadata['storeName'] as String? ?? 'Seller Store',
      unitPrice: price,
      imageUrl: product.coverImage.isNotEmpty
          ? product.coverImage
          : 'assets/images/3d/product_headphones.png',
      quantity: 1,
    );
    await ref.read(cartControllerProvider.notifier).addItem(cartItem);
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.title} added to cart'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return false;
  }
}

// ─── Bottom Sheet ─────────────────────────────────────────────────────────────

class VariantSelectorSheet extends ConsumerStatefulWidget {
  final CatalogItem product;

  const VariantSelectorSheet({super.key, required this.product});

  @override
  ConsumerState<VariantSelectorSheet> createState() =>
      _VariantSelectorSheetState();
}

class _VariantSelectorSheetState extends ConsumerState<VariantSelectorSheet> {
  final Map<String, String> _selected = {};
  int _quantity = 1;
  bool _isAdding = false;

  CatalogItem get product => widget.product;

  bool get _isComplete =>
      _selected.length == product.variantAttributes.length;

  VariantSku? get _sku =>
      _isComplete ? product.selectedSku(_selected) : null;

  int get _stock {
    final sku = _sku;
    return sku != null ? sku.stock : 0;
  }

  bool get _outOfStock => _isComplete && _stock <= 0;

  bool _isColorAttr(VariantAttribute attr) {
    final n = attr.name.toLowerCase();
    return n.contains('color') ||
        n.contains('colour') ||
        attr.options.any((o) => o.colorHex != null);
  }

  /// Returns true if picking [option] for [attr], combined with existing
  /// selections for other attributes, can still resolve to ≥1 in-stock SKU.
  /// This is the Amazon/Flipkart "smart availability" cascade logic.
  bool _isOptionAvailable(VariantAttribute attr, VariantOption option) {
    final hypothetical = Map<String, String>.from(_selected)
      ..[attr.name] = option.value;
    return product.variantSkus.any((sku) {
      for (final entry in hypothetical.entries) {
        if (sku.combination[entry.key] != entry.value) return false;
      }
      return sku.stock > 0;
    });
  }

  Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    final h = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  void _select(String attrName, String value) {
    setState(() {
      _selected[attrName] = value;
      _quantity = 1;
    });
  }

  Future<void> _addToCart() async {
    final sku = _sku;
    if (sku == null || _outOfStock || _isAdding) return;
    setState(() => _isAdding = true);
    try {
      final unitPrice = product.effectivePrice(_selected);
      final image = product.coverImageForCombination(_selected);
      final cartItem = CartItem(
        id: '${product.id}__${sku.skuId}',
        productId: product.id,
        title: product.title,
        storeId: product.storeId,
        storeName: product.metadata['storeName'] as String? ?? 'Seller Store',
        unitPrice: unitPrice,
        imageUrl: image.isNotEmpty
            ? image
            : 'assets/images/3d/product_headphones.png',
        quantity: _quantity,
        skuId: sku.skuId,
        selectedCombination: Map<String, String>.from(_selected),
      );
      await ref.read(cartControllerProvider.notifier).addItem(cartItem);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
    isDark ? AppColors.darkBgSurface : AppColors.lightBgSurface;
    final textPrimary =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecond =
    isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond;
    final accent =
    isDark ? AppColors.darkAccentPurple : AppColors.lightAccentPurple;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    // Price display
    final double? unitPrice = _isComplete
        ? product.effectivePrice(_selected)
        : (product.hasPriceRange ? null : product.basePrice);
    final double? compareAt = _isComplete
        ? product.compareAtPriceForCombination(_selected)
        : product.compareAtPrice;
    final String imageUrl = product.coverImageForCombination(_selected);

    // CTA label & total
    final String ctaLabel = !_isComplete
        ? 'Select all options'
        : _outOfStock
        ? 'Out of Stock'
        : 'Add to Cart  ·  ₹${(product.effectivePrice(_selected) * _quantity).toStringAsFixed(0)}';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // ── Header: image + title + price + close
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 68,
                      height: 68,
                      child: imageUrl.isNotEmpty
                          ? AppNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        child: Icon(
                          Icons.image_outlined,
                          color: textSecond,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title + price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              unitPrice != null
                                  ? '₹${unitPrice.toStringAsFixed(0)}'
                                  : '₹${product.minVariantPrice.toStringAsFixed(0)} – ₹${product.maxVariantPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: accent,
                              ),
                            ),
                            if (compareAt != null &&
                                unitPrice != null &&
                                compareAt > unitPrice) ...[
                              const SizedBox(width: 8),
                              Text(
                                '₹${compareAt.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: textSecond,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEC4899)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${(((compareAt - unitPrice) / compareAt) * 100).round()}% off',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFEC4899),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: Icon(Icons.close_rounded, color: textSecond),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: border),

            // ── Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Attribute rows
                    ...product.variantAttributes.map((attr) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label row: "Color: Red" or "Select Size"
                            Row(
                              children: [
                                Text(
                                  attr.name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selected[attr.name] != null
                                        ? _selected[attr.name]!
                                        : '— Select ${attr.name}',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _selected[attr.name] != null
                                          ? accent
                                          : textSecond,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Chips
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: attr.options.map((opt) {
                                final isSelected =
                                    _selected[attr.name] == opt.value;
                                final isAvailable =
                                _isOptionAvailable(attr, opt);
                                if (_isColorAttr(attr)) {
                                  return _ColorSwatch(
                                    option: opt,
                                    isSelected: isSelected,
                                    isAvailable: isAvailable,
                                    accent: accent,
                                    parseHex: _parseHex,
                                    onTap: () => _select(attr.name, opt.value),
                                  );
                                }
                                return _OptionChip(
                                  label: opt.value,
                                  isSelected: isSelected,
                                  isAvailable: isAvailable,
                                  isDark: isDark,
                                  accent: accent,
                                  textPrimary: textPrimary,
                                  textSecond: textSecond,
                                  border: border,
                                  onTap: () => _select(attr.name, opt.value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Stock indicator
                    if (_isComplete) ...[
                      Row(
                        children: [
                          Icon(
                            _outOfStock
                                ? Icons.block_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 15,
                            color: _outOfStock
                                ? AppColors.error
                                : AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _outOfStock
                                ? 'Out of stock for this combination'
                                : (_stock <= 10
                                ? 'Only $_stock left in stock!'
                                : 'In Stock'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _outOfStock
                                  ? AppColors.error
                                  : (_stock <= 10
                                  ? AppColors.warning
                                  : AppColors.success),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Quantity stepper (only when complete + in stock)
                    if (_isComplete && !_outOfStock) ...[
                      Row(
                        children: [
                          Text(
                            'Quantity',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _QtyBtn(
                                  icon: Icons.remove_rounded,
                                  enabled: _quantity > 1,
                                  accent: accent,
                                  onTap: () =>
                                      setState(() => _quantity--),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    '$_quantity',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                _QtyBtn(
                                  icon: Icons.add_rounded,
                                  enabled: _quantity < _stock,
                                  accent: accent,
                                  onTap: () =>
                                      setState(() => _quantity++),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),

            // ── Sticky CTA
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: GradientButton(
                label: ctaLabel,
                isLoading: _isAdding,
                onTap: (_isComplete && !_outOfStock && !_isAdding)
                    ? () => _addToCart()
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  const _QtyBtn({
    required this.icon,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? accent : Colors.grey.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final VariantOption option;
  final bool isSelected;
  final bool isAvailable;
  final Color accent;
  final Color Function(String?) parseHex;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.option,
    required this.isSelected,
    required this.isAvailable,
    required this.accent,
    required this.parseHex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = parseHex(option.colorHex);
    final luminance = chipColor.computeLuminance();
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.35,
      child: Tooltip(
        message: isAvailable
            ? option.value
            : '${option.value} (unavailable)',
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: chipColor,
                  border: Border.all(
                    color: isSelected
                        ? accent
                        : Colors.black.withValues(alpha: 0.14),
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: luminance > 0.5 ? Colors.black : Colors.white,
                )
                    : null,
              ),
              // Diagonal slash for unavailable
              if (!isAvailable)
                Transform.rotate(
                  angle: 0.785, // 45°
                  child: Container(
                    width: 46,
                    height: 1.5,
                    color: Colors.red.withValues(alpha: 0.75),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isAvailable;
  final bool isDark;
  final Color accent;
  final Color textPrimary;
  final Color textSecond;
  final Color border;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.isAvailable,
    required this.isDark,
    required this.accent,
    required this.textPrimary,
    required this.textSecond,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.38,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? accent
                : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? accent : border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : textPrimary,
              decoration:
              isAvailable ? null : TextDecoration.lineThrough,
              decorationColor: textSecond,
            ),
          ),
        ),
      ),
    );
  }
}