import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';
import 'package:ecom/features/marketplace/presentation/controllers/marketplace_controller.dart';
import 'package:ecom/core/providers/categories_provider.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecom/shared/presentation/widgets/cart_icon_with_badge.dart';
import 'package:go_router/go_router.dart';

import 'package:ecom/features/buyer/presentation/widgets/buyer_side_drawer.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);

    return categoriesAsync.when(
      loading: () => const Scaffold(body: AppLoadingView()),
      error: (error, _) => Scaffold(body: AppErrorView(message: error.toString())),
      data: (categories) {
        // Ensure "All" is at the start of the category list for filter tabs
        final filterCategories = List<String>.from(categories);
        if (!filterCategories.contains('All')) {
          filterCategories.insert(0, 'All');
        }
        return ProductsScreenContent(categories: filterCategories);
      },
    );
  }
}

class ProductsScreenContent extends ConsumerStatefulWidget {
  final List<String> categories;

  const ProductsScreenContent({super.key, required this.categories});

  @override
  ConsumerState<ProductsScreenContent> createState() => _ProductsScreenContentState();
}

class _ProductsScreenContentState extends ConsumerState<ProductsScreenContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to filter by category
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsAsync = ref.watch(marketplaceControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary,
      drawer: const BuyerSideDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond,
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                ),
              )
            : Text(
                'All Products',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _isSearching = false;
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          const CartIconWithBadge(),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              physics: const ClampingScrollPhysics(),
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: const EdgeInsets.symmetric(horizontal: 20),
              indicatorPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond,
              tabs: widget.categories.map((category) => Tab(text: category)).toList(),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const IgnorePointer(child: OrbBackgroundWidget()),
          productsAsync.when(
            data: (products) {
              final selectedCategory = widget.categories[_tabController.index];
              
              final filtered = products.where((product) {
                final matchesQuery = _searchQuery.isEmpty ||
                    product.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    product.description.toLowerCase().contains(_searchQuery.toLowerCase());
                
                final matchesCategory = selectedCategory == 'All' ||
                    (product.metadata['category'] as String?)?.toLowerCase() == selectedCategory.toLowerCase();
                
                return matchesQuery && matchesCategory;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No products found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try checking another category or refining search',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 768;
                  final crossAxisCount = isWide ? 4 : 2;
                  
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;
                      
                      return GestureDetector(
                        onTap: () {
                          context.push('/buyer/home/product/${product.id}');
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBgSurface : AppColors.lightBgSurface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                        image: DecorationImage(
                                          image: imageUrl != null && imageUrl.startsWith('http')
                                              ? NetworkImage(imageUrl) as ImageProvider
                                              : AssetImage(imageUrl ?? 'assets/images/3d/product_headphones.png'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkBgSurface : AppColors.lightBgSurface,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.favorite_border,
                                          size: 12,
                                          color: Color(0xFFEC4899),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 11),
                                        const SizedBox(width: 2),
                                        Text(
                                          '4.8',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      product.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${product.basePrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? AppColors.darkAccentPurple : AppColors.lightAccentPurple,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ],
      ),
    );
  }
}
