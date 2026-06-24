import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/utils/time_utils.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/orders/domain/entities/order_status.dart';
import 'package:ecom/features/seller/domain/entities/seller_dashboard_data.dart';
import 'package:ecom/features/seller/presentation/controllers/seller_dashboard_controller.dart';
import 'package:ecom/shared/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../widgets/seller_navigation.dart';

// ─────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────
class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(sellerDashboardControllerProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return SafeArea(
      child: dashboardAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.read(sellerDashboardControllerProvider.notifier).refresh(),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () =>
              ref.read(sellerDashboardControllerProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _DashboardHeader(
                  isDesktop: isDesktop,
                  isLoading: dashboardAsync.isRefreshing,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _MetricsGrid(data: data),
                    const SizedBox(height: 24),
                    const _QuickActions(),
                    const SizedBox(height: 24),
                    _RecentOrdersCard(orders: data.recentOrders),
                    const SizedBox(height: 24),
                    _LowStockCard(products: data.lowStockItems),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────
class _DashboardHeader extends ConsumerWidget {
  final bool isDesktop;
  final bool isLoading;

  const _DashboardHeader({required this.isDesktop, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = _getGreeting();
    final sellerName =
        ref.watch(authControllerProvider).value?.displayName ?? 'Seller';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () =>
                  sellerShellScaffoldKey.currentState?.openDrawer(),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecond
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sellerName,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              const SizedBox(width: 4),
              const NotificationBell(isStyledContainer: true),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getGreeting() {
    return '${getGreetingMessage()},';
  }
}

// ─────────────────────────────────────────────────────────────
// Metrics grid
// ─────────────────────────────────────────────────────────────
class _MetricsGrid extends StatelessWidget {
  final SellerDashboardData data;

  const _MetricsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final metrics = [
      _MetricConfig(
        label: 'Total Revenue',
        value: currFmt.format(data.totalRevenue.round()),
        icon: Icons.currency_rupee_rounded,
        iconColor: AppColors.success,
        bgColor: AppColors.success.withValues(alpha: 0.1),
      ),
      _MetricConfig(
        label: 'Total Orders',
        value: '${data.totalOrders}',
        icon: Icons.shopping_bag_outlined,
        iconColor: AppColors.primary,
        bgColor: AppColors.primary.withValues(alpha: 0.1),
      ),
      _MetricConfig(
        label: 'Products Listed',
        value: '${data.totalProducts}',
        icon: Icons.inventory_2_outlined,
        iconColor: AppColors.secondary,
        bgColor: AppColors.secondary.withValues(alpha: 0.1),
      ),
      _MetricConfig(
        label: 'Pending Orders',
        value: '${data.pendingOrders}',
        icon: Icons.pending_actions_outlined,
        iconColor: AppColors.warning,
        bgColor: AppColors.warning.withValues(alpha: 0.1),
      ),
    ];

    return LayoutBuilder(
      builder: (_, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 4 ? 1.55 : 1.6,
          ),
          itemCount: metrics.length,
          itemBuilder: (_, i) => _MetricCard(config: metrics[i]),
        );
      },
    );
  }
}

class _MetricConfig {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _MetricConfig({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricConfig config;

  const _MetricCard({required this.config});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecond
        : AppColors.lightTextSecond;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B33) : AppColors.lightCard,
        borderRadius: AppRadius.borderLG,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: isDark ? 20 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: config.bgColor,
                borderRadius: AppRadius.borderSM,
              ),
              child: Icon(config.icon, color: config.iconColor, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  config.label,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Quick actions
// ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      _ActionConfig(
        label: 'Add Product',
        icon: Icons.add_box_outlined,
        onTap: () => context.push('/seller/inventory/add'),
        isPrimary: true,
      ),
      _ActionConfig(
        label: 'View Orders',
        icon: Icons.receipt_long_outlined,
        onTap: () => context.go('/seller/orders'),
        isPrimary: false,
      ),
      _ActionConfig(
        label: 'Inventory',
        icon: Icons.inventory_2_outlined,
        onTap: () => context.go('/seller/inventory'),
        isPrimary: false,
      ),
      _ActionConfig(
        label: 'Analytics',
        icon: Icons.analytics_outlined,
        onTap: () => context.go('/seller/analytics'),
        isPrimary: false,
      ),
      _ActionConfig(
        label: 'Returns',
        icon: Icons.assignment_return_outlined,
        onTap: () => context.push('/seller/returns'),
        isPrimary: false,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions
              .map((a) => _QuickActionChip(config: a, isDark: isDark))
              .toList(),
        ),
      ],
    );
  }
}

class _ActionConfig {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionConfig({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isPrimary,
  });
}

class _QuickActionChip extends StatelessWidget {
  final _ActionConfig config;
  final bool isDark;

  const _QuickActionChip({required this.config, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (config.isPrimary) {
      return FilledButton.icon(
        onPressed: config.onTap,
        icon: Icon(config.icon, size: 18),
        label: Text(config.label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: config.onTap,
      icon: Icon(config.icon, size: 18),
      label: Text(config.label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Recent orders card
// ─────────────────────────────────────────────────────────────
class _RecentOrdersCard extends StatelessWidget {
  final List<DashboardOrderSummary> orders;

  const _RecentOrdersCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _SectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Orders',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () => context.go('/seller/orders'),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (orders.isEmpty)
            const _EmptyStateRow(
              icon: Icons.receipt_long_outlined,
              message: 'No orders yet — share your store link to get started.',
            )
          else
            ...orders.map((order) {
              final status = OrderStatus.values.firstWhere(
                (e) => e.name == order.status,
                orElse: () => OrderStatus.pending,
              );

              return _OrderRow(
                orderId: order.orderId,
                buyerName: 'Customer',
                // Would need real name from expanded query
                summary: 'Order #${order.orderId.substring(0, 8)}',
                amount: order.amount,
                dateStr: order.createdAt != null
                    ? DateFormat('d MMM, h:mm a').format(order.createdAt!)
                    : '',
                status: status,
                isDark: isDark,
              );
            }),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String orderId;
  final String buyerName;
  final String summary;
  final num amount;
  final String dateStr;
  final OrderStatus status;
  final bool isDark;

  const _OrderRow({
    required this.orderId,
    required this.buyerName,
    required this.summary,
    required this.amount,
    required this.dateStr,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = orderId.length >= 8 ? orderId.substring(0, 8) : orderId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderSM,
            ),
            child: Center(
              child: Text(
                buyerName.isNotEmpty ? buyerName[0].toUpperCase() : 'C',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      buyerName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '#$shortId',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecond
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecond
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              _StatusBadge(status: status),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  (Color, String) _getStatusConfig(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return (AppColors.warning, 'Pending');
      case OrderStatus.confirmed:
        return (AppColors.primary, 'Confirmed');
      case OrderStatus.packed:
        return (AppColors.secondary, 'Packed');
      case OrderStatus.shipped:
        return (const Color(0xFF7C3AED), 'Shipped');
      case OrderStatus.outForDelivery:
        return (Colors.teal, 'Out for Delivery');
      case OrderStatus.delivered:
        return (AppColors.success, 'Delivered');
      case OrderStatus.cancelled:
        return (AppColors.error, 'Cancelled');
      case OrderStatus.returnRequested:
        return (AppColors.warning, 'Return Requested');
      case OrderStatus.returnApproved:
        return (AppColors.success, 'Return Approved');
      case OrderStatus.returnRejected:
        return (AppColors.error, 'Return Rejected');
      case OrderStatus.refunded:
        return (Colors.grey, 'Refunded');
      case OrderStatus.returned:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Low stock card
// ─────────────────────────────────────────────────────────────
class _LowStockCard extends StatelessWidget {
  final List<DashboardProductSummary> products;

  const _LowStockCard({required this.products});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _SectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Low Stock Alert',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (products.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${products.length}',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              TextButton(
                onPressed: () => context.go('/seller/inventory'),
                child: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (products.isEmpty)
            const _EmptyStateRow(
              icon: Icons.check_circle_outline_rounded,
              message: 'All products are well-stocked.',
              iconColor: AppColors.success,
            )
          else
            ...products.take(5).map((p) {
              return _LowStockRow(
                title: p.title,
                stock: p.stock,
                imageUrl: null,
                // Expanded data would provide this
                productId: p.productId,
                isDark: isDark,
              );
            }),
        ],
      ),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  final String title;
  final int stock;
  final String? imageUrl;
  final String productId;
  final bool isDark;

  const _LowStockRow({
    required this.title,
    required this.stock,
    required this.imageUrl,
    required this.productId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = stock == 0;
    final stockColor = isOutOfStock ? AppColors.error : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.borderSM,
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const _PlaceholderImage(),
                  )
                : const _PlaceholderImage(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  isOutOfStock ? 'Out of stock' : '$stock units left',
                  style: TextStyle(
                    color: stockColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/seller/inventory/edit/$productId'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Restock',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: AppColors.border,
      child: const Icon(
        Icons.image_outlined,
        size: 20,
        color: AppColors.darkTextSecond,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _SectionCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B33) : AppColors.lightCard,
        borderRadius: AppRadius.borderLG,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: isDark ? 20 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyStateRow extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color? iconColor;

  const _EmptyStateRow({
    required this.icon,
    required this.message,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color:
                  iconColor ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecond.withValues(alpha: 0.5)
                      : AppColors.lightTextSecondary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecond
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
