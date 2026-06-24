import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/seller_analytics_controller.dart';

class SellerAnalyticsScreen extends ConsumerWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(sellerAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/seller/dashboard'),
        ),
        title: const Text('Analytics'),
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (error, stackTrace) => Center(child: Text(error.toString())),

        data: (analytics) {
          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: MediaQuery.of(context).size.width > 900
                ? 5
                : MediaQuery.of(context).size.width > 600
                ? 4
                : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _AnalyticsCard(
                title: 'Revenue',
                value: '₹${analytics.totalRevenue.toStringAsFixed(2)}',
                icon: Icons.currency_rupee,
              ),

              _AnalyticsCard(
                title: 'Orders',
                value: analytics.totalOrders.toString(),
                icon: Icons.shopping_bag,
              ),

              _AnalyticsCard(
                title: 'Products',
                value: analytics.totalProducts.toString(),
                icon: Icons.inventory_2,
              ),

              _AnalyticsCard(
                title: 'Pending Orders',
                value: analytics.pendingOrders.toString(),
                icon: Icons.pending_actions,
              ),

              _AnalyticsCard(
                title: 'Active Products',
                value: analytics.activeProducts.toString(),
                icon: Icons.check_circle,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {}, // Add inkwell for better visual feedback
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 6),
              Expanded(
                flex: 2,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                flex: 1,
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
