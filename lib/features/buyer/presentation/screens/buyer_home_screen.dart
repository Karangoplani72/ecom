import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_product_card.dart';
import 'package:ecom/features/marketplace/presentation/controllers/marketplace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BuyerHomeScreen extends ConsumerWidget {
  const BuyerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(marketplaceControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              context.push('/buyer/wishlist');
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              context.push('/buyer/cart');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      context.push('/seller/dashboard');
                    },
                    icon: const Icon(Icons.storefront),
                    label: const Text('Seller'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      context.push('/admin/control-panel');
                    },
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Admin'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: catalogState.when(
        loading: () => const AppLoadingView(),

        error: (error, stack) => AppErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(marketplaceControllerProvider);
          },
        ),

        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyView(
              title: 'No Products Available',
              subtitle:
                  'New products will appear here when sellers publish them.',
              icon: Icons.inventory_2_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(marketplaceControllerProvider);
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),

              itemCount: items.length,

              itemBuilder: (context, index) {
                final item = items[index];

                return AppProductCard(
                  title: item.title,
                  imageUrl: item.imageUrls.isNotEmpty
                      ? item.imageUrls.first
                      : '',
                  rating: 4.5,
                  price: item.basePrice,
                  onTap: () {
                    context.push('/buyer/home/product/${item.id}');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
