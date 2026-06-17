import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ecom/core/widgets/app_product_card.dart';
import 'package:ecom/core/widgets/app_search_bar.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() =>
      _ProductsScreenState();
}

class _ProductsScreenState
    extends State<ProductsScreen> {
  final TextEditingController
  _searchController =
  TextEditingController();

  final List<String> categories = [
    'All',
    'Electronics',
    'Fashion',
    'Beauty',
    'Home',
    'Sports',
    'Books',
  ];

  String selectedCategory = 'All';

  final products = List.generate(
    20,
        (index) => {
      'id': 'p$index',
      'title': 'Premium Product ${index + 1}',
      'price': 999.0 + index * 100,
      'rating': 4.2,
      'image':
      'https://picsum.photos/400/400?random=$index',
    },
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.of(context).size.width;

    final crossAxisCount =
    width > 1200
        ? 5
        : width > 900
        ? 4
        : width > 600
        ? 3
        : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.favorite_border,
            ),
            onPressed: () {
              context.push(
                '/buyer/wishlist',
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.shopping_cart_outlined,
            ),
            onPressed: () {
              context.push('/buyer/cart');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.all(16),
            child: AppSearchBar(
              controller:
              _searchController,
            ),
          ),

          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection:
              Axis.horizontal,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              itemCount:
              categories.length,
              itemBuilder:
                  (context, index) {
                final category =
                categories[index];

                final selected =
                    category ==
                        selectedCategory;

                return Padding(
                  padding:
                  const EdgeInsets.only(
                    right: 8,
                  ),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory =
                            category;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: GridView.builder(
              padding:
              const EdgeInsets.all(16),
              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: products.length,
              itemBuilder:
                  (context, index) {
                final product =
                products[index];

                return AppProductCard(
                  title:
                  product['title']
                  as String,
                  imageUrl:
                  product['image']
                  as String,
                  rating:
                  product['rating']
                  as double,
                  price:
                  product['price']
                  as double,
                  onTap: () {
                    context.push(
                      '/buyer/home/product/${product['id']}',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}