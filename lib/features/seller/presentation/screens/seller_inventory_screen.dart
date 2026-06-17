import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/seller_inventory_controller.dart';

class SellerInventoryScreen extends ConsumerWidget {
  const SellerInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(sellerProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/seller/inventory/add');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (error, stackTrace) => Center(child: Text(error.toString())),

        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products added yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),

            itemBuilder: (context, index) {
              final product = products[index];

              final image = product.imageUrls.isNotEmpty
                  ? product.imageUrls.first
                  : null;

              return Card(
                child: ListTile(
                  leading: image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            image,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.inventory_2),

                  title: Text(product.title),

                  subtitle: Text('₹${product.basePrice}'),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          context.go('/seller/inventory/edit/${product.id}');
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref
                              .read(sellerInventoryControllerProvider.notifier)
                              .deleteProduct(productId: product.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
