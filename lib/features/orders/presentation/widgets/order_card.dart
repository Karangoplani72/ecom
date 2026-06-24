import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import 'package:ecom/core/widgets/cards/glass_card.dart';


class OrderCard extends StatelessWidget {
  final AppOrder order;
  final VoidCallback? onTap;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final bool showCustomerInfo;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onActionPressed,
    this.actionLabel,
    this.showCustomerInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          isDark: theme.brightness == Brightness.dark,
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderId.substring(0, 8).toUpperCase()}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 16),
            ...order.items
                .take(2)
                .map(
                  (item) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imageUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 40,
                                  height: 40,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    size: 20,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'x${item.quantity}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
            ),
            if (order.items.length > 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '+ ${order.items.length - 2} more items',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (showCustomerInfo) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.buyerName,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Placed on',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(order.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    if (onActionPressed != null && actionLabel != null)
                      TextButton(
                        onPressed: onActionPressed,
                        child: Text(actionLabel!),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
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
      case OrderStatus.returnRequested:
        return (Colors.orange, 'Return Requested');
      case OrderStatus.returnApproved:
        return (Colors.green, 'Return Approved');
      case OrderStatus.returnRejected:
        return (Colors.red, 'Return Rejected');
      case OrderStatus.refunded:
        return (Colors.blueGrey, 'Refunded');
    }
  }
}
