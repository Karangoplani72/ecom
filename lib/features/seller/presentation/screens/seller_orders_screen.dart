import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_price_text.dart';
import 'package:ecom/core/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/seller_orders_controller.dart';

const _statusLabels = {
  'pending': 'Pending',
  'processing': 'Processing',
  'shipped': 'Shipped',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};

const _statusColors = {
  'pending': Colors.orange,
  'processing': Colors.blue,
  'shipped': Colors.purple,
  'delivered': Colors.green,
  'cancelled': Colors.redAccent,
};

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return AppScaffold(
      title: 'Orders',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip('all', 'All'),
                  ..._statusLabels.entries.map(
                    (e) => _filterChip(e.key, e.value),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ordersAsync.when(
              loading: () => const AppLoadingView(),

              error: (e, st) =>
                  AppErrorView(message: 'Failed to load orders: $e'),

              data: (orders) {
                var filteredOrders = orders;

                if (_filter != 'all') {
                  filteredOrders = orders
                      .where((o) => o.status == _filter)
                      .toList();
                }

                if (filteredOrders.isEmpty) {
                  return const AppEmptyView(
                    title: 'No orders yet',
                    subtitle:
                        'Orders placed against your store will show up here.',
                    icon: Icons.receipt_long_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];

                    final itemSummary = order.items.isEmpty
                        ? 'No items'
                        : order.items.map((e) => e.title).join(', ');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${order.id.substring(0, order.id.length < 8 ? order.id.length : 8)}',
                                  ),
                                  _StatusChip(status: order.status),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Text(
                                itemSummary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 4),

                              Text('Buyer: ${order.buyerName}'),

                              const SizedBox(height: 8),

                              Align(
                                alignment: Alignment.centerRight,
                                child: AppPriceText(amount: order.totalAmount),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _filter = value;
          });
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[status] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabels[status] ?? status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
