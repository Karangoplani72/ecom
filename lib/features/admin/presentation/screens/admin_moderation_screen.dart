import 'package:ecom/features/admin/domain/entities/audit_log.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AdminModerationScreen extends ConsumerWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminDashboardMetricsProvider);
    final currencyFmt =
        NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹', decimalDigits: 1);
    final numFmt = NumberFormat.compact(locale: 'en_IN');

    return AdminScaffold(
      title: 'Admin Dashboard',
      subtitle: 'Platform-wide overview',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh metrics',
          onPressed: () => ref.invalidate(adminDashboardMetricsProvider),
        ),
      ],
      body: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: AdminEmptyRow(
            icon: Icons.cloud_off_rounded,
            message: 'Failed to load metrics\n${e.toString()}',
          ),
        ),
        data: (metrics) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              // ── Revenue highlight ──────────────────────────────────────
              _RevenueCard(
                totalRevenue: metrics.totalRevenue,
                platformRevenue: metrics.platformRevenue,
                currencyFmt: currencyFmt,
              ),
              const SizedBox(height: 20),

              // ── Users ──────────────────────────────────────────────────
              _SectionLabel('People'),
              const SizedBox(height: 10),
              AdminMetricGrid(
                metrics: [
                  AdminMetricCard(
                    label: 'Total Users',
                    value: numFmt.format(metrics.totalUsers),
                    icon: Icons.people_outline_rounded,
                    color: const Color(0xFF2563EB),
                    onTap: () => context.push('/admin/users'),
                  ),
                  AdminMetricCard(
                    label: 'Buyers',
                    value: numFmt.format(metrics.totalBuyers),
                    icon: Icons.shopping_bag_outlined,
                    color: const Color(0xFF7C3AED),
                    onTap: () => context.push('/admin/users'),
                  ),
                  AdminMetricCard(
                    label: 'Sellers',
                    value: numFmt.format(metrics.totalSellers),
                    icon: Icons.storefront_outlined,
                    color: const Color(0xFF16A34A),
                    onTap: () => context.push('/admin/stores'),
                  ),
                  AdminMetricCard(
                    label: 'Pending Applications',
                    value: metrics.pendingApplications.toString(),
                    icon: Icons.hourglass_empty_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () => context.push('/admin/store-approvals'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Products ───────────────────────────────────────────────
              _SectionLabel('Catalog'),
              const SizedBox(height: 10),
              AdminMetricGrid(
                metrics: [
                  AdminMetricCard(
                    label: 'Total Products',
                    value: numFmt.format(metrics.totalProducts),
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF0891B2),
                    onTap: () => context.push('/admin/products'),
                  ),
                  AdminMetricCard(
                    label: 'Active',
                    value: numFmt.format(metrics.activeProducts),
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF16A34A),
                    onTap: () => context.push('/admin/products'),
                  ),
                  AdminMetricCard(
                    label: 'Inactive',
                    value: numFmt.format(metrics.inactiveProducts),
                    icon: Icons.visibility_off_outlined,
                    color: const Color(0xFF6B7280),
                    onTap: () => context.push('/admin/products'),
                  ),
                  AdminMetricCard(
                    label: 'Out of Stock',
                    value: numFmt.format(metrics.outOfStockProducts),
                    icon: Icons.remove_shopping_cart_outlined,
                    color: const Color(0xFFDC2626),
                    onTap: () => context.push('/admin/products'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Orders ─────────────────────────────────────────────────
              _SectionLabel('Orders'),
              const SizedBox(height: 10),
              AdminMetricGrid(
                metrics: [
                  AdminMetricCard(
                    label: 'Total Orders',
                    value: numFmt.format(metrics.totalOrders),
                    icon: Icons.receipt_long_outlined,
                    color: const Color(0xFF2563EB),
                    onTap: () => context.push('/admin/orders'),
                  ),
                  AdminMetricCard(
                    label: 'Pending',
                    value: numFmt.format(metrics.pendingOrders),
                    icon: Icons.pending_outlined,
                    color: const Color(0xFFF59E0B),
                    onTap: () => context.push('/admin/orders'),
                  ),
                  AdminMetricCard(
                    label: 'Delivered',
                    value: numFmt.format(metrics.deliveredOrders),
                    icon: Icons.local_shipping_outlined,
                    color: const Color(0xFF16A34A),
                    onTap: () => context.push('/admin/orders'),
                  ),
                  AdminMetricCard(
                    label: 'Cancelled',
                    value: numFmt.format(metrics.cancelledOrders),
                    icon: Icons.cancel_outlined,
                    color: const Color(0xFFDC2626),
                    onTap: () => context.push('/admin/orders'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Trust & Safety ────────────────────────────────────────
              _SectionLabel('Trust & Safety'),
              const SizedBox(height: 10),
              AdminMetricGrid(
                metrics: [
                  AdminMetricCard(
                    label: 'Total Disputes',
                    value: metrics.totalDisputes.toString(),
                    icon: Icons.report_problem_outlined,
                    color: const Color(0xFFDC2626),
                    onTap: () => context.push('/admin/reports'),
                  ),
                  AdminMetricCard(
                    label: 'Open Disputes',
                    value: metrics.openDisputes.toString(),
                    icon: Icons.gavel_outlined,
                    color: const Color(0xFFF59E0B),
                    onTap: () => context.push('/admin/reports'),
                  ),
                  AdminMetricCard(
                    label: 'Active Chats',
                    value: metrics.totalChats.toString(),
                    icon: Icons.chat_bubble_outline_rounded,
                    color: const Color(0xFF7C3AED),
                  ),
                  AdminMetricCard(
                    label: 'Verified Stores',
                    value: metrics.approvedSellers.toString(),
                    icon: Icons.verified_outlined,
                    color: const Color(0xFF16A34A),
                    onTap: () => context.push('/admin/stores'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Recent Activity Timeline ──────────────────────────────
              _SectionLabel('Recent System Activity'),
              const SizedBox(height: 10),
              Consumer(
                builder: (context, ref, _) {
                  final auditLogsAsync = ref.watch(adminAuditLogsProvider);
                  return auditLogsAsync.when(
                    data: (logs) {
                      final recent = logs.take(5).toList();
                      if (recent.isEmpty) {
                        return const AdminSectionCard(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No recent activity'),
                            ),
                          ),
                        );
                      }
                      return AdminSectionCard(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Column(
                          children: [
                            for (int i = 0; i < recent.length; i++) ...[
                              _ActivityTimelineTile(log: recent[i]),
                              if (i != recent.length - 1) const Divider(),
                            ],
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error loading activity: $e', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Quick navigation ───────────────────────────────────────
              _SectionLabel('Management'),
              const SizedBox(height: 12),
              _QuickNavTile(
                title: 'Store Approvals',
                subtitle: '${metrics.pendingApplications} pending review',
                icon: Icons.fact_check_outlined,
                badge: metrics.pendingApplications,
                onTap: () => context.push('/admin/store-approvals'),
              ),
              _QuickNavTile(
                title: 'Stores',
                subtitle: 'Browse and manage all stores',
                icon: Icons.storefront_outlined,
                onTap: () => context.push('/admin/stores'),
              ),
              _QuickNavTile(
                title: 'Users & Roles',
                subtitle: '${numFmt.format(metrics.totalUsers)} registered users',
                icon: Icons.people_outline_rounded,
                onTap: () => context.push('/admin/users'),
              ),
              _QuickNavTile(
                title: 'Products',
                subtitle: '${numFmt.format(metrics.totalProducts)} products in catalog',
                icon: Icons.inventory_2_outlined,
                onTap: () => context.push('/admin/products'),
              ),
              _QuickNavTile(
                title: 'Orders',
                subtitle: '${numFmt.format(metrics.totalOrders)} orders placed',
                icon: Icons.receipt_long_outlined,
                onTap: () => context.push('/admin/orders'),
              ),
              _QuickNavTile(
                title: 'Reports & Disputes',
                subtitle: '${metrics.openDisputes} open disputes',
                icon: Icons.report_problem_outlined,
                badge: metrics.openDisputes,
                onTap: () => context.push('/admin/reports'),
              ),
              _QuickNavTile(
                title: 'Settlements',
                subtitle: 'Manage seller payouts and finances',
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => context.push('/admin/settlements'),
              ),
              _QuickNavTile(
                title: 'Analytics',
                subtitle: 'Marketplace insights and trends',
                icon: Icons.analytics_outlined,
                onTap: () => context.push('/admin/analytics'),
              ),
              _QuickNavTile(
                title: 'Platform Settings',
                subtitle: 'Commission rates, maintenance mode, theme',
                icon: Icons.settings_outlined,
                onTap: () => context.push('/admin/settings'),
              ),
              _QuickNavTile(
                title: 'System Audit Logs',
                subtitle: 'View tracking and action logs',
                icon: Icons.history_edu_outlined,
                onTap: () => context.push('/admin/audit-logs'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final double totalRevenue;
  final double platformRevenue;
  final NumberFormat currencyFmt;

  const _RevenueCard({
    required this.totalRevenue,
    required this.platformRevenue,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: isDark ? 0.4 : 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Platform Revenue',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currencyFmt.format(platformRevenue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'from ${currencyFmt.format(totalRevenue)} GMV',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, _) {
              final firestore = ref.watch(firebaseFirestoreProvider);
              return _RevenueSparkline(
                firestore: firestore,
                lineColor: Colors.white.withValues(alpha: 0.8),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RevenueSparkline extends StatelessWidget {
  final FirebaseFirestore firestore;
  final Color lineColor;

  const _RevenueSparkline({required this.firestore, required this.lineColor});

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime.now().subtract(const Duration(days: 7));
    return FutureBuilder<QuerySnapshot>(
      future: firestore
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final Map<DateTime, double> dailyRevenue = {};
        for (int i = 0; i < 7; i++) {
          final date = DateUtils.dateOnly(startDate.add(Duration(days: i)));
          dailyRevenue[date] = 0;
        }

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
          final timestamp = data['createdAt'] as Timestamp?;
          if (timestamp != null) {
            final date = DateUtils.dateOnly(timestamp.toDate());
            if (dailyRevenue.containsKey(date)) {
              dailyRevenue[date] = (dailyRevenue[date] ?? 0) + amount;
            }
          }
        }

        final chartPoints = <FlSpot>[];
        final dates = dailyRevenue.keys.toList()..sort();
        for (int i = 0; i < dates.length; i++) {
          chartPoints.add(FlSpot(i.toDouble(), dailyRevenue[dates[i]] ?? 0));
        }

        if (chartPoints.length < 2) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 45,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: chartPoints,
                  isCurved: true,
                  color: lineColor,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _QuickNavTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  const _QuickNavTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AdminSectionCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _ActivityTimelineTile extends StatelessWidget {
  final AuditLog log;

  const _ActivityTimelineTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_toggle_off_rounded,
              color: AppColors.primary,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.action.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'By ${log.userEmail} on ${log.targetType} (${log.targetId})',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('h:mm a').format(log.createdAt),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
