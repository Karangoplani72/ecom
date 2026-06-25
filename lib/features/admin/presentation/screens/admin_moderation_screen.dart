import 'package:ecom/core/theme/app_colors.dart';
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
                  ),
                  AdminMetricCard(
                    label: 'Buyers',
                    value: numFmt.format(metrics.totalBuyers),
                    icon: Icons.shopping_bag_outlined,
                    color: const Color(0xFF7C3AED),
                  ),
                  AdminMetricCard(
                    label: 'Sellers',
                    value: numFmt.format(metrics.totalSellers),
                    icon: Icons.storefront_outlined,
                    color: const Color(0xFF16A34A),
                  ),
                  AdminMetricCard(
                    label: 'Pending Applications',
                    value: metrics.pendingApplications.toString(),
                    icon: Icons.hourglass_empty_rounded,
                    color: const Color(0xFFF59E0B),
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
                  ),
                  AdminMetricCard(
                    label: 'Active',
                    value: numFmt.format(metrics.activeProducts),
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF16A34A),
                  ),
                  AdminMetricCard(
                    label: 'Inactive',
                    value: numFmt.format(metrics.inactiveProducts),
                    icon: Icons.visibility_off_outlined,
                    color: const Color(0xFF6B7280),
                  ),
                  AdminMetricCard(
                    label: 'Out of Stock',
                    value: numFmt.format(metrics.outOfStockProducts),
                    icon: Icons.remove_shopping_cart_outlined,
                    color: const Color(0xFFDC2626),
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
                  ),
                  AdminMetricCard(
                    label: 'Pending',
                    value: numFmt.format(metrics.pendingOrders),
                    icon: Icons.pending_outlined,
                    color: const Color(0xFFF59E0B),
                  ),
                  AdminMetricCard(
                    label: 'Delivered',
                    value: numFmt.format(metrics.deliveredOrders),
                    icon: Icons.local_shipping_outlined,
                    color: const Color(0xFF16A34A),
                  ),
                  AdminMetricCard(
                    label: 'Cancelled',
                    value: numFmt.format(metrics.cancelledOrders),
                    icon: Icons.cancel_outlined,
                    color: const Color(0xFFDC2626),
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
                  ),
                  AdminMetricCard(
                    label: 'Open Disputes',
                    value: metrics.openDisputes.toString(),
                    icon: Icons.gavel_outlined,
                    color: const Color(0xFFF59E0B),
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
                  ),
                ],
              ),
              const SizedBox(height: 28),

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
        ],
      ),
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
