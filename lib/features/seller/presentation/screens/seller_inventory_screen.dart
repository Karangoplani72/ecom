import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/providers/common_providers.dart';

import '../controllers/seller_inventory_controller.dart';

class SellerInventoryScreen extends ConsumerWidget {
  const SellerInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(sellerProductsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Inventory Management'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/seller/inventory/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add New Product'),
        elevation: 4,
      ),
      body: productsAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(message: error.toString()),
        data: (products) {
          if (products.isEmpty) {
            return const AppEmptyView(
              title: 'Empty Inventory',
              subtitle: 'Start adding products to reach millions of customers.',
              icon: Icons.inventory_2_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final product = products[index];
              final stock = product.stock;
              final isLowStock = stock <= 5;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: product.imageUrls.isNotEmpty
                          ? Image.network(
                              product.imageUrls.first,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.inventory_2_outlined),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${product.basePrice}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isLowStock
                                      ? colorScheme.errorContainer.withValues(
                                          alpha: 0.5,
                                        )
                                      : colorScheme.primaryContainer.withValues(
                                          alpha: 0.3,
                                        ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Stock: $stock',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isLowStock
                                        ? colorScheme.error
                                        : colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                product.status.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          if (product.metadata['isFlashDeal'] == true &&
                              product.metadata['flashSaleStatus'] == 'pending') ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.bolt,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '⚡ Campaign Offer Pending Approval',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Discount: ${(((product.metadata['flashSaleDiscountPercent'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(0)}% OFF'
                                    '\nFunded by: ${product.metadata['flashSaleSponsor'] == 'seller' ? 'Seller' : 'Platform/Admin'}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () async {
                                          final firestore = ref.read(firebaseFirestoreProvider);
                                          await firestore.collection('catalog').doc(product.id).update({
                                            'metadata.isFlashDeal': false,
                                            'metadata.flashSaleStartsAt': FieldValue.delete(),
                                            'metadata.flashSaleEndsAt': FieldValue.delete(),
                                            'metadata.flashSaleDiscountPercent': FieldValue.delete(),
                                            'metadata.flashSaleSponsor': FieldValue.delete(),
                                            'metadata.flashSaleStatus': FieldValue.delete(),
                                            'updatedAt': FieldValue.serverTimestamp(),
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Campaign offer declined.')),
                                            );
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: colorScheme.error,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: const Text('Decline'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final firestore = ref.read(firebaseFirestoreProvider);
                                          await firestore.collection('catalog').doc(product.id).update({
                                            'metadata.flashSaleStatus': 'active',
                                            'updatedAt': FieldValue.serverTimestamp(),
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Campaign offer accepted! Discount is now scheduled.')),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Accept'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: colorScheme.primary,
                          ),
                          onPressed: () => context.push(
                            '/seller/inventory/edit/${product.id}',
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: colorScheme.error,
                          ),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Product?'),
                                content: const Text(
                                  'This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              ref
                                  .read(
                                    sellerInventoryControllerProvider.notifier,
                                  )
                                  .deleteProduct(productId: product.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
