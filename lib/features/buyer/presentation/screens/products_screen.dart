import 'dart:ui';

import 'package:ecom/core/providers/categories_provider.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_side_drawer.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/buyer/presentation/controllers/wishlist_controller.dart';
import 'package:ecom/features/marketplace/presentation/controllers/marketplace_controller.dart';
import 'package:ecom/core/utils/price_helper.dart';
import 'package:ecom/shared/presentation/widgets/cart_icon_with_badge.dart';
import 'package:ecom/shared/presentation/widgets/wishlist_icon_with_badge.dart';
import 'package:ecom/shared/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY — loads categories then hands off to stateful content
// ─────────────────────────────────────────────────────────────────────────────

class ProductsScreen extends ConsumerWidget {
  final String? initialSearch;
  const ProductsScreen({super.key, this.initialSearch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);

    return categoriesAsync.when(
      loading: () => const Scaffold(body: AppLoadingView()),
      error: (e, _) => Scaffold(body: AppErrorView(message: e.toString())),
      data: (categories) {
        final filterCategories = List<String>.from(categories);
        if (!filterCategories.contains('All')) {
          filterCategories.insert(0, 'All');
        }
        return ProductsScreenContent(
          categories: filterCategories,
          initialSearch: initialSearch,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class ProductsScreenContent extends ConsumerStatefulWidget {
  final List<String> categories;
  final String? initialSearch;

  const ProductsScreenContent({
    super.key,
    required this.categories,
    this.initialSearch,
  });

  @override
  ConsumerState<ProductsScreenContent> createState() =>
      _ProductsScreenContentState();
}

class _ProductsScreenContentState extends ConsumerState<ProductsScreenContent> {
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocus = FocusNode();

  String _searchQuery = '';
  String _sortMode =
      'popular'; // 'popular' | 'price_asc' | 'price_desc' | 'newest'
  final Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch);
    _searchQuery = widget.initialSearch ?? '';

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleCategory(String category) {
    setState(() {
      final normalized = category.toLowerCase();
      if (normalized == 'all') {
        _selectedCategories.clear();
      } else {
        if (_selectedCategories.contains(normalized)) {
          _selectedCategories.remove(normalized);
        } else {
          _selectedCategories.add(normalized);
        }
      }
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<CatalogItem> _applyFilters(List<CatalogItem> all) {
    var list = all.where((p) {
      final matchQ =
          _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchC =
          _selectedCategories.isEmpty ||
          _selectedCategories.contains(
              (p.metadata['category'] as String?)?.toLowerCase());
      return matchQ && matchC;
    }).toList();

    switch (_sortMode) {
      case 'price_asc':
        list.sort((a, b) => a.basePrice.compareTo(b.basePrice));
      case 'price_desc':
        list.sort((a, b) => b.basePrice.compareTo(a.basePrice));
      case 'newest':
        list = list.reversed.toList();
      default:
        break;
    }
    return list;
  }

  void _showSortSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        isDark: isDark,
        current: _sortMode,
        onSelected: (v) {
          setState(() => _sortMode = v);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsAsync = ref.watch(marketplaceControllerProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBgPrimary
          : AppColors.lightBgPrimary,
      drawer: const BuyerSideDrawer(),
      body: Stack(
        children: [
          // ── Atmospheric background ──────────────────────────────────────
          const IgnorePointer(child: OrbBackgroundWidget()),

          // ── Main content ───────────────────────────────────────────────
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(isDark),
              _buildSearchBar(isDark),
              _buildCategoryBar(isDark),
              _buildActiveFiltersBar(isDark),
              productsAsync.when(
                data: (products) => _buildProductGrid(products, isDark),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sliver AppBar ──────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 80,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          AppColors.darkBgPrimary.withValues(alpha: 0.95),
                          AppColors.darkBgPrimary.withValues(alpha: 0.7),
                        ]
                      : [
                          AppColors.lightBgPrimary.withValues(alpha: 0.95),
                          AppColors.lightBgPrimary.withValues(alpha: 0.7),
                        ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Builder(
                        builder: (ctx) => GestureDetector(
                          onTap: () => Scaffold.of(ctx).openDrawer(),
                          child: _GlassIcon(
                            isDark: isDark,
                            icon: Icons.menu_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Discover',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              'Find what you love',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextSecond
                                    : AppColors.lightTextSecond,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const NotificationBell(),
                      const WishlistIconWithBadge(),
                      const CartIconWithBadge(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.1 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search products, brands & more...',
                          hintStyle: GoogleFonts.inter(
                            color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: Icon(
                          Icons.close,
                          color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _GlassIcon(
              isDark: isDark,
              icon: Icons.tune_rounded,
              onTap: _showSortSheet,
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Tab Bar ───────────────────────────────────────────────────────

  Widget _buildCategoryBar(bool isDark) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _CategoryBarDelegate(
        isDark: isDark,
        selectedCategories: _selectedCategories,
        categories: widget.categories,
        onCategoryToggled: _toggleCategory,
      ),
    );
  }

  // ── Active Filters Bar ─────────────────────────────────────────────────────

  Widget _buildActiveFiltersBar(bool isDark) {
    final hasFilters = _searchQuery.isNotEmpty || _sortMode != 'popular' || _selectedCategories.isNotEmpty;
    if (!hasFilters) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_searchQuery.isNotEmpty)
              _FilterChip(
                label: '"$_searchQuery"',
                isDark: isDark,
                onRemove: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                }),
              ),
            if (_sortMode != 'popular')
              _FilterChip(
                label: _sortLabel(_sortMode),
                isDark: isDark,
                onRemove: () => setState(() => _sortMode = 'popular'),
              ),
            ..._selectedCategories.map((cat) {
              return _FilterChip(
                label: cat.toUpperCase(),
                isDark: isDark,
                onRemove: () => setState(() {
                  _selectedCategories.remove(cat);
                }),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _sortLabel(String mode) => switch (mode) {
    'price_asc' => 'Price: Low → High',
    'price_desc' => 'Price: High → Low',
    'newest' => 'Newest',
    _ => 'Popular',
  };

  // ── Product Grid ───────────────────────────────────────────────────────────

  Widget _buildProductGrid(List<CatalogItem> all, bool isDark) {
    final filtered = _applyFilters(all);

    if (filtered.isEmpty) {
      return SliverFillRemaining(child: _EmptyState(isDark: isDark));
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _ProductCard(
            item: filtered[i],
            isDark: isDark,
            onTap: () =>
                context.push('/buyer/home/product/${filtered[i].id}'),
          ),
          childCount: filtered.length,
        ),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 195,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.63,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY BAR DELEGATE
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBarDelegate extends SliverPersistentHeaderDelegate {
  final bool isDark;
  final Set<String> selectedCategories;
  final List<String> categories;
  final Function(String) onCategoryToggled;

  _CategoryBarDelegate({
    required this.isDark,
    required this.selectedCategories,
    required this.categories,
    required this.onCategoryToggled,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: isDark
              ? AppColors.darkBgPrimary.withValues(alpha: 0.85)
              : AppColors.lightBgPrimary.withValues(alpha: 0.85),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: categories.map((c) {
                  final isSelected = (c.toLowerCase() == 'all' && selectedCategories.isEmpty) ||
                      selectedCategories.contains(c.toLowerCase());
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => onCategoryToggled(c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: isSelected
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              )
                            : BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.transparent,
                              ),
                        child: Text(
                          c,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextSecond
                                    : AppColors.lightTextSecond),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_CategoryBarDelegate old) =>
      old.isDark != isDark || old.categories != categories || old.selectedCategories != selectedCategories;
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ProductCard extends ConsumerStatefulWidget {
  final CatalogItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _ProductCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverCtrl;
  late final Animation<double> _scaleAnim;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;
    
    final hasActiveFlashSale = PriceHelper.isFlashSaleActive(item);
    final effectivePrice = PriceHelper.getEffectivePrice(item);
    final originalPriceStr = '₹${item.basePrice.toStringAsFixed(0)}';
    final effectivePriceStr = '₹${effectivePrice.toStringAsFixed(0)}';

    final imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : null;
    final isOutOfStock = item.status == ListingStatus.outOfStock;
    final category = (item.metadata['category'] as String? ?? '').toUpperCase();
    final discount = item.metadata['discount'] as String? ?? '';
    final isTrending = item.metadata['trending'] == true || item.metadata['isTrending'] == true;

    final cartItems = ref.watch(cartControllerProvider);
    CartItem? matchingCartItem;
    for (final cartItem in cartItems) {
      if (cartItem.productId == item.id) {
        matchingCartItem = cartItem;
        break;
      }
    }

    final wishlistAsync = ref.watch(wishlistStreamProvider);
    final isInWishlist = wishlistAsync.maybeWhen(
      data: (items) => items.any((i) => i.id == item.id),
      orElse: () => false,
    );

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _hoverCtrl.forward(),
        onTapUp: (_) {
          _hoverCtrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _hoverCtrl.reverse(),
        child: GlassCardWidget(
          padding: const EdgeInsets.all(6),
          borderRadius: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image Frame ────────────────────────────────────────────
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    // Image Container
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox.expand(
                                child: imageUrl.startsWith('http')
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) =>
                                            _ImagePlaceholder(isDark: isDark),
                                      )
                                    : Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(6.0),
                                          child: FloatingProductWidget(
                                            floatHeight: 4,
                                            child: Image.asset(
                                              imageUrl,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            )
                          : _ImagePlaceholder(isDark: isDark),
                    ),

                    // Out of stock overlay
                    if (isOutOfStock)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'OUT OF STOCK',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Category / Promo pill
                    if (isTrending)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '🔥 TRENDING',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      )
                    else if (discount.isNotEmpty)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            discount.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      )
                    else if (category.isNotEmpty)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                    // Rating pill bottom-left
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFBBF24),
                              size: 8,
                            ),
                            const SizedBox(width: 1),
                            Text(
                              '4.8',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Wishlist button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          final notifier = ref.read(wishlistControllerProvider.notifier);
                          if (isInWishlist) {
                            notifier.removeFromWishlist(item.id);
                          } else {
                            notifier.addToWishlist(item);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isInWishlist
                                ? const Color(0xFFEC4899).withValues(alpha: 0.9)
                                : Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isInWishlist
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // ── Info Frame ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, top: 6, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Price & Quantity Adjuster Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: hasActiveFlashSale
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      originalPriceStr,
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    GradientText(
                                      effectivePriceStr,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                )
                              : GradientText(
                                  originalPriceStr,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                        if (matchingCartItem != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  ref
                                      .read(cartControllerProvider.notifier)
                                      .updateQuantity(matchingCartItem!.id, -1);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    color: isDark ? Colors.white : Colors.black87,
                                    size: 8,
                                    key: const ValueKey('remove_btn'),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '${matchingCartItem.quantity}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ref
                                      .read(cartControllerProvider.notifier)
                                      .updateQuantity(matchingCartItem!.id, 1);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 8,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          GestureDetector(
                            onTap: () async {
                              if (_isAdding) return;
                              setState(() => _isAdding = true);
                              try {
                                final cartItem = CartItem(
                                  id: item.id,
                                  productId: item.id,
                                  title: item.title,
                                  storeId: item.storeId,
                                  storeName: item.metadata['storeName']
                                          as String? ??
                                      'Seller Store',
                                  unitPrice: effectivePrice,
                                  imageUrl: item.imageUrls.isNotEmpty
                                      ? item.imageUrls.first
                                      : 'assets/images/3d/product_headphones.png',
                                  quantity: 1,
                                );

                                await ref
                                    .read(cartControllerProvider.notifier)
                                    .addItem(cartItem);

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${item.title} added to cart!',
                                      ),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(milliseconds: 1500),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to add: $e'),
                                      backgroundColor: const Color(0xFFEF4444),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isAdding = false);
                                }
                              }
                            },
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SORT BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _SortSheet extends StatelessWidget {
  final bool isDark;
  final String current;
  final void Function(String) onSelected;

  const _SortSheet({
    required this.isDark,
    required this.current,
    required this.onSelected,
  });

  static const _options = [
    ('popular', Icons.local_fire_department_rounded, 'Most Popular'),
    ('price_asc', Icons.arrow_upward_rounded, 'Price: Low to High'),
    ('price_desc', Icons.arrow_downward_rounded, 'Price: High to Low'),
    ('newest', Icons.fiber_new_rounded, 'Newest First'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.lightBgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sort By',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._options.map((opt) {
            final (value, icon, label) = opt;
            final selected = current == value;
            return GestureDetector(
              onTap: () => onSelected(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.06)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: selected
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.darkTextSecond
                                : AppColors.lightTextSecond),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                      ),
                    ),
                    const Spacer(),
                    if (selected)
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _GlassIcon extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback? onTap;

  const _GlassIcon({required this.isDark, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final bool isDark;

  const _ImagePlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.03),
      child: Icon(
        Icons.image_outlined,
        size: 36,
        color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 36,
              color: isDark
                  ? AppColors.darkAccentPurple
                  : AppColors.lightAccentPurple,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nothing found',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different category or search term',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecond
                  : AppColors.lightTextSecond,
            ),
          ),
        ],
      ),
    );
  }
}
