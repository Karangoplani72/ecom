import 'package:flutter/material.dart';
import 'package:ecom/core/theme/app_theme.dart';

class BuyerOrdersScreen extends StatelessWidget {
  const BuyerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeOrders = [
      {
        'id': 'ORD-89433',
        'storeName': "Nail Aesthetics Co.",
        'item': 'Luxury Gel Polish Set (6 Colors)',
        'status': 'Shipped',
        'deliveryDate': 'Arriving Thu, 18 Jun',
        'price': 1299.0,
      },
      {
        'id': 'ORD-89434',
        'storeName': "Beauty Supply Hub",
        'item': 'Professional UV/LED Nail Lamp',
        'status': 'Processing',
        'deliveryDate': 'Estimating Delivery...',
        'price': 2450.0,
      }
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          bottom: const TabBar(
            indicatorColor: AppTheme.blushPink,
            labelColor: AppTheme.charcoalText,
            unselectedLabelColor: AppTheme.slateGreyText,
            tabs: [Tab(text: 'Active Orders'), Tab(text: 'Order History')],
          ),
        ),
        body: TabBarView(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: activeOrders.length,
              itemBuilder: (context, index) {
                final order = activeOrders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Order #${order['id']}', style: const TextStyle(color: AppTheme.slateGreyText, fontSize: 13)),
                            Text(
                              order['status'] as String,
                              style: TextStyle(
                                color: order['status'] == 'Shipped' ? Colors.blue.shade700 : Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: AppTheme.creamBackground),
                        Row(
                          children: [
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(color: AppTheme.creamBackground, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.inventory_2_outlined, color: AppTheme.roseGold),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(order['item'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('Sold by: ${order['storeName']}', style: const TextStyle(color: AppTheme.slateGreyText, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.creamBackground.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_shipping_outlined, size: 18, color: AppTheme.charcoalText),
                                  const SizedBox(width: 8),
                                  Text(order['deliveryDate'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Text('₹${(order['price'] as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(onPressed: () {}, child: const Text('Track Package')),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
            const Center(child: Text('No past orders found.')),
          ],
        ),
      ),
    );
  }
}