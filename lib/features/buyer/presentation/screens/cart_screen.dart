import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_price_text.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartControllerProvider);

    final subtotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );

    if (cartItems.isEmpty) {
      return const Scaffold(
        body: AppEmptyView(
          title: 'Your Cart is Empty',
          subtitle: 'Products added to cart will appear here.',
          icon: Icons.shopping_cart_outlined,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: cartItems.length,
        separatorBuilder: (context, state) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = cartItems[index];

          return Card(
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image),
                ),
              ),
              title: Text(item.title),
              subtitle: Text('Qty: ${item.quantity}'),
              trailing: AppPriceText(amount: item.unitPrice * item.quantity),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: TextStyle(fontSize: 16)),
                  AppPriceText(amount: subtotal),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    context.push('/buyer/checkout');
                  },
                  child: const Text('Proceed To Checkout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
