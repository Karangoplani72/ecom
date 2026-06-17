import 'package:flutter/material.dart';

import 'package:ecom/core/widgets/app_empty_view.dart';

class BuyerOrdersScreen extends StatelessWidget {
  const BuyerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeOrders = [
      {
        'id': 'ORD-89433',
        'storeName': 'Nail Aesthetics Co.',
        'item': 'Luxury Gel Polish Set (6 Colors)',
        'status': 'Shipped',
        'deliveryDate': 'Arriving Thu, 18 Jun',
        'price': 1299.0,
      },
      {
        'id': 'ORD-89434',
        'storeName': 'Beauty Supply Hub',
        'item': 'Professional UV/LED Nail Lamp',
        'status': 'Processing',
        'deliveryDate': 'Estimating Delivery...',
        'price': 2450.0,
      },
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Active Orders'),
              Tab(text: 'Order History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeOrders.length,
              itemBuilder: (context, index) {
                final order = activeOrders[index];

                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;

                final statusColor =
                order['status'] == 'Shipped'
                    ? Colors.green
                    : Colors.orange;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${order['id']}',
                              style: theme.textTheme.bodySmall,
                            ),
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Text(
                                order['status'] as String,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Divider(
                          color: colorScheme.outline
                              .withValues(alpha: 0.2),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: colorScheme.primary
                                    .withValues(alpha: 0.08),
                                borderRadius:
                                BorderRadius.circular(
                                  12,
                                ),
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color:
                                colorScheme.primary,
                              ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  Text(
                                    order['item']
                                    as String,
                                    style: theme
                                        .textTheme
                                        .titleMedium,
                                  ),

                                  const SizedBox(
                                      height: 6),

                                  Text(
                                    'Sold by ${order['storeName']}',
                                    style: theme
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Container(
                          padding:
                          const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary
                                .withValues(alpha: 0.05),
                            borderRadius:
                            BorderRadius.circular(
                              12,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons
                                        .local_shipping_outlined,
                                    size: 18,
                                    color: colorScheme
                                        .primary,
                                  ),
                                  const SizedBox(
                                      width: 8),
                                  Text(
                                    order['deliveryDate']
                                    as String,
                                    style: theme
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                              Text(
                                '₹${(order['price'] as double).toStringAsFixed(2)}',
                                style: theme
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {},
                            child: const Text(
                              'Track Package',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const AppEmptyView(
              title: 'No Order History',
              subtitle:
              'Completed orders will appear here.',
              icon: Icons.history,
            ),
          ],
        ),
      ),
    );
  }
}