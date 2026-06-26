import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/data/services/admin_name_resolver.dart';
import 'package:ecom/features/admin/data/services/csv_export_helper.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:fl_chart/fl_chart.dart';
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
  bool _isExporting = false;

  Future<void> _exportAnalytics() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final firestore = ref.read(firebaseFirestoreProvider);

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

      final ordersSnapshot = await firestore
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .get();

      final platformConfig = ref.read(platformConfigProvider).asData?.value;
      final commissionRate = platformConfig?.defaultCommissionRate ?? 0.085;

      double totalRevenue = 0;
      final Map<String, double> sellerRevenue = {};
      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        totalRevenue += amount;
        final sellerId =
            data['sellerId'] as String? ?? data['storeId'] as String?;
        if (sellerId != null) {
          sellerRevenue[sellerId] = (sellerRevenue[sellerId] ?? 0) + amount;
        }
      }
      final platformRevenue = totalRevenue * commissionRate;
      final totalOrdersCount = ordersSnapshot.docs.length;
      final avgOrderValue = totalOrdersCount > 0
          ? totalRevenue / totalOrdersCount
          : 0.0;

      final statuses = [
        'pending',
        'processing',
        'shipped',
        'delivered',
        'cancelled',
      ];
      final Map<String, int> orderCounts = {};
      for (final status in statuses) {
        final snap = await firestore
            .collection('orders')
            .where('status', isEqualTo: status)
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .count()
            .get();
        orderCounts[status] = snap.count ?? 0;
      }

      final nameResolver = ref.read(adminNameResolverProvider.notifier);
      final sortedSellers = sellerRevenue.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final List<List<dynamic>> csvData = [
        ['Marketplace Analytics Export'],
        ['Time Range', _timeRange],
        ['Start Date', startDate.toIso8601String()],
        ['Export Date', DateTime.now().toIso8601String()],
        [],
        ['Financial Metrics'],
        ['Metric', 'Value'],
        ['Total Revenue', totalRevenue],
        ['Platform Commission Rate', commissionRate],
        ['Platform Revenue', platformRevenue],
        ['Completed Orders Count', totalOrdersCount],
        ['Average Order Value', avgOrderValue],
        [],
        ['Order Counts by Status (Selected Period)'],
        ['Status', 'Count'],
      ];

      for (final status in statuses) {
        csvData.add([status.toUpperCase(), orderCounts[status] ?? 0]);
      }

      csvData.addAll([
        [],
        ['Top Performing Sellers (Selected Period)'],
        ['Store ID', 'Store Name', 'Revenue'],
      ]);

      for (final entry in sortedSellers.take(10)) {
        final storeName = await nameResolver.resolveStoreName(entry.key);
        csvData.add([entry.key, storeName, entry.value]);
      }

      final productsSnapshot = await firestore
          .collection('catalog')
          .where('isActive', isEqualTo: true)
          .limit(200)
          .get();
      final Map<String, int> categoryCount = {};
      for (final doc in productsSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String? ?? 'Other';
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      csvData.addAll([
        [],
        ['Product Categories (Active Products count)'],
        ['Category', 'Active Products Count'],
      ]);

      categoryCount.forEach((cat, cnt) {
        csvData.add([cat, cnt]);
      });

      await CsvExportHelper.exportToCsv(
        fileName: 'marketplace_analytics_$_timeRange.csv',
        rows: csvData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analytics exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firebaseFirestoreProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
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
      actions: [
        _isExporting
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.download_rounded),
                tooltip: 'Export CSV',
                onPressed: _exportAnalytics,
              ),
      ],
      body: Column(
        children: [
          // Time Range Selector
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                const Text(
                  'Time Range:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                for (final range in ['7d', '30d', '90d'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        range == '7d'
                            ? '7 Days'
                            : range == '30d'
                            ? '30 Days'
                            : '90 Days',
                      ),
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

class _RevenueAnalytics extends ConsumerWidget {
  final FirebaseFirestore firestore;
  final DateTime startDate;
  final NumberFormat currencyFmt;

  const _RevenueAnalytics({
    required this.firestore,
    required this.startDate,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformConfigAsync = ref.watch(platformConfigProvider);
    final commissionRate =
        platformConfigAsync.asData?.value.defaultCommissionRate ?? 0.085;

    final daysCount = DateTime.now().difference(startDate).inDays + 1;
    final prevStartDate = startDate.subtract(Duration(days: daysCount));

    return FutureBuilder<QuerySnapshot>(
      future: firestore
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(prevStartDate),
          )
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];
        double totalRevenue = 0;
        double prevRevenue = 0;
        int orderCount = 0;
        int prevOrderCount = 0;

        // Group revenue by date (only for current period trend line)
        final Map<DateTime, double> chronologicalRevenue = {};
        for (int i = 0; i < daysCount; i++) {
          final date = DateUtils.dateOnly(startDate.add(Duration(days: i)));
          chronologicalRevenue[date] = 0;
        }

        for (final doc in orders) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
          final timestamp = data['createdAt'] as Timestamp?;
          if (timestamp != null) {
            final date = timestamp.toDate();
            if (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) {
              totalRevenue += amount;
              orderCount++;
              final dayDate = DateUtils.dateOnly(date);
              if (chronologicalRevenue.containsKey(dayDate)) {
                chronologicalRevenue[dayDate] =
                    (chronologicalRevenue[dayDate] ?? 0) + amount;
              }
            } else {
              prevRevenue += amount;
              prevOrderCount++;
            }
          }
        }

        final double platformRevenue = totalRevenue * commissionRate;
        final double prevPlatformRevenue = prevRevenue * commissionRate;

        final revenueDelta = prevRevenue > 0
            ? ((totalRevenue - prevRevenue) / prevRevenue * 100)
            : 0.0;
        final platformDelta = prevPlatformRevenue > 0
            ? ((platformRevenue - prevPlatformRevenue) /
                  prevPlatformRevenue *
                  100)
            : 0.0;
        final ordersDelta = prevOrderCount > 0
            ? ((orderCount - prevOrderCount) / prevOrderCount * 100)
            : 0.0;

        final avgOrderValue = orderCount > 0 ? totalRevenue / orderCount : 0.0;
        final prevAvgOrderValue = prevOrderCount > 0
            ? prevRevenue / prevOrderCount
            : 0.0;
        final avgValueDelta = prevAvgOrderValue > 0
            ? ((avgOrderValue - prevAvgOrderValue) / prevAvgOrderValue * 100)
            : 0.0;

        final chartPoints = <FlSpot>[];
        final datesList = chronologicalRevenue.keys.toList()..sort();
        for (int i = 0; i < datesList.length; i++) {
          final rev = chronologicalRevenue[datesList[i]] ?? 0;
          chartPoints.add(FlSpot(i.toDouble(), rev));
        }

        return AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (chartPoints.length > 1) ...[
                const Text(
                  'Revenue Trend',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartPoints,
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _RevenueRow(
                label: 'Total Revenue',
                value: currencyFmt.format(totalRevenue),
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                deltaPercentage: revenueDelta,
              ),
              const Divider(),
              _RevenueRow(
                label:
                    'Platform Revenue (${(commissionRate * 100).toStringAsFixed(1)}%)',
                value: currencyFmt.format(platformRevenue),
                icon: Icons.trending_up_rounded,
                color: AppColors.success,
                deltaPercentage: platformDelta,
              ),
              const Divider(),
              _RevenueRow(
                label: 'Total Orders',
                value: orderCount.toString(),
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF2563EB),
                deltaPercentage: ordersDelta,
              ),
              const Divider(),
              _RevenueRow(
                label: 'Average Order Value',
                value: currencyFmt.format(avgOrderValue),
                icon: Icons.analytics_outlined,
                color: const Color(0xFF7C3AED),
                deltaPercentage: avgValueDelta,
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
        final total = stats.values.fold(
          0,
          (accumulator, val) => accumulator + val,
        );

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
    final statuses = [
      'pending',
      'processing',
      'shipped',
      'delivered',
      'cancelled',
    ];
    final Map<String, int> stats = {};

    for (final status in statuses) {
      final snapshot = await firestore
          .collection('orders')
          .where('status', isEqualTo: status)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .count()
          .get();
      stats[status] = snapshot.count ?? 0;
    }

    return stats;
  }
}

class _TopSellers extends ConsumerWidget {
  final FirebaseFirestore firestore;
  final DateTime startDate;
  final NumberFormat currencyFmt;

  const _TopSellers({
    required this.firestore,
    required this.startDate,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<QuerySnapshot>(
      future: firestore
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
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
          final sellerId =
              data['sellerId'] as String? ?? data['storeId'] as String?;
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
                          FutureBuilder<String>(
                            future: ref
                                .read(adminNameResolverProvider.notifier)
                                .resolveStoreName(entry.key),
                            builder: (context, snapshot) {
                              final storeName = snapshot.data ?? 'Loading...';
                              return Text(
                                'Seller: $storeName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              );
                            },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

        final totalItems = sortedCategories.fold<int>(0, (s, e) => s + e.value);

        final colors = [
          AppColors.primary,
          const Color(0xFF10B981), // Emerald
          const Color(0xFF3B82F6), // Blue
          const Color(0xFFF59E0B), // Amber
          const Color(0xFF8B5CF6), // Purple
          const Color(0xFFEC4899), // Pink
        ];

        final pieSections = <PieChartSectionData>[];
        for (int i = 0; i < sortedCategories.length && i < 5; i++) {
          final entry = sortedCategories[i];
          final color = colors[i % colors.length];
          final double percentage = totalItems > 0
              ? (entry.value / totalItems * 100)
              : 0;
          pieSections.add(
            PieChartSectionData(
              color: color,
              value: entry.value.toDouble(),
              title: '${percentage.toStringAsFixed(0)}%',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        }

        return AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: pieSections,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Legend
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: List.generate(sortedCategories.take(5).length, (
                  index,
                ) {
                  final entry = sortedCategories[index];
                  final color = colors[index % colors.length];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${entry.key} (${entry.value})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white70
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
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
  final double? deltaPercentage;

  const _RevenueRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.deltaPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = (deltaPercentage ?? 0) >= 0;
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 16,
                ),
              ),
              if (deltaPercentage != null && deltaPercentage != 0.0) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 12,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${deltaPercentage!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'vs last period',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
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
    final percentage = total > 0
        ? (value / total * 100).toStringAsFixed(1)
        : '0.0';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 12)),
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
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
