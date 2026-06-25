import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/providers/categories_provider.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/widgets/app_network_image.dart';
import 'package:ecom/core/widgets/app_shimmer.dart';
import 'package:ecom/features/marketplace/data/dtos/catalog_item_dto.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/seller/domain/entities/seller_product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
                    // Title
                    Text(
                      'Discover',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
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
                    (_, i) => _ProductGridCard(
                      item: displayItems[i],
                      isDark: isDark,
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecond: textSecond,
                      accent: accent,
                      onTap: () =>
                          context.push('/product/${displayItems[i].id}'),
                    ),
                    childCount: displayItems.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
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

class _ProductGridCard extends StatefulWidget {
  final CatalogItem item;
  final VoidCallback onTap;
  final bool isDark;
  final Color surface;
  final Color textPrimary;
  final Color textSecond;
  final Color accent;

  const _ProductGridCard({
    required this.item,
    required this.onTap,
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecond,
    required this.accent,
  });

  @override
  State<_ProductGridCard> createState() => _ProductGridCardState();
}

class _ProductGridCardState extends State<_ProductGridCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Finds the variant options to show as color swatches, if this product
  /// has a "Color"/"Colour" attribute (or any attribute whose options carry
  /// a colorHex), else returns an empty list.
  List<VariantOption> _colorOptionsFor(CatalogItem item) {
    if (!item.hasVariants) return const [];
    for (final attr in item.variantAttributes) {
      final n = attr.name.toLowerCase();
      final isColorAttr =
          n.contains('color') ||
          n.contains('colour') ||
          attr.options.any((o) => o.colorHex != null);
      if (isColorAttr) {
        return attr.options.where((o) => o.colorHex != null).toList();
      }
    }
    return const [];
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

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: widget.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ──
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: item.coverImage.isNotEmpty
                          ? AppNetworkImage(
                              imageUrl: item.coverImage,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 40,
                              ),
                            ),
                    ),
                    // Discount badge
                    if (item.hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.discountPercent}% off',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    // Out of stock overlay
                    if (item.isOutOfStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                          child: const Center(
                            child: Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Color Swatches (below image) ──
              if (_colorOptionsFor(item).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: SizedBox(
                    height: 18,
                    child: Row(
                      children: [
                        ..._colorOptionsFor(item).take(5).map((opt) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _parseColorHex(opt.colorHex),
                                border: Border.all(
                                  color: widget.isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                            ),
                          );
                        }),
                        if (_colorOptionsFor(item).length > 5)
                          Text(
                            '+${_colorOptionsFor(item).length - 5}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: widget.textSecond,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    ),
                  ),
                ),

              // ── Info ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: widget.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const Spacer(),
                      // Price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${item.basePrice.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: widget.accent,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          if (item.hasDiscount) ...[
                            const SizedBox(width: 4),
                            Text(
                              '₹${item.compareAtPrice!.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: widget.textSecond,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                            ),
                          ],
                        ],
                      ),
                      // Rating
                      if (item.reviewCount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: AppColors.warning,
                              size: 13,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.avgRating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: widget.textSecond,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              ' (${item.reviewCount})',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: widget.textSecond),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
