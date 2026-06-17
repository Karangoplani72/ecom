import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_product_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() =>
      _WishlistScreenState();
}

class _WishlistScreenState
    extends State<WishlistScreen> {
  final List<Map<String, dynamic>>
  wishlistItems = [
    {
      'id': 'w1',
      'title': 'Premium Headphones',
      'price': 4999.0,
      'rating': 4.7,
      'image':
      'https://picsum.photos/400?random=100',
    },
    {
      'id': 'w2',
      'title': 'Gaming Mouse',
      'price': 1999.0,
      'rating': 4.5,
      'image':
      'https://picsum.photos/400?random=101',
    },
  ];

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

    if (wishlistItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Wishlist',
          ),
        ),
        body: const AppEmptyView(
          title: 'Wishlist Empty',
          subtitle:
          'Save products you like and they will appear here.',
          icon: Icons.favorite_border,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wishlist',
        ),
        actions: [
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
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate:
        SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.68,
        ),
        itemCount: wishlistItems.length,
        itemBuilder: (context, index) {
          final item =
          wishlistItems[index];

          return Stack(
            children: [
              AppProductCard(
                title:
                item['title'] as String,
                imageUrl:
                item['image'] as String,
                rating:
                item['rating'] as double,
                price:
                item['price'] as double,
                onTap: () {
                  context.push(
                    '/buyer/home/product/${item['id']}',
                  );
                },
              ),

              Positioned(
                right: 8,
                top: 8,
                child: Card(
                  child: IconButton(
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      setState(() {
                        wishlistItems.removeAt(
                          index,
                        );
                      });

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Removed from wishlist',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Added to cart',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.shopping_cart,
                  ),
                  label: const Text(
                    'Add',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}