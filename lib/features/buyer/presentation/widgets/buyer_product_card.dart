import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/utils/price_helper.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/wishlist_controller.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';
import 'package:ecom/features/buyer/presentation/widgets/variant_selector_sheet.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/seller/domain/entities/seller_product.dart';

class BuyerProductCard extends ConsumerStatefulWidget {
  final CatalogItem product;
  final bool showTrendingBadge;
  final bool showQuantitySelector;
  final VoidCallback? onTap;

  const BuyerProductCard({
    super.key,
    required this.product,
    this.showTrendingBadge = false,
    this.showQuantitySelector = true,
    this.onTap,
  });

  @override
  ConsumerState<BuyerProductCard> createState() => _BuyerProductCardState();
}

class _BuyerProductCardState extends ConsumerState<BuyerProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<VariantOption> _colorOptionsFor(CatalogItem item) {
    if (!item.hasVariants) return const [];
    for (final attr in item.variantAttributes) {
      final n = attr.name.toLowerCase();
      final isColorAttr =
          n.contains('color') ||
              n.contains('colour') ||
              attr.options.any((o) => o.colorHex != null);
      if (isColorAttr) {
        return attr.options.where((o) => o.colorHex != null).toList();
      }
    }
    return const [];
  }

  Color _parseColorHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    final h = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final title = widget.product.title;

    final hasActiveFlashSale = PriceHelper.isFlashSaleActive(widget.product);
    final effectivePrice = PriceHelper.getEffectivePrice(widget.product);
    final originalPriceStr = '₹${widget.product.basePrice.toStringAsFixed(0)}';
    final effectivePriceStr = '₹${effectivePrice.toStringAsFixed(0)}';

    final discount = widget.product.metadata['discount'] as String? ?? '';
    final imageUrl = widget.product.imageUrls.isNotEmpty
        ? widget.product.imageUrls.first
        : null;

    final cartItems = ref.watch(cartControllerProvider);
    // For variant products: never show a stepper (multiple SKU lines could
    // exist for the same productId). Show badge with total qty instead.
    // For simple products: find the single matching cart line for the stepper.
    CartItem? matchingCartItem;
    int variantCartQuantity = 0;
    for (final item in cartItems) {
      if (item.productId == widget.product.id) {
        if (widget.product.hasVariants) {
          variantCartQuantity += item.quantity;
        } else {
          matchingCartItem = item;
          break;
        }
      }
    }

    final wishlistAsync = ref.watch(wishlistStreamProvider);
    final isInWishlist = wishlistAsync.maybeWhen(
      data: (items) => items.any((i) => i.id == widget.product.id),
      orElse: () => false,
    );

    final cardContent = GlassCardWidget(
      padding: const EdgeInsets.all(8),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Frame
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox.expand(
                      child: imageUrl.startsWith('http')
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FloatingProductWidget(
                            floatHeight: 6,
                            child: Image.asset(
                              imageUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                      : Center(
                    child: FloatingProductWidget(
                      floatHeight: 6,
                      child: Image.asset(
                        'assets/images/3d/product_headphones.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                if (widget.showTrendingBadge)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🔥 Trending',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  if (discount.isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          discount,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                // Rating pill bottom-left
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFBBF24),
                          size: 8,
                        ),
                        const SizedBox(width: 1),
                        Text(
                          '4.8',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Wishlist button
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      final notifier = ref.read(
                        wishlistControllerProvider.notifier,
                      );
                      if (isInWishlist) {
                        notifier.removeFromWishlist(widget.product.id);
                      } else {
                        notifier.addToWishlist(widget.product);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isInWishlist
                            ? const Color(0xFFEC4899).withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isInWishlist
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_colorOptionsFor(widget.product).isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 14,
              child: Row(
                children: [
                  ..._colorOptionsFor(widget.product).take(5).map((opt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _parseColorHex(opt.colorHex),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_colorOptionsFor(widget.product).length > 5)
                    Text(
                      '+${_colorOptionsFor(widget.product).length - 5}',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white70
                            : AppColors.lightTextSecond,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Price Gradient and Plus Button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: hasActiveFlashSale
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      originalPriceStr,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    GradientText(
                      effectivePriceStr,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
                    : GradientText(
                  originalPriceStr,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              if (widget.showQuantitySelector)
                if (matchingCartItem != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(cartControllerProvider.notifier)
                              .updateQuantity(matchingCartItem!.id, -1);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.remove,
                            color: isDark ? Colors.white : Colors.black87,
                            size: 10,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${matchingCartItem.quantity}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark
                                ? Colors.white
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(cartControllerProvider.notifier)
                              .updateQuantity(matchingCartItem!.id, 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: () async {
                      if (_isAdding) return;
                      setState(() => _isAdding = true);
                      try {
                        await handleAddToCart(context, ref, widget.product);
                      } finally {
                        if (mounted) setState(() => _isAdding = false);
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED)
                                    .withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isAdding
                              ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 1.5,
                            ),
                          )
                              : const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        if (variantCartQuantity > 0)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEC4899),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBgPrimary
                                      : Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Center(
                                child: Text(
                                  '$variantCartQuantity',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
            ],
          ),
        ],
      ),
    );

    if (widget.onTap == null) {
      return cardContent;
    }

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: Tween(
          begin: 1.0,
          end: 0.96,
        ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
        child: cardContent,
      ),
    );
  }
}