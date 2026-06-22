import 'dart:ui';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/marketplace/presentation/controllers/marketplace_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/wishlist_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecom/shared/presentation/widgets/cart_icon_with_badge.dart';
import 'package:go_router/go_router.dart';

import 'package:ecom/features/buyer/presentation/widgets/buyer_side_drawer.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedColorIndex = 0;

  final List<Color> _colors = [
    const Color(0xFF8B5CF6),
    const Color(0xFF1F2937),
    const Color(0xFFFDE68A),
    const Color(0xFF3B82F6),
    const Color(0xFFF472B6),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final wishlistAsync = ref.watch(wishlistStreamProvider);

    return productAsync.when(
      loading: () => const Scaffold(body: AppLoadingView()),
      error: (error, _) => Scaffold(body: AppErrorView(message: error.toString())),
      data: (product) {
        final wishlist = wishlistAsync.value ?? <CatalogItem>[];
        final isInWishlist = wishlist.any((item) => item.id == product.id);

        final imageProvider = (product.imageUrls.isNotEmpty && product.imageUrls.first.startsWith('http'))
            ? NetworkImage(product.imageUrls.first) as ImageProvider
            : const AssetImage('assets/images/3d/product_headphones.png');

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary,
          drawer: const BuyerSideDrawer(),
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              const OrbBackgroundWidget(),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    actions: [
                      const CartIconWithBadge(),
                      IconButton(
                        icon: Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          color: isInWishlist
                              ? Colors.red
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                        onPressed: () async {
                          final notifier = ref.read(wishlistControllerProvider.notifier);
                          if (isInWishlist) {
                            await notifier.removeFromWishlist(product.id);
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Removed from wishlist'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            await notifier.addToWishlist(product);
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to wishlist'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.share_outlined, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // 3D Hero Product Presentation
                        Center(
                          child: Column(
                            children: [
                              FloatingProductWidget(
                                floatHeight: 20.0,
                                duration: const Duration(seconds: 4),
                                tiltDegrees: 2.0,
                                child: Container(
                                  width: 260,
                                  height: 260,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const GlowingPedestalWidget(width: 240, height: 60),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Thumbnails
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            return Container(
                              width: 60,
                              height: 60,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: index == 0 
                                    ? Border.all(color: AppColors.primary, width: 2)
                                    : Border.all(color: Colors.transparent),
                                boxShadow: [
                                  if (index == 0)
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.headphones, 
                                  color: index == 0 ? AppColors.primary : Colors.grey,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBgSurface : AppColors.lightBgSurface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, -10),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(128 reviews)',
                                style: TextStyle(color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Text(
                                '₹${product.basePrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '₹${(product.basePrice * 1.6).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '-40%',
                                  style: TextStyle(
                                    color: Color(0xFFEC4899),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            product.description,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Select Color
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Select Color',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              Icon(Icons.chevron_right, color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: List.generate(_colors.length, (index) {
                              final isSelected = index == _selectedColorIndex;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedColorIndex = index),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 16),
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _colors[index],
                                    shape: BoxShape.circle,
                                    border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: _colors[index].withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 32),

                          // Quantity
                          Row(
                            children: [
                              Text(
                                'Quantity',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        if (_quantity > 1) setState(() => _quantity--);
                                      },
                                    ),
                                    Text(
                                      '$_quantity',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () => setState(() => _quantity++),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 120), // padding for bottom bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkBgSurface : AppColors.lightBgSurface).withValues(alpha: 0.8),
                        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              try {
                                final cartItem = CartItem(
                                  id: product.id,
                                  productId: product.id,
                                  title: product.title,
                                  storeId: product.storeId,
                                  storeName: product.metadata['storeName'] as String? ?? 'Seller Store',
                                  unitPrice: product.basePrice,
                                  imageUrl: product.imageUrls.isNotEmpty
                                      ? product.imageUrls.first
                                      : 'assets/images/3d/product_headphones.png',
                                  quantity: _quantity,
                                );

                                await ref.read(cartControllerProvider.notifier).addItem(cartItem);
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Added to cart successfully'),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.all(16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to add to cart: $e'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add to Cart',
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                try {
                                  final cartItem = CartItem(
                                    id: product.id,
                                    productId: product.id,
                                    title: product.title,
                                    storeId: product.storeId,
                                    storeName: product.metadata['storeName'] as String? ?? 'Seller Store',
                                    unitPrice: product.basePrice,
                                    imageUrl: product.imageUrls.isNotEmpty
                                        ? product.imageUrls.first
                                        : 'assets/images/3d/product_headphones.png',
                                    quantity: _quantity,
                                  );

                                  await ref.read(cartControllerProvider.notifier).addItem(cartItem);
                                  
                                  if (mounted) {
                                    GoRouter.of(this.context).push('/buyer/cart');
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to purchase: $e'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'Buy Now',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
