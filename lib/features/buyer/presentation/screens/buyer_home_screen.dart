import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecom/features/marketplace/presentation/controllers/marketplace_controller.dart';
import 'package:ecom/core/theme/app_theme.dart';

class BuyerHomeScreen extends ConsumerWidget {
  const BuyerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the global catalog stream we built in Section 2
    final catalogState = ref.watch(marketplaceControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => context.push('/buyer/cart'),
          ),
        ],
      ),
      body: catalogState.when(
        // 1. Loading State
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.blushPink),
        ),

        // 2. Error State
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.errorCoral, size: 48),
              const SizedBox(height: 16),
              Text(error.toString(), textAlign: TextAlign.center),
              TextButton(
                onPressed: () => ref.invalidate(marketplaceControllerProvider),
                child: const Text('Retry'),
              )
            ],
          ),
        ),

        // 3. Success Data State
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No products or services available right now.'));
          }

          return RefreshIndicator(
            color: AppTheme.blushPink,
            onRefresh: () async => ref.invalidate(marketplaceControllerProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75, // Taller cards for images
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/buyer/home/product/${item.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Placeholder
                        Expanded(
                          child: Container(
                            color: AppTheme.champagneGold.withValues(alpha: 0.3),
                            width: double.infinity,
                            child: item.imageUrls.isNotEmpty
                                ? Image.network(item.imageUrls.first, fit: BoxFit.cover)
                                : const Icon(Icons.image, color: AppTheme.roseGold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.currency} ${item.basePrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppTheme.blushPink,
                                  fontWeight: FontWeight.bold,
                                ),
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
          );
        },
      ),
    );
  }
}