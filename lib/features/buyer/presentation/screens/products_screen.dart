import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/providers/categories_provider.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/widgets/app_shimmer.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_product_card.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_side_drawer.dart';
import 'package:ecom/features/buyer/presentation/widgets/variant_selector_sheet.dart';
import 'package:ecom/features/marketplace/data/dtos/catalog_item_dto.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/shared/presentation/widgets/cart_icon_with_badge.dart';
import 'package:ecom/shared/presentation/widgets/wishlist_icon_with_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Pagination State ─────────────────────────────────────────────────────────

class CatalogState {
  final List<CatalogItem> items;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;

  const CatalogState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDoc,
  });

  CatalogState copyWith({
    List<CatalogItem>? items,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
  }) => CatalogState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    hasMore: hasMore ?? this.hasMore,
    lastDoc: lastDoc ?? this.lastDoc,
  );
}

// ─── Catalog Notifier ─────────────────────────────────────────────────────────

final catalogNotifierProvider = NotifierProvider<CatalogNotifier, CatalogState>(
  CatalogNotifier.new,
);

class CatalogNotifier extends Notifier<CatalogState> {
  static const int _pageSize = 20;

  String? _category;

  @override
  CatalogState build() {
    return const CatalogState();
  }

  Future<void> init({String? category}) async {
    _category = category;
    state = const CatalogState(isLoading: true);
    await _fetchPage(reset: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    await _fetchPage(reset: false);
  }

  Future<void> _fetchPage({required bool reset}) async {
    try {
      final firestore = ref.read(firebaseFirestoreProvider);
      debugPrint('Fetching products with category: $_category');

      Query<Map<String, dynamic>> query = firestore
          .collection('catalog')
          .where('status', isEqualTo: 'active')
          .where('type', isEqualTo: 'product');

      if (_category != null && _category!.isNotEmpty) {
        debugPrint('Filtering by category: $_category');
        query = query.where('category', isEqualTo: _category);
      }

      if (!reset && state.lastDoc != null) {
        query = query.startAfterDocument(state.lastDoc!);
      }

      query = query.limit(_pageSize);

      final snap = await query.get();
      debugPrint('Query returned ${snap.docs.length} documents');

      final newItems = snap.docs
          .map((d) => CatalogItemDto.fromMap(d.id, d.data()))
          .toList();

      debugPrint('Parsed ${newItems.length} items');

      final existing = reset ? <CatalogItem>[] : state.items;
      state = CatalogState(
        items: [...existing, ...newItems],
        isLoading: false,
        hasMore: newItems.length == _pageSize,
        lastDoc: snap.docs.isNotEmpty ? snap.docs.last : state.lastDoc,
      );
    } catch (e) {
      debugPrint('Products screen fetch error: $e');
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class ProductsScreen extends ConsumerStatefulWidget {
  final String? initialSearch;

  const ProductsScreen({super.key, this.initialSearch});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String? _selectedCategory;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchController.text = widget.initialSearch!;
      _searchQuery = widget.initialSearch!.toLowerCase().trim();
    }
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(catalogNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _reload() async {
    await ref
        .read(catalogNotifierProvider.notifier)
        .init(category: _selectedCategory);
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = val.toLowerCase().trim());
    });
  }

  List<CatalogItem> _filtered(List<CatalogItem> items) {
    if (_searchQuery.isEmpty) return items;
    return items
        .where(
          (i) =>
              i.title.toLowerCase().contains(_searchQuery) ||
              i.category.toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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

    final catalogState = ref.watch(catalogNotifierProvider);
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);




    final displayItems = _filtered(catalogState.items);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: const BuyerSideDrawer(),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row containing Title, Wishlist, and Cart
                    Row(
                      children: [
                        Builder(
                          builder: (context) => GestureDetector(
                            onTap: () => Scaffold.of(context).openDrawer(),
                            child: _buildGlassIcon(Icons.menu_rounded, isDark),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Discover',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        const WishlistIconWithBadge(),
                        const CartIconWithBadge(),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Search bar
                    _SearchBar(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      isDark: isDark,
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecond: textSecond,
                      accent: accent,
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // ── Category chips ──
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: categoriesAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, _) => const SizedBox(),
                  data: (cats) => ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _CategoryChip(
                        label: 'All',
                        isSelected: _selectedCategory == null,
                        onTap: () {
                          setState(() => _selectedCategory = null);
                          _reload();
                        },
                        isDark: isDark,
                        accent: accent,
                        textPrimary: textPrimary,
                      ),
                      ...cats.map(
                        (cat) => _CategoryChip(
                          label: cat,
                          isSelected: _selectedCategory == cat,
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            _reload();
                          },
                          isDark: isDark,
                          accent: accent,
                          textPrimary: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Sort row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  '${displayItems.length} products',
                  style: theme.textTheme.bodySmall?.copyWith(color: textSecond),
                ),
              ),
            ),

            // ── Grid ──
            if (catalogState.items.isEmpty && catalogState.isLoading)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, _) => const _ShimmerCard(),
                    childCount: 6,
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.54,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
              )
            else if (displayItems.isEmpty && !catalogState.isLoading)
              SliverFillRemaining(
                child: _EmptyState(
                  hasSearch: _searchQuery.isNotEmpty,
                  textPrimary: textPrimary,
                  textSecond: textSecond,
                  accent: accent,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ProductGridItem(
                      item: displayItems[i],
                      isDark: isDark,
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecond: textSecond,
                      accent: accent,
                    ),
                    childCount: displayItems.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.54,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
              ),

            // ── Load more indicator ──
            SliverToBoxAdapter(
              child: catalogState.isLoading && catalogState.items.isNotEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search Bar ──────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isDark;
  final Color surface;
  final Color textPrimary;
  final Color textSecond;
  final Color accent;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecond,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: textPrimary),
        decoration: InputDecoration(
          hintText: 'Search products…',
          hintStyle: TextStyle(color: textSecond),
          prefixIcon: Icon(Icons.search_rounded, color: textSecond),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: textSecond, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}

// ─── Category Chip ───────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color accent;
  final Color textPrimary;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.accent,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? accent
                : isDark
                ? AppColors.darkBgSurface
                : AppColors.lightBgSurface,
            borderRadius: BorderRadius.circular(22),
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isSelected ? Colors.white : textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Product Grid Card ───────────────────────────────────────────────────────

class _ProductGridItem extends ConsumerStatefulWidget {
  final CatalogItem item;
  final bool isDark;
  final Color surface;
  final Color textPrimary;
  final Color textSecond;
  final Color accent;

  const _ProductGridItem({
    required this.item,
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecond,
    required this.accent,
  });

  @override
  ConsumerState<_ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends ConsumerState<_ProductGridItem> {
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    final cartItems = ref.watch(cartControllerProvider);
    CartItem? matchingCartItem;
    int variantCartQuantity = 0;
    for (final cartItem in cartItems) {
      if (cartItem.productId == item.id) {
        if (item.hasVariants) {
          variantCartQuantity += cartItem.quantity.toInt();
        } else {
          matchingCartItem = cartItem;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: BuyerProductCard(
            product: item,
            showTrendingBadge: false,
            showQuantitySelector: false,
            onTap: null,
          ),
        ),
        const SizedBox(height: 8),
        if (matchingCartItem == null && variantCartQuantity == 0)
          _buildAddToCartButton(context, item)
        else if (matchingCartItem != null)
          _buildQuantityStepper(context, matchingCartItem)
        else
          _buildAddToCartButton(
            context,
            item,
            variantCartQuantity: variantCartQuantity,
          ),
      ],
    );
  }

  Widget _buildAddToCartButton(
    BuildContext context,
    CatalogItem item, {
    int variantCartQuantity = 0,
  }) {
    return GestureDetector(
      onTap: () async {
        if (_isAdding) return;
        setState(() => _isAdding = true);
        try {
          await handleAddToCart(context, ref, item);
        } finally {
          if (mounted) setState(() => _isAdding = false);
        }
      },
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _isAdding
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add to Cart',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (variantCartQuantity > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$variantCartQuantity in cart',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildQuantityStepper(BuildContext context, CartItem cartItem) {
    final isDark = widget.isDark;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              ref
                  .read(cartControllerProvider.notifier)
                  .updateQuantity(cartItem.id, -1);
            },
            icon: Icon(
              Icons.remove_rounded,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            '${cartItem.quantity}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              ref
                  .read(cartControllerProvider.notifier)
                  .updateQuantity(cartItem.id, 1);
            },
            icon: Icon(
              Icons.add_rounded,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer Card ────────────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AppShimmer(width: double.infinity, borderRadius: 0),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(width: double.infinity, height: 14, borderRadius: 6),
                const SizedBox(height: 6),
                AppShimmer(width: 80, height: 14, borderRadius: 6),
                const Spacer(),
                AppShimmer(width: 60, height: 18, borderRadius: 6),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final Color textPrimary;
  final Color textSecond;
  final Color accent;

  const _EmptyState({
    required this.hasSearch,
    required this.textPrimary,
    required this.textSecond,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.shopping_bag_outlined,
              size: 64,
              color: accent.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'No results found' : 'No products yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Try a different search term or category'
                  : 'Check back later for new arrivals',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: textSecond),
            ),
          ],
        ),
      ),
    );
  }
}
