import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_product_card.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/features/buyer/presentation/controllers/wishlist_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistStreamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Wishlist'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/buyer/cart'),
          ),
        ],
      ),
      body: wishlistAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(wishlistStreamProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyView(
              title: 'Your Wishlist is Empty',
              subtitle:
                  'Save your favorite items here to find them easily later.',
              icon: Icons.favorite_border,
              action: FilledButton(
                onPressed: () => context.go('/buyer/products'),
                child: const Text('Browse Products'),
              ),
            );
          }

          return ResponsiveLayout(
            maxWidth: 1200,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: width > 1200
                    ? 5
                    : width > 900
                    ? 4
                    : width > 600
                    ? 3
                    : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Stack(
                  children: [
                    AppProductCard(
                      title: item.title,
                      imageUrl: item.imageUrls.isNotEmpty
                          ? item.imageUrls.first
                          : '',
                      rating: 4.8,
                      price: item.basePrice,
                      onTap: () =>
                          context.push('/buyer/home/product/${item.id}'),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          ref
                              .read(wishlistControllerProvider.notifier)
                              .removeFromWishlist(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Removed from wishlist'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
