import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../marketplace/presentation/controllers/marketplace_controller.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedQuantity = 1;
  int _selectedImageIndex = 0;
  bool _isAddingToCart = false;

  void _handleAddToCart(CatalogItem product) async {
    setState(() => _isAddingToCart = true);

    try {
      final cartItem = CartItem(
        id: product.id,
        productId: product.id,
        title: product.title,
        storeId: product.storeId,
        storeName: product.metadata['storeName'] ?? 'Official Store',
        unitPrice: product.basePrice,
        imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        quantity: _selectedQuantity,
      );

      await ref.read(cartControllerProvider.notifier).addItem(cartItem);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $_selectedQuantity item(s) to cart'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () => context.push('/buyer/cart'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
        ],
      ),
      body: productAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, stack) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        ),
        data: (product) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return ResponsiveLayout(
            maxWidth: 1200,
            child: isDesktop 
              ? _buildDesktopLayout(product, theme, colorScheme)
              : _buildMobileLayout(product, theme, colorScheme),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(CatalogItem product, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Side: Image Gallery
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: _buildImageGallery(product, colorScheme),
          ),
        ),
        const SizedBox(width: 48),
        // Right Side: Product Info
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: _buildProductInfo(product, theme, colorScheme, isDesktop: true),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(CatalogItem product, ThemeData theme, ColorScheme colorScheme) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: _buildImageGallery(product, colorScheme),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildProductInfo(product, theme, colorScheme),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        _buildStickyBottomBar(product, theme, colorScheme),
      ],
    );
  }

  Widget _buildImageGallery(CatalogItem product, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: product.imageUrls.isNotEmpty
                  ? PageView.builder(
                      itemCount: product.imageUrls.length,
                      onPageChanged: (index) => setState(() => _selectedImageIndex = index),
                      itemBuilder: (context, index) => Hero(
                        tag: 'product-${product.id}',
                        child: Image.network(product.imageUrls[index], fit: BoxFit.cover),
                      ),
                    )
                  : Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.image, size: 48, color: colorScheme.primary),
                    ),
            ),
          ),
        ),
        if (product.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                product.imageUrls.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _selectedImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _selectedImageIndex == index
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo(CatalogItem product, ThemeData theme, ColorScheme colorScheme, {bool isDesktop = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.type.name.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _buildRatingBadge(theme),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          product.title,
          style: (isDesktop ? theme.textTheme.displaySmall : theme.textTheme.headlineMedium)?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        _buildStoreInfo(product, theme, colorScheme),
        const SizedBox(height: 32),
        Text(
          'Description',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          product.description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        _buildQuantitySelector(theme, colorScheme),
        const SizedBox(height: 32),
        if (isDesktop) _buildDesktopActions(product, theme, colorScheme) else _buildFeaturesGrid(colorScheme),
      ],
    );
  }

  Widget _buildRatingBadge(ThemeData theme) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const SizedBox(width: 4),
        Text(
          '4.9', 
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Text('(120 reviews)', style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildStoreInfo(CatalogItem product, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.storefront, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          product.metadata['storeName'] ?? 'Premium Seller',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Icon(Icons.verified, size: 16, color: Colors.blue),
      ],
    );
  }

  Widget _buildQuantitySelector(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Text('Quantity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 24),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildQtyBtn(Icons.remove, () {
                if (_selectedQuantity > 1) setState(() => _selectedQuantity--);
              }),
              SizedBox(
                width: 40,
                child: Text(
                  '$_selectedQuantity',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _buildQtyBtn(Icons.add, () => setState(() => _selectedQuantity++)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopActions(CatalogItem product, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        const Divider(height: 64),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Price', style: theme.textTheme.labelMedium),
                Text(
                  '₹${(product.basePrice * _selectedQuantity).toStringAsFixed(2)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 48),
            Expanded(
              child: SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isAddingToCart ? null : () => _handleAddToCart(product),
                  icon: _isAddingToCart 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.shopping_cart_outlined),
                  label: Text(_isAddingToCart ? 'Processing...' : 'Add to Shopping Cart'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar(CatalogItem product, ThemeData theme, ColorScheme colorScheme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Price', style: theme.textTheme.labelMedium),
                Text(
                  '₹${(product.basePrice * _selectedQuantity).toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _isAddingToCart ? null : () => _handleAddToCart(product),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(_isAddingToCart ? 'Adding...' : 'Add to Cart'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return IconButton(onPressed: onTap, icon: Icon(icon, size: 20), padding: const EdgeInsets.all(12));
  }

  Widget _buildFeaturesGrid(ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildFeatureItem(Icons.local_shipping_outlined, 'Free Delivery', 'Orders above ₹999', colorScheme),
        _buildFeatureItem(Icons.verified_user_outlined, 'Genuine Product', '100% Quality Assured', colorScheme),
        _buildFeatureItem(Icons.assignment_return_outlined, '7 Days Return', 'Hassle-free process', colorScheme),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String sub, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colorScheme.primaryContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(sub, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
