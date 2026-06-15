import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecom/features/seller/presentation/controllers/seller_controller.dart';
import 'package:ecom/core/theme/app_theme.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real flow, this would watch the initialized seller profile.
    // For UI demonstration, we will assume a loaded state.
    final _ = ref.watch(sellerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Welcome Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, Anjali',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.blushPink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Here is what's happening at your studio today.",
                    style: TextStyle(color: AppTheme.slateGreyText, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // 2. Key Metrics Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildMetricCard(
                  context,
                  title: 'Today\'s Earnings',
                  value: '₹4,250',
                  icon: Icons.account_balance_wallet_outlined,
                  trend: '+12%',
                  isPositive: true,
                ),
                _buildMetricCard(
                  context,
                  title: 'Active Bookings',
                  value: '8',
                  icon: Icons.calendar_today_outlined,
                  trend: '2 pending',
                  isPositive: true,
                ),
                _buildMetricCard(
                  context,
                  title: 'Store Rating',
                  value: '4.9',
                  icon: Icons.star_border,
                  trend: 'Top 5%',
                  isPositive: true,
                ),
                _buildMetricCard(
                  context,
                  title: 'Profile Views',
                  value: '342',
                  icon: Icons.visibility_outlined,
                  trend: '-3%',
                  isPositive: false,
                ),
              ],
            ),
          ),

          // 3. Quick Actions Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add),
                          label: const Text('Add Service'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.local_offer_outlined),
                          label: const Text('Create Promo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. Recent Orders/Bookings List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Recent Bookings', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.champagneGold.withValues(alpha: 0.3),
                    child: const Icon(Icons.person_outline, color: AppTheme.charcoalText),
                  ),
                  title: const Text('Bridal Nail Art Package', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Today, 2:30 PM • Client: Priya M.'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.creamBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.champagneGold),
                    ),
                    child: const Text('Upcoming', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                );
              },
              childCount: 5,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required String trend,
    required bool isPositive,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.champagneGold.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppTheme.roseGold, size: 24),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green.shade700 : AppTheme.errorCoral,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.charcoalText),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: AppTheme.slateGreyText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}