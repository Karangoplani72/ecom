import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  String _timeRange = '7d'; // 7d, 30d, 90d

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firebaseFirestoreProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final numFmt = NumberFormat.compact(locale: 'en_IN');

    DateTime startDate;
    switch (_timeRange) {
      case '7d':
        startDate = DateTime.now().subtract(const Duration(days: 7));
        break;
      case '30d':
        startDate = DateTime.now().subtract(const Duration(days: 30));
        break;
      case '90d':
        startDate = DateTime.now().subtract(const Duration(days: 90));
        break;
      default:
        startDate = DateTime.now().subtract(const Duration(days: 7));
    }

    return AdminScaffold(
      title: 'Marketplace Analytics',
      subtitle: 'Detailed insights and trends',
      body: Column(
        children: [
          // Time Range Selector
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                const Text('Time Range:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                for (final range in ['7d', '30d', '90d'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(range == '7d' ? '7 Days' : range == '30d' ? '30 Days' : '90 Days'),
                      selected: _timeRange == range,
                      onSelected: (_) => setState(() => _timeRange = range),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Revenue Analytics
                _SectionHeader('Revenue Analytics'),
                _RevenueAnalytics(
                  firestore: firestore,
                  startDate: startDate,
                  currencyFmt: currencyFmt,
                ),
                const SizedBox(height: 24),

                // Order Analytics
                _SectionHeader('Order Analytics'),
                _OrderAnalytics(
                  firestore: firestore,
                  startDate: startDate,
                  numFmt: numFmt,
                ),
                const SizedBox(height: 24),

                // Seller Performance
                _SectionHeader('Top Performing Sellers'),
                _TopSellers(
                  firestore: firestore,
                  startDate: startDate,
                  currencyFmt: currencyFmt,
                ),
                const SizedBox(height: 24),

                // Product Analytics
                _SectionHeader('Product Analytics'),
                _ProductAnalytics(
                  firestore: firestore,
                  startDate: startDate,
                  numFmt: numFmt,
                ),
                const SizedBox(height: 24),

                // Category Performance
                _SectionHeader('Category Performance'),
                _CategoryPerformance(
                  firestore: firestore,
                  startDate: startDate,
                  numFmt: numFmt,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueAnalytics extends StatelessWidget {
  final FirebaseFirestore firestore;
  final DateTime startDate;
  final NumberFormat currencyFmt;

  const _RevenueAnalytics({
    required this.firestore,
    required this.startDate,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: firestore
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];
        double totalRevenue = 0;
        double platformRevenue = 0;
        int orderCount = orders.length;

        for (final doc in orders) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
          totalRevenue += amount;
          // Assuming 8.5% commission
          platformRevenue += amount * 0.085;
        }

        final avgOrderValue = orderCount > 0 ? totalRevenue / orderCount : 0;

        return AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _RevenueRow(
                label: 'Total Revenue',
                value: currencyFmt.format(totalRevenue),
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
              ),
              const Divider(),
              _RevenueRow(
                label: 'Platform Revenue (8.5%)',
                value: currencyFmt.format(platformRevenue),
                icon: Icons.trending_up_rounded,
                color: AppColors.success,
              ),
              const Divider(),
              _RevenueRow(
                label: 'Total Orders',
                value: orderCount.toString(),
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF2563EB),
              ),
              const Divider(),
              _RevenueRow(
                label: 'Average Order Value',
                value: currencyFmt.format(avgOrderValue),
                icon: Icons.analytics_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderAnalytics extends StatelessWidget {
  final FirebaseFirestore firestore;
  final DateTime startDate;
  final NumberFormat numFmt;

  const _OrderAnalytics({
    required this.firestore,
    required this.startDate,
    required this.numFmt,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchOrderStats(firestore, startDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? {};
        final total = stats.values.fold(0, (accumulator, val) => accumulator + val);

        return AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _StatRow(
                label: 'Total Orders',
                value: numFmt.format(total),
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              _OrderStatusRow(
                label: 'Pending',
                value: stats['pending'] ?? 0,
                color: const Color(0xFFF59E0B),
                total: total,
              ),
              _OrderStatusRow(
                label: 'Processing',
                value: stats['processing'] ?? 0,
                color: const Color(0xFF2563EB),
                total: total,
              ),
              _OrderStatusRow(
                label: 'Shipped',
                value: stats['shipped'] ?? 0,
                color: const Color(0xFF7C3AED),
                total: total,
              ),
              _OrderStatusRow(
                label: 'Delivered',
                value: stats['delivered'] ?? 0,
                color: AppColors.success,
                total: total,
              ),
              _OrderStatusRow(
                label: 'Cancelled',
                value: stats['cancelled'] ?? 0,
                color: AppColors.error,
                total: total,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _fetchOrderStats(
    FirebaseFirestore firestore,
    DateTime startDate,
  ) async {
    final statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
    final Map<String, int> stats = {};

    for (final status in statuses) {
      final snapshot = await firestore
          .collection('orders')
          .where('status', isEqualTo: status)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .count()
          .get();
      stats[status] = snapshot.count ?? 0;
    }

    return stats;
  }
}

class _TopSellers extends StatelessWidget {
  final FirebaseFirestore firestore;
  final DateTime startDate;
  final NumberFormat currencyFmt;

  const _TopSellers({
    required this.firestore,
    required this.startDate,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: firestore
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('totalAmount', descending: true)
          .limit(10)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];
        final Map<String, double> sellerRevenue = {};

        for (final doc in orders) {
          final data = doc.data() as Map<String, dynamic>;
          final sellerId = data['sellerId'] as String? ?? data['storeId'] as String?;
          if (sellerId != null) {
            final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
            sellerRevenue[sellerId] = (sellerRevenue[sellerId] ?? 0) + amount;
          }
        }

        final sortedSellers = sellerRevenue.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (sortedSellers.isEmpty) {
          return const AdminEmptyRow(
            icon: Icons.storefront_outlined,
            message: 'No seller data available for this period',
          );
        }

        return Column(
          children: sortedSellers.take(5).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AdminSectionCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        entry.key.substring(0, 2).toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seller: ${entry.key.substring(0, 12)}...',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            currencyFmt.format(entry.value),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ProductAnalytics extends StatelessWidget {
  final FirebaseFirestore firestore;
  final DateTime startDate;
  final NumberFormat numFmt;

  const _ProductAnalytics({
    required this.firestore,
    required this.startDate,
    required this.numFmt,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchProductStats(firestore, startDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? {};

        return AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Total Products',
                value: numFmt.format(stats['total'] ?? 0),
                icon: Icons.inventory_2_outlined,
                color: AppColors.primary,
              ),
              _StatItem(
                label: 'Active',
                value: numFmt.format(stats['active'] ?? 0),
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
              ),
              _StatItem(
                label: 'Out of Stock',
                value: numFmt.format(stats['outOfStock'] ?? 0),
                icon: Icons.remove_shopping_cart_outlined,
                color: AppColors.error,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _fetchProductStats(
    FirebaseFirestore firestore,
    DateTime startDate,
  ) async {
    final totalSnapshot = await firestore.collection('catalog').count().get();
    final activeSnapshot = await firestore
        .collection('catalog')
        .where('isActive', isEqualTo: true)
        .count()
        .get();
    final outOfStockSnapshot = await firestore
        .collection('catalog')
        .where('stockQuantity', isEqualTo: 0)
        .count()
        .get();

    return {
      'total': totalSnapshot.count ?? 0,
      'active': activeSnapshot.count ?? 0,
      'outOfStock': outOfStockSnapshot.count ?? 0,
    };
  }
}

class _CategoryPerformance extends StatelessWidget {
  final FirebaseFirestore firestore;
  final DateTime startDate;
  final NumberFormat numFmt;

  const _CategoryPerformance({
    required this.firestore,
    required this.startDate,
    required this.numFmt,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: firestore
          .collection('catalog')
          .where('isActive', isEqualTo: true)
          .limit(100)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data?.docs ?? [];
        final Map<String, int> categoryCount = {};

        for (final doc in products) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category'] as String? ?? 'Other';
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }

        final sortedCategories = categoryCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (sortedCategories.isEmpty) {
          return const AdminEmptyRow(
            icon: Icons.category_outlined,
            message: 'No category data available',
          );
        }

        return Column(
          children: sortedCategories.take(5).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AdminSectionCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: entry.value / (sortedCategories.first.value),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      numFmt.format(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _RevenueRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _OrderStatusRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final int total;

  const _OrderStatusRow({
    required this.label,
    required this.value,
    required this.color,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: total > 0 ? value / total : 0,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$percentage%',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
