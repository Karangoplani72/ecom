import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/cart_item.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartControllerProvider);
    final cartNotifier = ref.read(cartControllerProvider.notifier);
    final groupedItems = cartNotifier.groupedByStore;
    final subtotal = cartNotifier.subtotal;

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shopping Cart')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 80, color: AppTheme.roseGold),
              const SizedBox(height: 16),
              Text('Your cart is empty', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Looks like you haven\'t added anything yet.', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final storeName = groupedItems.keys.elementAt(index);
                  final items = groupedItems[storeName]!;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.storefront, color: AppTheme.slateGreyText, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                storeName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.charcoalText),
                              ),
                            ],
                          ),
                        ),
                        // Items List for this Store
                        ...items.map((item) => _buildCartItemCard(context, item, cartNotifier)),
                      ],
                    ),
                  );
                },
                childCount: groupedItems.length,
              ),
            ),
          ),

          // Order Summary Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: AppTheme.surfaceWhite,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Summary', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(height: 32, color: AppTheme.creamBackground),
                      _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                      const SizedBox(height: 12),
                      _buildSummaryRow('Taxes & Fees', 'Calculated at checkout'),
                      const Divider(height: 32, color: AppTheme.creamBackground),
                      _buildSummaryRow('Estimated Total', '₹${subtotal.toStringAsFixed(2)}', isTotal: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding for sticky nav
        ],
      ),

      // Sticky Bottom Checkout Bar
      bottomSheet: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          boxShadow: [
            BoxShadow(color: AppTheme.charcoalText.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Payment', style: TextStyle(color: AppTheme.slateGreyText, fontSize: 12)),
                    Text(
                      '₹${subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppTheme.charcoalText, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/buyer/checkout');                  },
                  child: const Text('Checkout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? AppTheme.charcoalText : AppTheme.slateGreyText,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.charcoalText,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item, CartController cartNotifier) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.errorCoral,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: AppTheme.surfaceWhite),
        ),
        onDismissed: (_) => cartNotifier.removeItem(item.id),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.champagneGold.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.creamBackground,
                  borderRadius: BorderRadius.circular(8),
                  image: item.imageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: item.imageUrl.isEmpty ? const Icon(Icons.image, color: AppTheme.roseGold) : null,
              ),
              const SizedBox(width: 16),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${item.unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppTheme.blushPink, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.champagneGold),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => cartNotifier.updateQuantity(item.id, -1),
                      child: const Padding(padding: EdgeInsets.all(6.0), child: Icon(Icons.remove, size: 16)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    InkWell(
                      onTap: () => cartNotifier.updateQuantity(item.id, 1),
                      child: const Padding(padding: EdgeInsets.all(6.0), child: Icon(Icons.add, size: 16)),
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