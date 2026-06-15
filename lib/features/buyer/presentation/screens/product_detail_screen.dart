import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecom/core/theme/app_theme.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedQuantity = 1;

  final Map<String, dynamic> _mockProductDetails = {
    'id': 'p1',
    'title': 'Luxury Gel Polish Set (6 Colors)',
    'description': 'High-pigment, long-lasting gel polish set. Includes base coat, matte top coat, and 4 seasonal shades. Cures under UV/LED lamp in 60 seconds. Chip-resistant formula lasts up to 21 days.',
    'basePrice': 1299.0,
    'storeId': 's1',
    'storeName': "Nail Aesthetics Co.",
    'rating': 4.8,
    'reviewsCount': 342,
    'imageUrls': ['https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=600'],
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
      final existingItem = existingCart.firstWhere((item) => item.productId == widget.productId);
      ref.read(cartControllerProvider.notifier).updateQuantity(existingItem.id, _selectedQuantity);
    } else {
      ref.read(cartControllerProvider).add(cartItem);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to cart!'),
        backgroundColor: AppTheme.roseGold,
        action: SnackBarAction(label: 'View Cart', textColor: AppTheme.surfaceWhite, onPressed: () => context.push('/buyer/cart')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _mockProductDetails;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: AppTheme.creamBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(product['imageUrls'][0] as String, fit: BoxFit.cover),
            ),
            leading: CircleAvatar(
              backgroundColor: AppTheme.surfaceWhite.withValues(alpha: 0.9),
              child: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.charcoalText), onPressed: () => context.pop()),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.creamBackground,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront, color: AppTheme.roseGold, size: 18),
                      const SizedBox(width: 6),
                      Text(product['storeName'] as String, style: const TextStyle(color: AppTheme.slateGreyText, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(product['title'] as String, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.charcoalText)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${(product['basePrice'] as double).toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.roseGold)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text('${product['rating']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoalText)),
                          Text(' (${product['reviewsCount']} reviews)', style: const TextStyle(color: AppTheme.slateGreyText)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32, color: AppTheme.champagneGold),
                  Text('Product Description', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(product['description'] as String, style: const TextStyle(color: AppTheme.slateGreyText, height: 1.6, fontSize: 15)),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(color: AppTheme.surfaceWhite, boxShadow: [BoxShadow(color: AppTheme.charcoalText.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, -4))]),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(border: Border.all(color: AppTheme.champagneGold), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: _selectedQuantity > 1 ? () => setState(() => _selectedQuantity--) : null),
                    Text('$_selectedQuantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => setState(() => _selectedQuantity++)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(height: 56, child: ElevatedButton(onPressed: _handleAddToCart, child: const Text('Add to Cart'))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}