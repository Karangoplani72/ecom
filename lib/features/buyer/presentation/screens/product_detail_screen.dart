import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/widgets/app_network_image.dart';
import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/core/widgets/app_scaffold.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/marketplace/data/dtos/catalog_item_dto.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/marketplace/presentation/controllers/communication_controller.dart';
import 'package:ecom/features/seller/domain/entities/seller_product.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_side_drawer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'product_detail_screen.g.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

@riverpod
Stream<CatalogItem?> catalogItemStream(Ref ref, String productId) {
  return ref
      .watch(firebaseFirestoreProvider)
      .collection('catalog')
      .doc(productId)
      .snapshots()
      .map((snap) => snap.exists ? CatalogItemDto.fromFirestore(snap) : null);
}

@riverpod
FutureOr<bool> wishlistStatus(Ref ref, String productId) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return false;
  final doc = await ref
      .watch(firebaseFirestoreProvider)
      .collection('users')
      .doc(uid)
      .collection('wishlist')
      .doc(productId)
      .get();
  return doc.exists;
}

@riverpod
Stream<List<Map<String, dynamic>>> productReviews(Ref ref, String productId) {
  return ref
      .watch(firebaseFirestoreProvider)
      .collection('reviews')
      .where('productId', isEqualTo: productId)
      .orderBy('createdAt', descending: true)
      .limit(3)
      .snapshots()
      .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Widget _buildGlassIcon(IconData icon, bool isDark) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.15),
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: isDark ? Colors.white : AppColors.lightTextPrimary,
      ),
    );
  }

  final PageController _pageController = PageController();
  int _currentPage = 0;
  Map<String, String> _selectedCombination = {};
  int _quantity = 1;
  bool _addingToCart = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initDefaults(CatalogItem item) {
    if (_selectedCombination.isEmpty && item.hasVariants) {
      final combo = <String, String>{};
      for (final attr in item.variantAttributes) {
        if (attr.options.isNotEmpty) {
          combo[attr.name] = attr.options.first.value;
        }
      }
      if (mounted) setState(() => _selectedCombination = combo);
    }
  }

  VariantSku? _currentSku(CatalogItem item) =>
      item.hasVariants ? item.selectedSku(_selectedCombination) : null;

  int _availableStock(CatalogItem item) {
    final sku = _currentSku(item);
    if (sku != null) return sku.stock;
    return item.totalStock;
  }

  double _unitPrice(CatalogItem item) =>
      item.effectivePrice(_selectedCombination);

  bool _isOutOfStock(CatalogItem item) => _availableStock(item) <= 0;

  /// Name of the color/colour-style attribute for this product, if any.
  String? _colorAttrName(CatalogItem item) {
    for (final attr in item.variantAttributes) {
      final n = attr.name.toLowerCase();
      if (n.contains('color') ||
          n.contains('colour') ||
          attr.options.any((o) => o.colorHex != null)) {
        return attr.name;
      }
    }
    return null;
  }

  /// Color swatches to show below the product image.
  List<VariantOption> _colorOptions(CatalogItem item) {
    if (!item.hasVariants) return const [];
    final name = _colorAttrName(item);
    if (name == null) return const [];
    final attr = item.variantAttributes.firstWhere((a) => a.name == name);
    return attr.options.where((o) => o.colorHex != null).toList();
  }

  Color _parseColorHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    final h = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Future<void> _addToCart(CatalogItem item, {bool buyNow = false}) async {
    if (_isOutOfStock(item)) return;

    setState(() => _addingToCart = true);
    try {
      final sku = _currentSku(item);
      // Use a deterministic id so repeated adds merge quantity instead of
      // creating duplicate cart lines:
      //   • variant product  → "<productId>__<skuId>"
      //   • simple product   → "<productId>"
      final cartId = sku != null ? '${item.id}__${sku.skuId}' : item.id;

      final cartItem = CartItem(
        id: cartId,
        productId: item.id,
        title: item.title,
        storeId: item.storeId,
        storeName: item.metadata['storeName'] as String? ?? 'Seller Store',
        unitPrice: _unitPrice(item),
        imageUrl: item.coverImageForCombination(_selectedCombination).isNotEmpty
            ? item.coverImageForCombination(_selectedCombination)
            : item.coverImage,
        quantity: _quantity,
        skuId: sku?.skuId,
        selectedCombination: _selectedCombination.isNotEmpty
            ? Map<String, String>.from(_selectedCombination)
            : null,
      );

      // Routes through CartController which handles both signed-in (Firestore)
      // and guest (local state) carts automatically.
      await ref.read(cartControllerProvider.notifier).addItem(cartItem);

      if (!mounted) return;
      if (buyNow) {
        context.push('/buyer/checkout');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to cart'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  Future<void> _toggleWishlist(CatalogItem item) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    final docRef = ref
        .read(firebaseFirestoreProvider)
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .doc(item.id);
    final snap = await docRef.get();
    if (snap.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'productId': item.id,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
    ref.invalidate(wishlistStatusProvider(item.id));
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(catalogItemStreamProvider(widget.productId));

    return itemAsync.when(
      loading: () =>
          const AppScaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => AppScaffold(body: Center(child: Text('Error: $e'))),
      data: (item) {
        if (item == null) {
          return const AppScaffold(
            body: Center(child: Text('Product not found')),
          );
        }
        _initDefaults(item);
        return _buildPage(context, item);
      },
    );
  }

  Widget _buildPage(BuildContext context, CatalogItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wishlistAsync = ref.watch(wishlistStatusProvider(item.id));

    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark ? AppColors.darkBgSurface : AppColors.lightBgSurface;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecond = isDark
        ? AppColors.darkTextSecond
        : AppColors.lightTextSecond;
    final accent = isDark
        ? AppColors.darkAccentPurple
        : AppColors.lightAccentPurple;

    return Scaffold(
      backgroundColor: bgColor,
      drawer: const BuyerSideDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: surface,
            leading: Builder(
              builder: (context) => IconButton(
                icon: _buildGlassIcon(Icons.menu_rounded, isDark),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share_outlined, color: textPrimary),
                onPressed: () => _share(item),
              ),
              wishlistAsync.when(
                data: (isWishlisted) => IconButton(
                  icon: Icon(
                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                    color: isWishlisted ? AppColors.error : textPrimary,
                  ),
                  onPressed: () => _toggleWishlist(item),
                ),
                loading: () => const SizedBox(width: 48),
                error: (_, _) => const SizedBox(width: 48),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ImageGallery(
                images: item.imagesForCombination(_selectedCombination),
                controller: _pageController,
                currentPage: _currentPage,
                onPageChanged: (p) => setState(() => _currentPage = p),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_colorOptions(item).isNotEmpty) ...[
                      SizedBox(
                        height: 28,
                        child: Row(
                          children: _colorOptions(item).map((opt) {
                            final isSelected =
                                _colorAttrName(item) != null &&
                                _selectedCombination[_colorAttrName(item)!] ==
                                    opt.value;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Tooltip(
                                message: opt.value,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _parseColorHex(opt.colorHex),
                                    border: Border.all(
                                      color: isSelected
                                          ? accent
                                          : (isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.25,
                                                  )
                                                : Colors.black.withValues(
                                                    alpha: 0.15,
                                                  )),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      item.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.category.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textSecond,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _PriceRow(
                      item: item,
                      combination: _selectedCombination,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    if (item.reviewCount > 0)
                      _RatingRow(
                        item: item,
                        textSecond: textSecond,
                        accent: accent,
                      ),
                    const SizedBox(height: 20),
                    if (item.hasVariants) ...[
                      _VariantSection(
                        item: item,
                        selected: _selectedCombination,
                        onChanged: (combo) => setState(() {
                          _selectedCombination = combo;
                          _quantity = 1;
                          _currentPage = 0;
                          if (_pageController.hasClients) {
                            _pageController.jumpToPage(0);
                          }
                        }),
                        isDark: isDark,
                        accent: accent,
                        textPrimary: textPrimary,
                        textSecond: textSecond,
                      ),
                      const SizedBox(height: 20),
                    ],
                    _StockIndicator(
                      stock: _availableStock(item),
                      hasVariants: item.hasVariants,
                      combination: _selectedCombination,
                    ),
                    const SizedBox(height: 20),
                    if (!_isOutOfStock(item)) ...[
                      _QuantitySelector(
                        quantity: _quantity,
                        max: _availableStock(item),
                        onChanged: (q) => setState(() => _quantity = q),
                        isDark: isDark,
                        accent: accent,
                        textPrimary: textPrimary,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (item.description.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textSecond,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _StoreRow(
                      storeId: item.storeId,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecond: textSecond,
                      surface: surface,
                      accent: accent,
                    ),
                    const SizedBox(height: 24),
                    _ReviewsSection(
                      productId: item.id,
                      avgRating: item.avgRating,
                      reviewCount: item.reviewCount,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecond: textSecond,
                      surface: surface,
                      accent: accent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _BottomBar(
        item: item,
        isOutOfStock: _isOutOfStock(item),
        isLoading: _addingToCart,
        onAddToCart: () => _addToCart(item),
        onBuyNow: () => _addToCart(item, buyNow: true),
        onChatSeller: () => _startSellerChat(item),
        surface: surface,
        isDark: isDark,
      ),
    );
  }

  Future<void> _startSellerChat(CatalogItem item) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to chat with the seller')),
      );
      return;
    }
    // Buyer's display name (best effort)
    final profileAsync = ref.read(currentUserProfileProvider);
    final buyerName = profileAsync.value?.displayName ?? 'Buyer';
    final buyerPhoto = profileAsync.value?.photoUrl;

    final sellerId = item.storeId;
    final sellerName =
        item.metadata['storeName'] as String? ?? 'Seller Store';

    final chatId = await ref
        .read(communicationControllerProvider.notifier)
        .createOrGetRoom(
          buyerId: currentUserId,
          sellerId: sellerId,
          buyerName: buyerName,
          sellerName: sellerName,
          buyerPhotoUrl: buyerPhoto,
        );

    if (!mounted) return;
    if (chatId != null) {
      context.push('/chat/$chatId');
    }
  }

  void _share(CatalogItem item) {
    Clipboard.setData(ClipboardData(text: 'Check out ${item.title}!'));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }
}

// ─── Image Gallery ───────────────────────────────────────────────────────────

class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _ImageGallery({
    required this.images,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image_not_supported, size: 64)),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: controller,
          itemCount: images.length,
          onPageChanged: onPageChanged,
          itemBuilder: (_, i) =>
              AppNetworkImage(imageUrl: images[i], fit: BoxFit.cover),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == currentPage ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == currentPage
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Price Row ───────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final CatalogItem item;
  final Map<String, String> combination;
  final bool isDark;

  const _PriceRow({
    required this.item,
    required this.combination,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePrice = item.effectivePrice(combination);
    final accent = isDark
        ? AppColors.darkAccentPurple
        : AppColors.lightAccentPurple;
    final textSecond = isDark
        ? AppColors.darkTextSecond
        : AppColors.lightTextSecond;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '₹${effectivePrice.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (item.hasDiscount) ...[
          const SizedBox(width: 10),
          Text(
            '₹${item.compareAtPrice!.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textSecond,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.discountPercent}% off',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Rating Row ──────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final CatalogItem item;
  final Color textSecond;
  final Color accent;

  const _RatingRow({
    required this.item,
    required this.textSecond,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
        const SizedBox(width: 4),
        Text(
          item.avgRating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${item.reviewCount} reviews)',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: textSecond),
        ),
      ],
    );
  }
}

// ─── Variant Section ─────────────────────────────────────────────────────────

class _VariantSection extends StatelessWidget {
  final CatalogItem item;
  final Map<String, String> selected;
  final ValueChanged<Map<String, String>> onChanged;
  final bool isDark;
  final Color accent;
  final Color textPrimary;
  final Color textSecond;

  const _VariantSection({
    required this.item,
    required this.selected,
    required this.onChanged,
    required this.isDark,
    required this.accent,
    required this.textPrimary,
    required this.textSecond,
  });

  bool _isColorAttr(VariantAttribute attr) {
    final n = attr.name.toLowerCase();
    if (n.contains('color') || n.contains('colour')) return true;
    return attr.options.any((o) => o.colorHex != null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: item.variantAttributes.map((attr) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    attr.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selected[attr.name] ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attr.options.map((opt) {
                  final isSelected = selected[attr.name] == opt.value;
                  if (_isColorAttr(attr)) {
                    return _ColorChip(
                      option: opt,
                      isSelected: isSelected,
                      onTap: () {
                        final c = Map<String, String>.from(selected);
                        c[attr.name] = opt.value;
                        onChanged(c);
                      },
                      accent: accent,
                    );
                  }
                  return _TextChip(
                    label: opt.value,
                    isSelected: isSelected,
                    onTap: () {
                      final c = Map<String, String>.from(selected);
                      c[attr.name] = opt.value;
                      onChanged(c);
                    },
                    isDark: isDark,
                    accent: accent,
                    textPrimary: textPrimary,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final VariantOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accent;

  const _ColorChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.accent,
  });

  Color _parseHex(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = option.colorHex != null
        ? _parseHex(option.colorHex!)
        : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: option.value,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: chipColor,
            border: Border.all(
              color: isSelected ? accent : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: chipColor.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 18,
                  color: chipColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

class _TextChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color accent;
  final Color textPrimary;

  const _TextChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.accent,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accent
              : isDark
              ? AppColors.darkBgSurface
              : AppColors.lightBgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? accent
                : isDark
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.white : textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Stock Indicator ─────────────────────────────────────────────────────────

class _StockIndicator extends StatelessWidget {
  final int stock;
  final bool hasVariants;
  final Map<String, String> combination;

  const _StockIndicator({
    required this.stock,
    required this.hasVariants,
    required this.combination,
  });

  @override
  Widget build(BuildContext context) {
    if (stock <= 0) {
      final label = hasVariants && combination.isNotEmpty
          ? 'Out of Stock for this variant'
          : 'Out of Stock';
      return _badge(
        context,
        Icons.block,
        label,
        AppColors.error,
        AppColors.error.withValues(alpha: 0.1),
        AppColors.error.withValues(alpha: 0.3),
      );
    }
    if (stock <= 10) {
      return _badge(
        context,
        Icons.warning_amber_rounded,
        'Only $stock left!',
        AppColors.warning,
        AppColors.warning.withValues(alpha: 0.1),
        AppColors.warning.withValues(alpha: 0.3),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppColors.success,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          'In Stock',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _badge(
    BuildContext context,
    IconData icon,
    String label,
    Color fg,
    Color bg,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quantity Selector ───────────────────────────────────────────────────────

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final int max;
  final ValueChanged<int> onChanged;
  final bool isDark;
  final Color accent;
  final Color textPrimary;

  const _QuantitySelector({
    required this.quantity,
    required this.max,
    required this.onChanged,
    required this.isDark,
    required this.accent,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Quantity',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _QtyBtn(
                icon: Icons.remove,
                enabled: quantity > 1,
                onTap: () => onChanged(quantity - 1),
                accent: accent,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$quantity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _QtyBtn(
                icon: Icons.add,
                enabled: quantity < max,
                onTap: () => onChanged(quantity + 1),
                accent: accent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final Color accent;

  const _QtyBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? accent : Colors.grey.shade400,
        ),
      ),
    );
  }
}

// ─── Store Row ───────────────────────────────────────────────────────────────

class _StoreRow extends ConsumerWidget {
  final String storeId;
  final bool isDark;
  final Color textPrimary;
  final Color textSecond;
  final Color surface;
  final Color accent;

  const _StoreRow({
    required this.storeId,
    required this.isDark,
    required this.textPrimary,
    required this.textSecond,
    required this.surface,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeNameAsync = ref.watch(storeNameProvider(storeId));

    return GestureDetector(
      onTap: () => context.push('/store/$storeId'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront_outlined, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sold by',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: textSecond),
                  ),
                  storeNameAsync.when(
                    data: (name) => Text(
                      name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 14,
                      width: 80,
                      child: LinearProgressIndicator(),
                    ),
                    error: (_, _) => const Text('Unknown Store'),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textSecond),
          ],
        ),
      ),
    );
  }
}

// ─── Reviews Section ─────────────────────────────────────────────────────────

class _ReviewsSection extends ConsumerWidget {
  final String productId;
  final double avgRating;
  final int reviewCount;
  final bool isDark;
  final Color textPrimary;
  final Color textSecond;
  final Color surface;
  final Color accent;

  const _ReviewsSection({
    required this.productId,
    required this.avgRating,
    required this.reviewCount,
    required this.isDark,
    required this.textPrimary,
    required this.textSecond,
    required this.surface,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(productId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Reviews',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (reviewCount > 0)
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${avgRating.toStringAsFixed(1)} · $reviewCount',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: textSecond),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        reviewsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            'Could not load reviews',
            style: TextStyle(color: textSecond),
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No reviews yet. Be the first!',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: textSecond),
                ),
              );
            }
            return Column(
              children: reviews
                  .map(
                    (r) => _ReviewCard(
                      review: r,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecond: textSecond,
                      surface: surface,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final bool isDark;
  final Color textPrimary;
  final Color textSecond;
  final Color surface;

  const _ReviewCard({
    required this.review,
    required this.isDark,
    required this.textPrimary,
    required this.textSecond,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final author = review['userName'] as String? ?? 'Anonymous';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                author,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.warning,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: textSecond, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Bottom Bar ──────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final CatalogItem item;
  final bool isOutOfStock;
  final bool isLoading;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final VoidCallback onChatSeller;
  final Color surface;
  final bool isDark;

  const _BottomBar({
    required this.item,
    required this.isOutOfStock,
    required this.isLoading,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.onChatSeller,
    required this.surface,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Chat with Seller ─────────────────────────────────────────────
          Tooltip(
            message: 'Chat with Seller',
            child: InkWell(
              onTap: onChatSeller,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: isOutOfStock || isLoading ? null : onAddToCart,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: isOutOfStock
                      ? Colors.grey.shade400
                      : AppColors.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isOutOfStock ? 'Out of Stock' : 'Add to Cart'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppPrimaryButton(
              text: 'Buy Now',
              onPressed: isOutOfStock ? null : onBuyNow,
            ),
          ),
        ],
      ),
    );
  }
}
