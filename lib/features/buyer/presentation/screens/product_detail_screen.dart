import 'dart:ui';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/wishlist_controller.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/marketplace/presentation/controllers/marketplace_controller.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/theme/app_shadows.dart';
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
  int _selectedImageIndex = 0;
  bool _isAddingToCart = false;
  bool _isInWishlist = false;
  bool _wishlistChecked = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
  }

  Future<void> _checkWishlist() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final result = await ref
        .read(wishlistControllerProvider.notifier)
        .isInWishlist(widget.productId);
    if (mounted) {
      setState(() {
        _isInWishlist = result;
        _wishlistChecked = true;
      });
    }
  }

  Future<void> _toggleWishlist(CatalogItem product) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save items')),
      );
      return;
    }

    setState(() => _isInWishlist = !_isInWishlist);

    if (_isInWishlist) {
      await ref
          .read(wishlistControllerProvider.notifier)
          .addToWishlist(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to wishlist'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => context.push('/buyer/wishlist'),
            ),
          ),
        );
      }
    } else {
      await ref
          .read(wishlistControllerProvider.notifier)
          .removeFromWishlist(product.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: const Text('Removed from wishlist'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
        );
      }
    }
  }

  Future<void> _handleAddToCart(CatalogItem product) async {
    setState(() => _isAddingToCart = true);

    try {
      final cartItem = CartItem(
        id: product.id,
        productId: product.id,
        title: product.title,
        storeId: product.storeId,
        storeName: product.metadata['storeName'] as String? ?? 'Official Store',
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.share_outlined, color: isDark ? Colors.white : Colors.black),
                onPressed: () {},
              ),
            ),
          ),
          productAsync.when(
            data: (product) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isInWishlist ? Icons.favorite : Icons.favorite_border,
                    color: _isInWishlist ? AppColors.error : (isDark ? Colors.white : Colors.black),
                  ),
                  onPressed: _wishlistChecked
                      ? () => _toggleWishlist(product)
                      : null,
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: productAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, stack) => AppErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(productDetailProvider(widget.productId)),
        ),
        data: (product) {
          return ResponsiveLayout(
            maxWidth: 1200,
            child: isDesktop
                ? _buildDesktopLayout(product, theme, isDark)
                : _buildMobileLayout(product, theme, isDark),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(CatalogItem product, ThemeData theme, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: _buildImageGallery(product, isDark),
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: _buildProductInfo(
              product,
              theme,
              isDark,
              isDesktop: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(CatalogItem product, ThemeData theme, bool isDark) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildImageGallery(product, isDark),
            ),
            SliverToBoxAdapter(
              child: Container(
                transform: Matrix4.translationValues(0.0, -32.0, 0.0),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: _buildProductInfo(product, theme, isDark),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ),
        _buildStickyBottomBar(product, theme, isDark),
      ],
    );
  }

  Widget _buildImageGallery(CatalogItem product, bool isDark) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 0.9,
          child: product.imageUrls.isNotEmpty
              ? PageView.builder(
                  itemCount: product.imageUrls.length,
                  onPageChanged: (index) =>
                      setState(() => _selectedImageIndex = index),
                  itemBuilder: (context, index) => Hero(
                    tag: 'product-${product.id}',
                    child: Image.network(
                      product.imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                        child: Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                  child: Icon(
                    Icons.image,
                    size: 48,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
        ),
        if (product.imageUrls.length > 1)
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
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
                        ? (isDark ? AppColors.primaryLight : AppColors.primary)
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      if (_selectedImageIndex == index)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo(
    CatalogItem product,
    ThemeData theme,
    bool isDark, {
    bool isDesktop = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.3)),
              ),
              child: Text(
                product.type.name.toUpperCase(),
                style: TextStyle(
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ),
            _buildRatingBadge(theme, isDark),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          product.title,
          style: TextStyle(
            fontSize: isDesktop ? 40 : 28,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.5,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '₹${product.basePrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        _buildStoreInfo(product, theme, isDark),
        const SizedBox(height: 32),
        Text(
          'Description',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          product.description,
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 32),
        _buildQuantitySelector(theme, isDark),
        const SizedBox(height: 32),
        if (isDesktop)
          _buildDesktopActions(product, theme, isDark)
        else
          _buildFeaturesGrid(isDark),
      ],
    );
  }

  Widget _buildRatingBadge(ThemeData theme, bool isDark) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: AppColors.warning, size: 24),
        const SizedBox(width: 6),
        Text(
          '4.9',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '(120 reviews)',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStoreInfo(
    CatalogItem product,
    ThemeData theme,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => context.push(
        '/chat/${product.storeId}-${ref.read(currentUserIdProvider) ?? ''}',
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          boxShadow: isDark ? AppShadows.darkSm : AppShadows.lightSm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront, size: 24, color: isDark ? AppColors.primaryLight : AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        product.metadata['storeName'] as String? ?? 'Premium Seller',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, size: 16, color: AppColors.info),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Official Brand Store',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chat_bubble_outline, size: 24, color: isDark ? AppColors.primaryLight : AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Text(
          'Quantity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            boxShadow: isDark ? AppShadows.darkSm : AppShadows.lightSm,
          ),
          child: Row(
            children: [
              _buildQtyBtn(Icons.remove, isDark, () {
                if (_selectedQuantity > 1) {
                  setState(() => _selectedQuantity--);
                }
              }),
              SizedBox(
                width: 48,
                child: Text(
                  '$_selectedQuantity',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              _buildQtyBtn(
                Icons.add,
                isDark,
                () => setState(() => _selectedQuantity++),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQtyBtn(IconData icon, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      ),
    );
  }

  Widget _buildDesktopActions(
    CatalogItem product,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      children: [
        const Divider(height: 64),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Price',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  '₹${(product.basePrice * _selectedQuantity).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 48),
            Expanded(
              child: AppPrimaryButton(
                text: 'Add to Cart',
                icon: Icons.shopping_cart_outlined,
                isLoading: _isAddingToCart,
                onPressed: () => _handleAddToCart(product),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar(
    CatalogItem product,
    ThemeData theme,
    bool isDark,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
              border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${(product.basePrice * _selectedQuantity).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: AppPrimaryButton(
                      text: 'Add to Cart',
                      icon: Icons.shopping_cart_outlined,
                      isLoading: _isAddingToCart,
                      onPressed: () => _handleAddToCart(product),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildFeatureItem(
          Icons.local_shipping_outlined,
          'Free Premium Delivery',
          'Orders above ₹999 get free shipping',
          isDark,
        ),
        _buildFeatureItem(
          Icons.verified_user_outlined,
          'Authenticity Guarantee',
          '100% genuine products sourced directly',
          isDark,
        ),
        _buildFeatureItem(
          Icons.assignment_return_outlined,
          '7 Days Easy Return',
          'Hassle-free return policy for premium members',
          isDark,
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String sub,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: isDark ? AppColors.primaryLight : AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
