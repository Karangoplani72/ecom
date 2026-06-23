import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_price_text.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/core/widgets/scaffolds/premium_25d_scaffold.dart';
import 'package:ecom/core/widgets/cards/glass_card.dart';
import 'package:ecom/features/orders/domain/entities/order.dart';
import 'package:ecom/features/orders/domain/entities/order_status.dart';
import 'package:ecom/features/orders/presentation/controllers/order_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final orderAsync = ref.watch(orderByIdProvider(orderId));
    final currentUserId = ref.watch(currentUserIdProvider);

    ref.listen(orderControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      error.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ),
          );
        },
      );
    });

    return Premium25DScaffold(
      isDark: theme.brightness == Brightness.dark,
      particles: [
        FloatingParticle(imagePath: 'assets/images/25d_sphere.svg', width: 40, height: 40, dx: -100, dy: 100, delay: 0.1, depth: 1.2),
        FloatingParticle(imagePath: 'assets/images/25d_cube.svg', width: 30, height: 30, dx: 300, dy: 300, delay: 0.4, depth: 0.8),
      ],
      appBar: AppBar(
        title: Text(
          'Order #${orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}',
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: orderAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(orderByIdProvider(orderId)),
        ),
        data: (order) {
          if (order == null) {
            return const AppErrorView(message: 'Order not found');
          }

          final isSeller = order.storeId == currentUserId;
          final isBuyer = order.buyerId == currentUserId;

          return ResponsiveLayout(
            maxWidth: 800,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusSection(order, theme, colorScheme),
                  const SizedBox(height: 24),
                  _buildTrackingSection(order, theme, colorScheme),
                  const SizedBox(height: 24),
                  _buildItemsSection(order, theme, colorScheme),
                  const SizedBox(height: 24),
                  _buildPricingSection(order, theme, colorScheme),
                  const SizedBox(height: 24),
                  _buildDeliverySection(order, theme, colorScheme),
                  const SizedBox(height: 24),
                  _buildPaymentSection(order, theme, colorScheme),
                  if (isSeller) ...[
                    const SizedBox(height: 32),
                    _buildSellerActions(context, ref, order, theme, colorScheme),
                  ],
                  if (isBuyer && order.canCancel) ...[
                    const SizedBox(height: 32),
                    _buildCancelButton(context, ref, order),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(
    AppOrder order,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return GlassCard(
      isDark: theme.brightness == Brightness.dark,
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                order.storeName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Last updated ${DateFormat('MMM d, yyyy • hh:mm a').format(order.updatedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingSection(
    AppOrder order,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final statuses = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.packed,
      OrderStatus.shipped,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];

    if (order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.refunded) {
      return const SizedBox.shrink();
    }

    final currentIndex = statuses.indexOf(order.status);

    return GlassCard(
      isDark: theme.brightness == Brightness.dark,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Tracking',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        border: isCurrent
                            ? Border.all(color: colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.circle_outlined,
                        size: 16,
                        color: isCompleted
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (index < statuses.length - 1)
                      Container(
                        width: 2,
                        height: 32,
                        color: isCompleted && index < currentIndex
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _statusLabel(status),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCompleted
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.packed:
        return 'Packed & Ready';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
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
          'Items (${order.items.length})',
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
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_outlined),
                    ),
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
    return GlassCard(
      isDark: theme.brightness == Brightness.dark,
      padding: const EdgeInsets.all(20),
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
        GlassCard(
          isDark: theme.brightness == Brightness.dark,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.buyerName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      order.deliveryAddress,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(
    AppOrder order,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return GlassCard(
      isDark: theme.brightness == Brightness.dark,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.payment_outlined),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                order.paymentMethod,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: order.paymentStatus == 'paid'
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              order.paymentStatus.toUpperCase(),
              style: TextStyle(
                color: order.paymentStatus == 'paid'
                    ? Colors.green
                    : Colors.orange,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerActions(
    BuildContext context,
    WidgetRef ref,
    AppOrder order,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final nextStatus = _getNextStatus(order.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seller Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (nextStatus != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _updateStatus(context, ref, order.orderId, nextStatus),
              icon: const Icon(Icons.arrow_forward),
              label: Text('Mark as ${nextStatus.name.toUpperCase()}'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showStatusPicker(context, ref, order),
            child: const Text('Change to specific status'),
          ),
        ),
      ],
    );
  }

  OrderStatus? _getNextStatus(OrderStatus current) {
    switch (current) {
      case OrderStatus.pending:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.packed;
      case OrderStatus.packed:
        return OrderStatus.shipped;
      case OrderStatus.shipped:
        return OrderStatus.outForDelivery;
      case OrderStatus.outForDelivery:
        return OrderStatus.delivered;
      default:
        return null;
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String orderId,
    OrderStatus status,
  ) async {
    await ref.read(orderControllerProvider.notifier).updateStatus(
          orderId: orderId,
          status: status,
        );
    ref.invalidate(orderByIdProvider(orderId));
  }

  void _showStatusPicker(BuildContext context, WidgetRef ref, AppOrder order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Select Order Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...OrderStatus.values.map(
              (s) => ListTile(
                title: Text(s.name.toUpperCase()),
                trailing: order.status == s
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus(context, ref, order.orderId, s);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(
    BuildContext context,
    WidgetRef ref,
    AppOrder order,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showCancelDialog(context, ref, order),
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('Cancel Order'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, AppOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(orderControllerProvider.notifier)
                  .cancelOrder(orderId: order.orderId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order cancelled successfully')),
                );
                context.pop();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
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
