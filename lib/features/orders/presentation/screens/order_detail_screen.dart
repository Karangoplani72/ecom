import 'package:ecom/core/widgets/app_price_text.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/features/orders/domain/entities/order.dart';
import 'package:ecom/features/orders/domain/entities/order_status.dart';
import 'package:ecom/features/orders/presentation/controllers/order_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // We can find the order from the list providers for efficiency
    final buyerOrders = ref.watch(buyerOrdersProvider).value ?? [];
    final sellerOrders = ref.watch(sellerOrdersProvider).value ?? [];

    final order = [...buyerOrders, ...sellerOrders].firstWhere(
      (o) => o.orderId == orderId,
      orElse: () => throw Exception('Order not found'),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Order #${order.orderId.substring(0, 8).toUpperCase()}'),
        centerTitle: true,
      ),
      body: ResponsiveLayout(
        maxWidth: 800,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusSection(order, theme, colorScheme),
              const SizedBox(height: 32),
              _buildItemsSection(order, theme, colorScheme),
              const SizedBox(height: 32),
              _buildPricingSection(order, theme, colorScheme),
              const SizedBox(height: 32),
              _buildDeliverySection(order, theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection(
    AppOrder order,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Status',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Last updated on ${DateFormat('MMM d, yyyy • hh:mm a').format(order.updatedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(
    AppOrder order,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items from ${order.storeName}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...order.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Quantity: ${item.quantity}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                AppPriceText(amount: item.unitPrice * item.quantity),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection(
    AppOrder order,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _priceRow('Subtotal', order.subtotal, theme),
          const SizedBox(height: 8),
          _priceRow('Delivery Fee', order.deliveryFee, theme),
          const SizedBox(height: 8),
          _priceRow('Platform Fee', order.platformFee, theme),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${order.totalAmount.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection(
    AppOrder order,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Address',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  order.deliveryAddress,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, double amount, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  (Color, String) _getStatusConfig(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return (Colors.orange, 'Pending');
      case OrderStatus.confirmed:
        return (Colors.blue, 'Confirmed');
      case OrderStatus.packed:
        return (Colors.indigo, 'Packed');
      case OrderStatus.shipped:
        return (Colors.purple, 'Shipped');
      case OrderStatus.outForDelivery:
        return (Colors.teal, 'Out for Delivery');
      case OrderStatus.delivered:
        return (Colors.green, 'Delivered');
      case OrderStatus.cancelled:
        return (Colors.red, 'Cancelled');
      case OrderStatus.refunded:
        return (Colors.grey, 'Refunded');
    }
  }
}
