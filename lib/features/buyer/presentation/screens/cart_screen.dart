import 'dart:ui';
import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_price_text.dart';
import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/core/widgets/scaffolds/premium_25d_scaffold.dart';
import 'package:ecom/core/widgets/cards/glass_card.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/theme/app_shadows.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/buyer/presentation/controllers/guest_cart_controller.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_side_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final cartAsync = userId == null 
        ? AsyncValue.data(ref.watch(guestCartControllerProvider)) 
        : ref.watch(cartStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Premium25DScaffold(
      isDark: isDark,
      drawer: const BuyerSideDrawer(),
      particles: [
        FloatingParticle(imagePath: 'assets/images/25d_cart.svg', width: 60, height: 60, dx: -50, dy: 100, delay: 0.1, depth: 1.5),
        FloatingParticle(imagePath: 'assets/images/25d_bag.svg', width: 40, height: 40, dx: 300, dy: 300, delay: 0.5, depth: 0.8),
      ],
      appBar: AppBar(
        title: Text(
          'My Cart',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          cartAsync.when(
            data: (items) => items.isNotEmpty
                ? TextButton(
                    onPressed: () => _showClearCartDialog(context, ref),
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: cartAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(cartStreamProvider),
        ),
        data: (cartItems) {
          if (cartItems.isEmpty) {
            return AppEmptyView(
              title: 'Your cart is empty',
              subtitle: 'Browse our collection and find something you love!',
              icon: Icons.shopping_basket_outlined,
              action: AppPrimaryButton(
                onPressed: () => context.go('/buyer/products'),
                text: 'Browse Products',
                icon: Icons.search,
              ),
            );
          }

          final subtotal = cartItems.fold<double>(
            0,
            (currentSum, item) => currentSum + (item.unitPrice * item.quantity),
          );

          return ResponsiveLayout(
            maxWidth: 800,
            child: Stack(
              children: [
                ListView.separated(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: 140, // Space for bottom bar
                  ),
                  itemCount: cartItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        ref
                            .read(cartControllerProvider.notifier)
                            .removeItem(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.title} removed from cart'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      child: GlassCard(
                        isDark: isDark,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.push(
                                '/buyer/home/product/${item.productId}',
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isDark ? AppShadows.darkSm : AppShadows.lightSm,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    item.imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 100,
                                              height: 100,
                                              color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                                              child: Icon(
                                                Icons.image_outlined,
                                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.storeName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      AppPriceText(amount: item.unitPrice),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _QtyBtn(
                                              icon: item.quantity > 1
                                                  ? Icons.remove
                                                  : Icons.delete_outline,
                                              color: item.quantity > 1
                                                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                                  : AppColors.error,
                                              onTap: () {
                                                if (item.quantity > 1) {
                                                  ref
                                                      .read(
                                                        cartControllerProvider
                                                            .notifier,
                                                      )
                                                      .updateQuantity(
                                                        item.id,
                                                        -1,
                                                      );
                                                } else {
                                                  ref
                                                      .read(
                                                        cartControllerProvider
                                                            .notifier,
                                                      )
                                                      .removeItem(item.id);
                                                }
                                              },
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              child: Text(
                                                '${item.quantity}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                                ),
                                              ),
                                            ),
                                            _QtyBtn(
                                              icon: Icons.add,
                                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                              onTap: () => ref
                                                  .read(
                                                    cartControllerProvider
                                                        .notifier,
                                                  )
                                                  .updateQuantity(item.id, 1),
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
                    );
                  },
                ),

                // Order Summary - Sticky Bottom Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
                          border: Border(
                            top: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${cartItems.length} item(s)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      Text(
                                        'Total',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '₹${subtotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              AppPrimaryButton(
                                text: 'Proceed to Checkout',
                                onPressed: () {
                                  debugPrint('[CHECKOUT] Proceed to Checkout clicked. userId: $userId');
                                  if (userId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please login to purchase items')),
                                    );
                                    context.push('/login');
                                  } else {
                                    context.push('/buyer/checkout');
                                  }
                                },
                                icon: Icons.arrow_forward,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          ),
          FilledButton(
            onPressed: () {
              ref.read(cartControllerProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _QtyBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
