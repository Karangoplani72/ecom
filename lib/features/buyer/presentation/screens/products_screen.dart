import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_product_card.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/features/marketplace/presentation/controllers/marketplace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  RangeValues _priceRange = const RangeValues(0, 100000);
  String _sortBy = 'default';

  final List<String> categories = [
    'All',
    'Electronics',
    'Fashion',
    'Beauty',
    'Home',
    'Sports',
    'Books',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'Price Range',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 100000,
                divisions: 100,
                labels: RangeLabels(
                  '₹${_priceRange.start.toInt()}',
                  '₹${_priceRange.end.toInt()}',
                ),
                onChanged: (values) {
                  setModalState(() => _priceRange = values);
                  setState(() => _priceRange = values);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Sort By',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _sortChip('default', 'Default', setModalState),
                  _sortChip('price_asc', 'Price: Low to High', setModalState),
                  _sortChip('price_desc', 'Price: High to Low', setModalState),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Filters'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortChip(String value, String label, StateSetter setModalState) {
    final selected = _sortBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setModalState(() => _sortBy = value);
        setState(() => _sortBy = value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(marketplaceControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('All Products'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/buyer/cart'),
          ),
        ],
      ),
      body: ResponsiveLayout(
        maxWidth: 1200,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search for products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final selected = category == _selectedCategory;
                        return ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = category),
                          selectedColor: colorScheme.primaryContainer,
                          checkmarkColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelStyle: TextStyle(
                            color: selected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: catalogState.when(
                loading: () => const AppLoadingView(),
                error: (error, stack) => AppErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(marketplaceControllerProvider),
                ),
                data: (items) {
                  final searchText = _searchController.text.toLowerCase();

                  var filtered = items.where((item) {
                    final matchesSearch =
                        item.title.toLowerCase().contains(searchText) ||
                        item.description.toLowerCase().contains(searchText);
                    final matchesCategory =
                        _selectedCategory == 'All' ||
                        (item.metadata['category'] as String?) ==
                            _selectedCategory;
                    final matchesPrice =
                        item.basePrice >= _priceRange.start &&
                        item.basePrice <= _priceRange.end;
                    return matchesSearch && matchesCategory && matchesPrice;
                  }).toList();

                  if (_sortBy == 'price_asc') {
                    filtered.sort((a, b) => a.basePrice.compareTo(b.basePrice));
                  } else if (_sortBy == 'price_desc') {
                    filtered.sort((a, b) => b.basePrice.compareTo(a.basePrice));
                  }

                  if (filtered.isEmpty) {
                    return AppEmptyView(
                      title: searchText.isNotEmpty
                          ? 'No Products Found'
                          : 'Inventory Empty',
                      subtitle: searchText.isNotEmpty
                          ? 'Try different keywords or filters'
                          : 'Check back later for new arrivals.',
                      icon: Icons.search_off_rounded,
                      action: searchText.isNotEmpty
                          ? TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _selectedCategory = 'All';
                                  _priceRange = const RangeValues(0, 100000);
                                });
                              },
                              child: const Text('Clear Filters'),
                            )
                          : null,
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: width > 1200
                          ? 5
                          : width > 900
                          ? 4
                          : width > 600
                          ? 3
                          : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return AppProductCard(
                        title: item.title,
                        imageUrl: item.imageUrls.isNotEmpty
                            ? item.imageUrls.first
                            : '',
                        rating: 4.8,
                        price: item.basePrice,
                        onTap: () =>
                            context.push('/buyer/home/product/${item.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
