import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/features/orders/domain/entities/order.dart';
import 'package:ecom/features/orders/domain/entities/order_status.dart';
import 'package:ecom/features/orders/presentation/controllers/order_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class BuyerOrdersScreen extends ConsumerWidget {
  const BuyerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(buyerOrdersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('My Orders'),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: ordersAsync.when(
          loading: () => const AppLoadingView(),
          error: (error, _) => AppErrorView(message: error.toString()),
          data: (orders) {
            final activeOrders = orders
                .where(
                  (o) => !o.isCompleted && o.status != OrderStatus.cancelled,
                )
                .toList();
            final pastOrders = orders
                .where(
                  (o) => o.isCompleted || o.status == OrderStatus.cancelled,
                )
                .toList();

            return TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: () => ref.refresh(buyerOrdersProvider.future),
                  child: _OrdersList(
                    orders: activeOrders,
                    emptyTitle: 'No Active Orders',
                  ),
                ),
                RefreshIndicator(
                  onRefresh: () => ref.refresh(buyerOrdersProvider.future),
                  child: _OrdersList(
                    orders: pastOrders,
                    emptyTitle: 'No Order History',
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

class _OrdersList extends StatelessWidget {
  final List<AppOrder> orders;
  final String emptyTitle;

  const _OrdersList({required this.orders, required this.emptyTitle});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return AppEmptyView(
        title: emptyTitle,
        subtitle: 'Your orders will appear here once you place them.',
        icon: Icons.shopping_bag_outlined,
      );
    }

    return ResponsiveLayout(
      maxWidth: 800,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) => _OrderCard(order: orders[index]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final AppOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => context.push('/buyer/orders/${order.orderId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
            ...order.items.map(
              (item) => Padding(
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
                    Text('x${item.quantity}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
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
                Text(
                  '₹${order.totalAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
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
      case OrderStatus.refunded:
        return (Colors.grey, 'Refunded');
    }
  }
}
