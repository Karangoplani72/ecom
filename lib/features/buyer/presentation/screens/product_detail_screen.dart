import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/wishlist_controller.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/marketplace/presentation/controllers/marketplace_controller.dart';
import 'package:ecom/core/utils/price_helper.dart';
import 'package:ecom/shared/presentation/widgets/cart_icon_with_badge.dart';
import 'package:ecom/shared/presentation/widgets/wishlist_icon_with_badge.dart';
import 'package:ecom/shared/presentation/widgets/notification_bell.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedColorIndex = 0;
  bool _isDescriptionExpanded = false;
  late final PageController _imagePageController;
  late final TextEditingController _searchController;
  int _currentImageIndex = 0;
  bool _isActionLoading = false;

  final List<Color> _fallbackColors = [
    const Color(0xFF7C3AED),
    const Color(0xFFEC4899),
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
  ];

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final wishlistAsync = ref.watch(wishlistStreamProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary,
      body: productAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (product) {
          final hasActiveFlashSale = PriceHelper.isFlashSaleActive(product);
          final effectivePrice = PriceHelper.getEffectivePrice(product);
          final originalPriceStr = '₹${product.basePrice.toStringAsFixed(0)}';
          final effectivePriceStr = '₹${effectivePrice.toStringAsFixed(0)}';

          final wishlist = wishlistAsync.value ?? <CatalogItem>[];
          final isInWishlist = wishlist.any((item) => item.id == product.id);

          final List<Color> colorOptions = [];
          if (product.metadata['colors'] is List) {
            for (final c in product.metadata['colors']) {
              if (c is String) {
                final cleaned = c.replaceAll('#', '');
                final val = int.tryParse('0xFF$cleaned');
                if (val != null) colorOptions.add(Color(val));
              }
            }
          }
          final colorsToUse =
              colorOptions.isNotEmpty ? colorOptions : _fallbackColors;

          final discount = product.metadata['discount'] as String? ?? '';
          final oldPrice = product.metadata['oldPrice'] as String? ?? '';
          final category =
              product.metadata['category'] as String? ?? 'Products';

          final double screenHeight = MediaQuery.of(context).size.height;

          return Stack(
            children: [
              const IgnorePointer(child: OrbBackgroundWidget()),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. SliverAppBar with Image Slider
                  SliverAppBar(
                    expandedHeight: screenHeight * 0.42,
                    collapsedHeight: 80,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leadingWidth: 70,
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Center(
                        child: _buildFrostedCircleButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onPressed: () => context.pop(),
                          isDark: isDark,
                        ),
                      ),
                    ),
                    actions: [
                      _buildFrostedWishlistButton(
                        isInWishlist: isInWishlist,
                        onPressed: () async {
                          final notifier = ref
                              .read(wishlistControllerProvider.notifier);
                          if (isInWishlist) {
                            await notifier.removeFromWishlist(product.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Removed from wishlist'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          } else {
                            await notifier.addToWishlist(product);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to wishlist'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(width: 4),
                      const NotificationBell(),
                      const WishlistIconWithBadge(),
                      const CartIconWithBadge(),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Images PageView
                          Hero(
                            tag: 'product_${product.id}',
                            child: PageView.builder(
                              controller: _imagePageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemCount: product.imageUrls.isNotEmpty
                                  ? product.imageUrls.length
                                  : 1,
                              itemBuilder: (context, index) {
                                final hasImage = product.imageUrls.isNotEmpty;
                                final url = hasImage
                                    ? product.imageUrls[index]
                                    : null;
                                return Container(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.02)
                                      : Colors.black.withValues(alpha: 0.02),
                                  child: Center(
                                    child: FloatingProductWidget(
                                      floatHeight: 12.0,
                                      child: url != null &&
                                              url.startsWith('http')
                                          ? Image.network(
                                              url,
                                              width: 240,
                                              height: 240,
                                              fit: BoxFit.contain,
                                            )
                                          : Image.asset(
                                              url ??
                                                  'assets/images/3d/product_headphones.png',
                                              width: 240,
                                              height: 240,
                                              fit: BoxFit.contain,
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Bottom Gradient Overlay for Seamless Blend
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.transparent,
                                    (isDark
                                            ? AppColors.darkBgPrimary
                                            : AppColors.lightBgPrimary)
                                        .withValues(alpha: 0.8),
                                    isDark
                                        ? AppColors.darkBgPrimary
                                        : AppColors.lightBgPrimary,
                                  ],
                                  stops: const [0.0, 0.6, 0.9, 1.0],
                                ),
                              ),
                            ),
                          ),
                          // Page Dots Indicator
                          if (product.imageUrls.length > 1)
                            Positioned(
                              bottom: 24,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  product.imageUrls.length,
                                  (index) {
                                    final isSel = _currentImageIndex == index;
                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      height: 6,
                                      width: isSel ? 20 : 6,
                                      decoration: BoxDecoration(
                                        gradient: isSel
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF7C3AED),
                                                  Color(0xFFA855F7)
                                                ],
                                              )
                                            : null,
                                        color: isSel
                                            ? null
                                            : Colors.grey
                                                .withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
 
                  // Search Bar (same style as home screen)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.1 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: GoogleFonts.inter(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search products, brands & more...',
                                  hintStyle: GoogleFonts.inter(
                                    color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) => setState(() {}),
                                onSubmitted: (val) {
                                  if (val.trim().isNotEmpty) {
                                    context.go('/buyer/products?search=${Uri.encodeComponent(val.trim())}');
                                  }
                                },
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
 
                  // 2. Content Info Panel
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 130),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBgSurface.withValues(alpha: 0.8)
                              : AppColors.lightBgSurface.withValues(alpha: 0.9),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: isDark ? 0.08 : 0.6,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, -10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFA855F7),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFA855F7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Product Title
                            Text(
                              product.title,
                              style: GoogleFonts.playfairDisplay(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Rating and Reviews Row
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '4.8',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(142 reviews)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecond
                                        : AppColors.lightTextSecond,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_user_rounded,
                                        color: Color(0xFF10B981),
                                        size: 11,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF10B981),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Price and discount Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                if (hasActiveFlashSale) ...[
                                  GradientText(
                                    effectivePriceStr,
                                    style: GoogleFonts.inter(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    originalPriceStr,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEC4899),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${(PriceHelper.getDiscountPercent(product) * 100).toStringAsFixed(0)}% OFF',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  GradientText(
                                    originalPriceStr,
                                    style: GoogleFonts.inter(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (oldPrice.isNotEmpty)
                                    Text(
                                      '₹$oldPrice',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  if (discount.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEC4899)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '-$discount',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFFEC4899),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                            const Divider(height: 32, thickness: 0.5),

                            // Product Description with Read More
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isDescriptionExpanded =
                                      !_isDescriptionExpanded;
                                });
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    child: Text(
                                      product.description,
                                      maxLines:
                                          _isDescriptionExpanded ? null : 3,
                                      overflow: _isDescriptionExpanded
                                          ? TextOverflow.visible
                                          : TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        height: 1.6,
                                        color: isDark
                                            ? AppColors.darkTextSecond
                                            : AppColors.lightTextSecond,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isDescriptionExpanded
                                        ? 'Read less'
                                        : 'Read more',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF7C3AED),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 32, thickness: 0.5),

                            // Color Chips Row
                            Text(
                              'Select Color',
                              style: GoogleFonts.inter(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: List.generate(
                                colorsToUse.length,
                                (index) {
                                  final isSel = _selectedColorIndex == index;
                                  return GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedColorIndex = index,
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: colorsToUse[index],
                                        shape: BoxShape.circle,
                                        border: isSel
                                            ? Border.all(
                                                color: const Color(0xFF7C3AED),
                                                width: 2,
                                              )
                                            : null,
                                        boxShadow: isSel
                                            ? [
                                                BoxShadow(
                                                  color: colorsToUse[index]
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                )
                                              ]
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Quantity Stepper
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Quantity',
                                  style: GoogleFonts.inter(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.lightTextPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  height: 38,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: isDark ? 0.08 : 0.15,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        iconSize: 16,
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.remove),
                                        onPressed: () {
                                          if (_quantity > 1) {
                                            setState(() => _quantity--);
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$_quantity',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        iconSize: 16,
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          setState(() => _quantity++);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32, thickness: 0.5),

                            // Store info card
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.store_mall_directory_rounded,
                                    color: Color(0xFF7C3AED),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.metadata['storeName']
                                                as String? ??
                                            'Seller Store',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Active seller store',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Visit Store →',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF7C3AED),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 3. Floating Bottom Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.darkBgSurface
                                : AppColors.lightBgSurface)
                            .withValues(alpha: 0.85),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(
                              alpha: isDark ? 0.08 : 0.3,
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionBtn(
                              label: 'Add to Cart',
                              isOutlined: true,
                              isLoading: _isActionLoading,
                              onTap: () async {
                                if (_isActionLoading) return;
                                setState(() => _isActionLoading = true);
                                try {
                                  final cartItem = CartItem(
                                    id: product.id,
                                    productId: product.id,
                                    title: product.title,
                                    storeId: product.storeId,
                                    storeName: product.metadata['storeName']
                                            as String? ??
                                        'Seller Store',
                                    unitPrice: effectivePrice,
                                    imageUrl: product.imageUrls.isNotEmpty
                                        ? product.imageUrls.first
                                        : 'assets/images/3d/product_headphones.png',
                                    quantity: _quantity,
                                  );

                                  await ref
                                      .read(cartControllerProvider.notifier)
                                      .addItem(cartItem);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Added $_quantity x ${product.title} to cart!',
                                        ),
                                        backgroundColor:
                                            const Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.all(16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        duration: const Duration(
                                          milliseconds: 1500,
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to add to cart: $e'),
                                        backgroundColor:
                                            const Color(0xFFEF4444),
                                      ),
                                    );
                                  }
                                } finally {
                                  setState(() => _isActionLoading = false);
                                }
                              },
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildActionBtn(
                              label: 'Buy Now',
                              isOutlined: false,
                              isLoading: _isActionLoading,
                              onTap: () async {
                                if (_isActionLoading) return;
                                setState(() => _isActionLoading = true);
                                try {
                                  final cartItem = CartItem(
                                    id: product.id,
                                    productId: product.id,
                                    title: product.title,
                                    storeId: product.storeId,
                                    storeName: product.metadata['storeName']
                                            as String? ??
                                        'Seller Store',
                                    unitPrice: effectivePrice,
                                    imageUrl: product.imageUrls.isNotEmpty
                                        ? product.imageUrls.first
                                        : 'assets/images/3d/product_headphones.png',
                                    quantity: _quantity,
                                  );

                                  await ref
                                      .read(cartControllerProvider.notifier)
                                      .addItem(cartItem);

                                  if (context.mounted) {
                                    context.push('/buyer/cart');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to add to cart: $e'),
                                        backgroundColor:
                                            const Color(0xFFEF4444),
                                      ),
                                    );
                                  }
                                } finally {
                                  setState(() => _isActionLoading = false);
                                }
                              },
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFrostedCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.2),
        ),
      ),
      child: Center(
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            icon,
            size: 16,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildFrostedWishlistButton({
    required bool isInWishlist,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.2),
        ),
      ),
      child: Center(
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            isInWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 18,
            color: isInWishlist ? const Color(0xFFEC4899) : (isDark ? Colors.white : AppColors.lightTextPrimary),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required bool isOutlined,
    required bool isLoading,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GradientButton(
      label: label,
      onTap: onTap,
      isLoading: isLoading,
      gradient: isOutlined
          ? LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.04),
              ],
            )
          : const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
            ),
    );
  }
}
