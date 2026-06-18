import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_product_card.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  // Wishlist items would ideally come from a Provider/Controller
  final List<Map<String, dynamic>> wishlistItems = [
    {
      'id': 'w1',
      'title': 'Premium Headphones',
      'price': 4999.0,
      'rating': 4.7,
      'image': 'https://picsum.photos/400?random=100',
    },
    {
      'id': 'w2',
      'title': 'Gaming Mouse',
      'price': 1999.0,
      'rating': 4.5,
      'image': 'https://picsum.photos/400?random=101',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Wishlist'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/buyer/cart'),
          ),
        ],
      ),
      body: ResponsiveLayout(
        maxWidth: 1200,
        child: wishlistItems.isEmpty
            ? const AppEmptyView(
                title: 'Empty Wishlist',
                subtitle:
                    'Save your favorite items here to find them easily later.',
                icon: Icons.favorite_border,
              )
            : GridView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20),
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
                itemCount: wishlistItems.length,
                itemBuilder: (context, index) {
                  final item = wishlistItems[index];
                  return Stack(
                    children: [
                      AppProductCard(
                        title: item['title'] as String,
                        imageUrl: item['image'] as String,
                        rating: item['rating'] as double,
                        price: item['price'] as double,
                        onTap: () =>
                            context.push('/buyer/home/product/${item['id']}'),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => wishlistItems.removeAt(index));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Removed from wishlist'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
