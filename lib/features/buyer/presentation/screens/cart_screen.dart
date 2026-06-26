import 'dart:ui';

import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/guest_cart_controller.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/admin/domain/entities/platform_config.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkBgSurface
            : AppColors.lightBgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Clear Cart',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove all items from your cart?',
          style: GoogleFonts.inter(
            color: isDark
                ? AppColors.darkTextSecond
                : AppColors.lightTextSecond,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: isDark
                    ? AppColors.darkTextSecond
                    : AppColors.lightTextSecond,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartControllerProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            child: Text(
              'Clear',
              style: GoogleFonts.inter(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final cartAsync = userId == null
        ? AsyncValue.data(ref.watch(guestCartControllerProvider))
        : ref.watch(cartStreamProvider);
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBgPrimary
          : AppColors.lightBgPrimary,
      body: Stack(
        children: [
          const IgnorePointer(child: OrbBackgroundWidget()),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom Blurred SliverAppBar
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
                  'My Cart',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                centerTitle: true,
                actions: [
                  cartAsync.when(
                    data: (items) => items.isNotEmpty
                        ? TextButton(
                            onPressed: () =>
                                _showClearCartDialog(context, ref, isDark),
                            child: Text(
                              'Clear All',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (err, stack) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 16),
                ],
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  AppColors.darkBgPrimary.withValues(
                                    alpha: 0.95,
                                  ),
                                  AppColors.darkBgPrimary.withValues(
                                    alpha: 0.6,
                                  ),
                                ]
                              : [
                                  AppColors.lightBgPrimary.withValues(
                                    alpha: 0.95,
                                  ),
                                  AppColors.lightBgPrimary.withValues(
                                    alpha: 0.6,
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Cart Content
              cartAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  ),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Error: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                data: (cartItems) {
                  if (cartItems.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Center(
                          child: GlassCardWidget(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF7C3AED),
                                        Color(0xFFA855F7),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF7C3AED,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 56,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Your cart is empty',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Explore our products and add items you love',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextSecond
                                        : AppColors.lightTextSecond,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                GradientButton(
                                  label: 'Start Shopping',
                                  onTap: () => context.go('/buyer/products'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 180),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = cartItems[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) {
                              ref
                                  .read(cartControllerProvider.notifier)
                                  .removeItem(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${item.title} removed from cart',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            child: GlassCardWidget(
                              padding: const EdgeInsets.all(12),
                              borderRadius: 20,
                              child: Row(
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: item.imageUrl.startsWith('http')
                                        ? Image.network(
                                            item.imageUrl,
                                            width: 68,
                                            height: 68,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            item.imageUrl,
                                            width: 68,
                                            height: 68,
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Content Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.storeName,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.darkTextSecond
                                                : AppColors.lightTextSecond,
                                          ),
                                        ),
                                        if (item.selectedCombination != null &&
                                            item
                                                .selectedCombination!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.selectedCombination!.entries
                                                .map(
                                                  (e) => '${e.key}: ${e.value}',
                                                )
                                                .join(' · '),
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? AppColors.darkAccentPurple
                                                  : AppColors.lightAccentPurple,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            GradientText(
                                              '₹${item.unitPrice.toStringAsFixed(0)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            Container(
                                              height: 32,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.05,
                                                      )
                                                    : Colors.black.withValues(
                                                        alpha: 0.03,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    iconSize: 14,
                                                    padding: EdgeInsets.zero,
                                                    icon: const Icon(
                                                      Icons.remove,
                                                    ),
                                                    onPressed: () {
                                                      ref
                                                          .read(
                                                            cartControllerProvider
                                                                .notifier,
                                                          )
                                                          .updateQuantity(
                                                            item.id,
                                                            -1,
                                                          );
                                                    },
                                                  ),
                                                  Text(
                                                    '${item.quantity}',
                                                    style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    iconSize: 14,
                                                    padding: EdgeInsets.zero,
                                                    icon: const Icon(Icons.add),
                                                    onPressed: () {
                                                      ref
                                                          .read(
                                                            cartControllerProvider
                                                                .notifier,
                                                          )
                                                          .updateQuantity(
                                                            item.id,
                                                            1,
                                                          );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }, childCount: cartItems.length),
                    ),
                  );
                },
              ),
            ],
          ),

          // Order summary & proceed CTA
          cartAsync.maybeWhen(
            data: (cartItems) {
              if (cartItems.isEmpty) return const SizedBox.shrink();

              final subtotal = cartItems.fold<double>(
                0.0,
                (sum, item) => sum + (item.unitPrice * item.quantity),
              );

              final groupedItems = <String, List<CartItem>>{};
              for (final item in cartItems) {
                groupedItems.putIfAbsent(item.storeId, () => <CartItem>[]);
                groupedItems[item.storeId]!.add(item);
              }

              final platformConfig = ref.watch(platformConfigProvider).value ??
                  const PlatformConfig(
                    defaultCommissionRate: 0.085,
                    categoryCommissionOverrides: {},
                    maintenanceModeActive: false,
                    globalRateLimitPerMinute: 600,
                    razorpayKey: 'managed_via_functions',
                    announcementText: '',
                    featuredCategory: '',
                  );

              final platformFee = subtotal * platformConfig.defaultCommissionRate;
              double deliveryFee = 0.0;
              groupedItems.forEach((storeId, items) {
                final storeSub = items.fold<double>(
                  0.0,
                  (sum, item) => sum + (item.unitPrice * item.quantity),
                );
                if (storeSub < 1000) {
                  deliveryFee += 99.0;
                }
              });

              final total = subtotal + platformFee + deliveryFee;

              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      decoration: BoxDecoration(
                        color:
                            (isDark
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSummaryRow(
                            'Subtotal',
                            '₹${subtotal.toStringAsFixed(0)}',
                            isDark,
                          ),
                          const SizedBox(height: 6),
                          _buildSummaryRow(
                            'Delivery Fee',
                            '₹${deliveryFee.toStringAsFixed(0)}',
                            isDark,
                          ),
                          const SizedBox(height: 6),
                          _buildSummaryRow(
                            'Platform Fee',
                            '₹${platformFee.toStringAsFixed(0)}',
                            isDark,
                          ),
                          if (appliedCoupon != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Coupon (${appliedCoupon.code})',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        ref
                                            .read(
                                              appliedCouponProvider.notifier,
                                            )
                                            .removeCoupon();
                                        _couponController.clear();
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '-₹${appliedCoupon.calculateDiscount(subtotal).toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (appliedCoupon == null && userId != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.03,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: TextField(
                                      controller: _couponController,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Enter coupon code',
                                        hintStyle: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: isDark
                                              ? AppColors.darkTextSecond
                                              : AppColors.lightTextSecond,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () async {
                                    if (_couponController.text.trim().isEmpty) {
                                      return;
                                    }
                                    try {
                                      await ref
                                          .read(appliedCouponProvider.notifier)
                                          .applyCoupon(
                                            _couponController.text.trim(),
                                          );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.toString().replaceAll(
                                                'Exception: ',
                                                '',
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF7C3AED),
                                          Color(0xFFA855F7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Apply',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 20, thickness: 0.5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              GradientText(
                                '₹${(total - (appliedCoupon?.calculateDiscount(subtotal) ?? 0)).toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GradientButton(
                            label: 'Proceed to Checkout',
                            onTap: () {
                              if (userId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please login to purchase items',
                                    ),
                                  ),
                                );
                                context.push('/login');
                              } else {
                                context.push('/buyer/checkout');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextSecond
                : AppColors.lightTextSecond,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.lightTextPrimary,
          ),
        ),
      ],
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
}
