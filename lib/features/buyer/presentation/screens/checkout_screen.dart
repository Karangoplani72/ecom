import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ecom/core/widgets/app_price_text.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(
      cartControllerProvider,
    );

    final subtotal = cartItems.fold<double>(
      0,
          (sum, item) =>
      sum + (item.unitPrice * item.quantity),
    );

    final gst = subtotal * 0.18;
    final total = subtotal + gst;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Order Summary',
            style:
            Theme.of(context)
                .textTheme
                .titleLarge,
          ),

          const SizedBox(height: 16),

          ...cartItems.map(
                (item) => Card(
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(
                  'Qty ${item.quantity}',
                ),
                trailing: AppPriceText(
                  amount:
                  item.unitPrice *
                      item.quantity,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding:
              const EdgeInsets.all(16),
              child: Column(
                children: [
                  _billRow(
                    'Subtotal',
                    subtotal,
                  ),
                  const SizedBox(height: 12),
                  _billRow(
                    'GST (18%)',
                    gst,
                  ),
                  const Divider(),
                  _billRow(
                    'Total',
                    total,
                    bold: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.location_on_outlined,
              ),
              title: const Text(
                'Delivery Address',
              ),
              subtitle: const Text(
                'Address management coming soon',
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading:
              const Icon(Icons.payment),
              title: const Text(
                'Payment Method',
              ),
              subtitle: const Text(
                'UPI / Card / COD',
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Order placed successfully',
                    ),
                  ),
                );

                context.go(
                  '/buyer/orders',
                );
              },
              child: Text(
                'Pay ₹${total.toStringAsFixed(2)}',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _billRow(
      String label,
      double amount, {
        bool bold = false,
      }) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: bold
                ? FontWeight.bold
                : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}