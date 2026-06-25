import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/features/buyer/presentation/controllers/wishlist_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';
import 'package:ecom/core/utils/price_helper.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

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
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18),
        color: isDark ? Colors.white : AppColors.lightTextPrimary,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary,
      body: Stack(
        children: [
          const IgnorePointer(child: OrbBackgroundWidget()),
          wishlistAsync.when(
            loading: () => const AppLoadingView(),
            error: (error, _) => AppErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(wishlistStreamProvider),
            ),
            data: (items) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    snap: true,
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
                    title: Text(
                      'My Wishlist',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    centerTitle: true,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildFrostedCircleButton(
                          icon: Icons.shopping_cart_outlined,
                          onPressed: () => context.push('/buyer/cart'),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: GlassCardWidget(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 40,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PulsingDot(
                                      size: 24,
                                      color: const Color(0xFFEC4899),
                                    ),
                                    const Icon(
                                      Icons.favorite_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Your Wishlist is Empty',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Save your favorite items here to find them easily later.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: subtitleColor,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                GradientButton(
                                  label: 'Browse Products',
                                  width: 200,
                                  onTap: () => context.push('/buyer/products'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: ResponsiveLayout(
                          maxWidth: 1200,
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.65,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return GlassCardWidget(
                                padding: EdgeInsets.zero,
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Product Image
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                item.imageUrls.isNotEmpty
                                                    ? Image.network(
                                                        item.imageUrls.first,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Container(
                                                        color: isDark
                                                            ? Colors.white.withValues(alpha: 0.05)
                                                            : Colors.black.withValues(alpha: 0.05),
                                                        child: Icon(
                                                          Icons.image_not_supported_outlined,
                                                          color: subtitleColor,
                                                          size: 32,
                                                        ),
                                                      ),
                                                // Dark overlay at the bottom of the image for contrast
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.black.withValues(alpha: 0.4),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Product Info
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              PriceHelper.isFlashSaleActive(item)
                                                  ? Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          '₹${item.basePrice.toStringAsFixed(2)}',
                                                          style: GoogleFonts.playfairDisplay(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                            decoration: TextDecoration.lineThrough,
                                                          ),
                                                        ),
                                                        Text(
                                                          '₹${PriceHelper.getEffectivePrice(item).toStringAsFixed(2)}',
                                                          style: GoogleFonts.playfairDisplay(
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.bold,
                                                            color: const Color(0xFFA855F7),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Text(
                                                      '₹${item.basePrice.toStringAsFixed(2)}',
                                                      style: GoogleFonts.playfairDisplay(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.bold,
                                                        color: const Color(0xFFA855F7),
                                                      ),
                                                    ),
                                              const SizedBox(height: 10),
                                              GradientButton(
                                                label: 'Add to Cart',
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                                                ),
                                                onTap: () async {
                                                  try {
                                                    final effectivePrice = PriceHelper.getEffectivePrice(item);
                                                    final cartItem = CartItem(
                                                      id: item.id,
                                                      productId: item.id,
                                                      title: item.title,
                                                      storeId: item.storeId,
                                                      storeName: item.metadata['storeName'] as String? ?? 'Seller Store',
                                                      unitPrice: effectivePrice,
                                                      imageUrl: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
                                                      quantity: 1,
                                                    );
                                                    await ref.read(cartControllerProvider.notifier).addItem(cartItem);
                                                    await ref.read(wishlistControllerProvider.notifier).removeFromWishlist(item.id);
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Added to cart'),
                                                          behavior: SnackBarBehavior.floating,
                                                          duration: Duration(seconds: 1),
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Failed to add to cart: $e'),
                                                          backgroundColor: const Color(0xFFEF4444),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Remove heart button
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          ref.read(wishlistControllerProvider.notifier).removeFromWishlist(item.id);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Removed from wishlist'),
                                              behavior: SnackBarBehavior.floating,
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.black.withValues(alpha: 0.5)
                                                : Colors.white.withValues(alpha: 0.8),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.4),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.favorite_rounded,
                                            color: Color(0xFFEC4899),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
