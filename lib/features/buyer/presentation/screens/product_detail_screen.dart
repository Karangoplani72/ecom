import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedQuantity = 1;

  final Map<String, dynamic> _mockProductDetails = {
    'id': 'p1',
    'title': 'Professional Gel Polish Set',
    'description':
        'Premium quality gel polish collection designed for professional and personal use. Long-lasting finish, quick curing formula, and salon-grade quality.',
    'basePrice': 1299.0,
    'storeId': 's1',
    'storeName': 'Beauty Essentials',
    'rating': 4.8,
    'reviewsCount': 342,
    'imageUrls': [
      'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=600',
    ],
  };

  void _handleAddToCart() {
    final cartItem = CartItem(
      id: 'c_${widget.productId}_${DateTime.now().millisecondsSinceEpoch}',
      productId: widget.productId,
      title: _mockProductDetails['title'] as String,
      storeId: _mockProductDetails['storeId'] as String,
      storeName: _mockProductDetails['storeName'] as String,
      unitPrice: _mockProductDetails['basePrice'] as double,
      imageUrl: (_mockProductDetails['imageUrls'] as List<String>).first,
      quantity: _selectedQuantity,
    );

    final existingCart = ref.read(cartControllerProvider);

    if (existingCart.any((item) => item.productId == widget.productId)) {
      final existingItem = existingCart.firstWhere(
        (item) => item.productId == widget.productId,
      );

      ref
          .read(cartControllerProvider.notifier)
          .setQuantity(existingItem.id, _selectedQuantity);
    } else {
      ref.read(cartControllerProvider.notifier).addItem(cartItem);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Product added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            context.push('/buyer/cart');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _mockProductDetails;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            stretch: true,

            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                product['imageUrls'][0] as String,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storefront,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product['storeName'] as String,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    product['title'] as String,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${(product['basePrice'] as double).toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${product['rating']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${product['reviewsCount']} reviews)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Divider(color: colorScheme.outlineVariant),

                  const SizedBox(height: 24),

                  Text('Description', style: theme.textTheme.titleLarge),

                  const SizedBox(height: 12),

                  Text(
                    product['description'] as String,
                    style: theme.textTheme.bodyLarge,
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _selectedQuantity > 1
                          ? () {
                              setState(() {
                                _selectedQuantity--;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      '$_selectedQuantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedQuantity++;
                        });
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: AppPrimaryButton(
                  text: 'Add To Cart',
                  onPressed: _handleAddToCart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
