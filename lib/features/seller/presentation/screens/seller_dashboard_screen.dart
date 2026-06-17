import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────
// Data model for dashboard snapshot
// ─────────────────────────────────────────────────────────────
class _DashboardData {
  final double totalRevenue;
  final int totalOrders;
  final int totalProducts;
  final int pendingOrders;
  final List<Map<String, dynamic>> recentOrders;
  final List<Map<String, dynamic>> lowStockProducts;

  const _DashboardData({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalProducts,
    required this.pendingOrders,
    required this.recentOrders,
    required this.lowStockProducts,
  });
}

// ─────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────
class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  late Future<_DashboardData> _dataFuture;
  final String? _sellerId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadDashboard();
  }

  Future<_DashboardData> _loadDashboard() async {
    if (_sellerId == null) {
      return const _DashboardData(
        totalRevenue: 0,
        totalOrders: 0,
        totalProducts: 0,
        pendingOrders: 0,
        recentOrders: [],
        lowStockProducts: [],
      );
    }

    final firestore = FirebaseFirestore.instance;

    // Parallel fetch for speed
    final results = await Future.wait([
      firestore
          .collection('orders')
          .where('storeId', isEqualTo: _sellerId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get(),
      firestore
          .collection('stores')
          .doc(_sellerId)
          .collection('products')
          .get(),
    ]);

    final ordersSnap = results[0];
    final productsSnap = results[1];

    double revenue = 0;
    int pending = 0;
    final recentOrders = <Map<String, dynamic>>[];

    for (final doc in ordersSnap.docs) {
      final d = doc.data();
      revenue += ((d['totalAmount'] as num?) ?? 0).toDouble();
      if (d['status'] == 'pending') pending++;
      if (recentOrders.length < 5) {
        recentOrders.add({...d, 'id': doc.id});
      }
    }

    final lowStock = <Map<String, dynamic>>[];
    for (final doc in productsSnap.docs) {
      final d = doc.data();
      final stock =
          ((d['metadata'] as Map<String, dynamic>?)?['stock'] as num?) ?? 0;
      if (stock <= 5) {
        lowStock.add({...d, 'id': doc.id});
      }
    }

    return _DashboardData(
      totalRevenue: revenue,
      totalOrders: ordersSnap.size,
      totalProducts: productsSnap.size,
      pendingOrders: pending,
      recentOrders: recentOrders,
      lowStockProducts: lowStock,
    );
  }

  void _refresh() => setState(() => _dataFuture = _loadDashboard());

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: isDesktop ? null : const _SellerDrawer(),
      body: Row(
        children: [
          if (isDesktop) const _SellerSidebar(),
          Expanded(
            child: SafeArea(
              child: FutureBuilder<_DashboardData>(
                future: _dataFuture,
                builder: (context, snapshot) {
                  return RefreshIndicator(
                    onRefresh: () async => _refresh(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _DashboardHeader(
                            isDesktop: isDesktop,
                            isLoading:
                                snapshot.connectionState ==
                                ConnectionState.waiting,
                          ),
                        ),
                        if (snapshot.hasError)
                          SliverFillRemaining(
                            child: _ErrorState(
                              message: snapshot.error.toString(),
                              onRetry: _refresh,
                            ),
                          )
                        else ...[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                _MetricsGrid(
                                  data: snapshot.data,
                                  isLoading:
                                      snapshot.connectionState ==
                                      ConnectionState.waiting,
                                ),
                                const SizedBox(height: 24),
                                _QuickActions(sellerId: _sellerId),
                                const SizedBox(height: 24),
                                _RecentOrdersCard(
                                  orders: snapshot.data?.recentOrders ?? [],
                                  isLoading:
                                      snapshot.connectionState ==
                                      ConnectionState.waiting,
                                ),
                                const SizedBox(height: 24),
                                _LowStockCard(
                                  products:
                                      snapshot.data?.lowStockProducts ?? [],
                                  isLoading:
                                      snapshot.connectionState ==
                                      ConnectionState.waiting,
                                ),
                                const SizedBox(height: 32),
                              ]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final bool isDesktop;
  final bool isLoading;

  const _DashboardHeader({required this.isDesktop, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final greeting = _greeting();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDesktop)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
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
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.displayName?.split(' ').first ?? 'Seller',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
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
              _NotificationBell(),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.borderMD,
      ),
      child: const Icon(Icons.notifications_outlined, size: 22),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Metrics grid
// ─────────────────────────────────────────────────────────────
class _MetricsGrid extends StatelessWidget {
  final _DashboardData? data;
  final bool isLoading;

  const _MetricsGrid({required this.data, required this.isLoading});

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
        value: isLoading
            ? '—'
            : currFmt.format(data?.totalRevenue.round() ?? 0),
        icon: Icons.currency_rupee_rounded,
        iconColor: AppColors.success,
        bgColor: AppColors.success.withValues(alpha: 0.1),
        trend: null,
      ),
      _MetricConfig(
        label: 'Total Orders',
        value: isLoading ? '—' : '${data?.totalOrders ?? 0}',
        icon: Icons.shopping_bag_outlined,
        iconColor: AppColors.primary,
        bgColor: AppColors.primary.withValues(alpha: 0.1),
        trend: null,
      ),
      _MetricConfig(
        label: 'Products Listed',
        value: isLoading ? '—' : '${data?.totalProducts ?? 0}',
        icon: Icons.inventory_2_outlined,
        iconColor: AppColors.secondary,
        bgColor: AppColors.secondary.withValues(alpha: 0.1),
        trend: null,
      ),
      _MetricConfig(
        label: 'Pending Orders',
        value: isLoading ? '—' : '${data?.pendingOrders ?? 0}',
        icon: Icons.pending_actions_outlined,
        iconColor: AppColors.warning,
        bgColor: AppColors.warning.withValues(alpha: 0.1),
        trend: null,
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
  final String? trend;

  const _MetricConfig({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.trend,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricConfig config;

  const _MetricCard({required this.config});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadius.borderLG,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  config.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
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
  final String? sellerId;

  const _QuickActions({this.sellerId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      _ActionConfig(
        label: 'Add Product',
        icon: Icons.add_box_outlined,
        onTap: () => context.go('/seller/inventory/add'),
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
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: actions
                .map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _QuickActionChip(config: a, isDark: isDark),
                  ),
                )
                .toList(),
          ),
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
  final List<Map<String, dynamic>> orders;
  final bool isLoading;

  const _RecentOrdersCard({required this.orders, required this.isLoading});

  static const _statusColors = {
    'pending': AppColors.warning,
    'processing': AppColors.primary,
    'shipped': Color(0xFF7C3AED),
    'delivered': AppColors.success,
    'cancelled': AppColors.error,
  };

  static const _statusLabels = {
    'pending': 'Pending',
    'processing': 'Processing',
    'shipped': 'Shipped',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

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
          if (isLoading)
            const _ShimmerList(count: 3)
          else if (orders.isEmpty)
            _EmptyStateRow(
              icon: Icons.receipt_long_outlined,
              message: 'No orders yet — share your store link to get started.',
            )
          else
            ...orders.map((order) {
              final status = (order['status'] as String?) ?? 'pending';
              final statusColor = _statusColors[status] ?? Colors.grey;
              final ts = order['createdAt'] as Timestamp?;
              final dateStr = ts != null
                  ? DateFormat('d MMM, h:mm a').format(ts.toDate())
                  : '';
              final items = List<Map<String, dynamic>>.from(
                ((order['items'] as List?) ?? []).map(
                  (e) => Map<String, dynamic>.from(e as Map),
                ),
              );
              final summary = items.isEmpty
                  ? 'No items'
                  : items.map((i) => i['title'] ?? '').join(', ');

              return _OrderRow(
                orderId: order['id'] as String,
                buyerName: (order['buyerName'] as String?) ?? 'Customer',
                summary: summary,
                amount: (order['totalAmount'] as num?) ?? 0,
                dateStr: dateStr,
                statusLabel: _statusLabels[status] ?? status,
                statusColor: statusColor,
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
  final String statusLabel;
  final Color statusColor;
  final bool isDark;

  const _OrderRow({
    required this.orderId,
    required this.buyerName,
    required this.summary,
    required this.amount,
    required this.dateStr,
    required this.statusLabel,
    required this.statusColor,
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightTextSecondary,
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
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Low stock card
// ─────────────────────────────────────────────────────────────
class _LowStockCard extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final bool isLoading;

  const _LowStockCard({required this.products, required this.isLoading});

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
                  if (!isLoading && products.isNotEmpty) ...[
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
          if (isLoading)
            const _ShimmerList(count: 2)
          else if (products.isEmpty)
            _EmptyStateRow(
              icon: Icons.check_circle_outline_rounded,
              message: 'All products are well-stocked.',
              iconColor: AppColors.success,
            )
          else
            ...products.take(5).map((p) {
              final meta = (p['metadata'] as Map<String, dynamic>?) ?? {};
              final stock = (meta['stock'] as num?) ?? 0;
              final imageUrls = (p['imageUrls'] as List?)?.cast<String>() ?? [];
              final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

              return _LowStockRow(
                title: (p['title'] as String?) ?? 'Untitled',
                stock: stock.toInt(),
                imageUrl: imageUrl,
                productId: p['id'] as String? ?? '',
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
                        _PlaceholderImage(),
                  )
                : _PlaceholderImage(),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: AppColors.border,
      child: const Icon(
        Icons.image_outlined,
        size: 20,
        color: AppColors.lightTextSecondary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sidebar (desktop) + Drawer (mobile)
// ─────────────────────────────────────────────────────────────
class _SellerSidebar extends StatelessWidget {
  const _SellerSidebar();

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 256,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.border,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.borderSM,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LuxeMarket',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Seller Portal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _SidebarSection(
            label: 'Overview',
            children: [
              _SidebarItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
                route: '/seller/dashboard',
                isActive: currentPath.startsWith('/seller/dashboard'),
              ),
              _SidebarItem(
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics_rounded,
                label: 'Analytics',
                route: '/seller/analytics',
                isActive: currentPath.startsWith('/seller/analytics'),
              ),
            ],
          ),
          _SidebarSection(
            label: 'Store',
            children: [
              _SidebarItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2_rounded,
                label: 'Inventory',
                route: '/seller/inventory',
                isActive: currentPath.startsWith('/seller/inventory'),
              ),
              _SidebarItem(
                icon: Icons.shopping_bag_outlined,
                activeIcon: Icons.shopping_bag_rounded,
                label: 'Orders',
                route: '/seller/orders',
                isActive: currentPath.startsWith('/seller/orders'),
              ),
              _SidebarItem(
                icon: Icons.people_outline_rounded,
                activeIcon: Icons.people_rounded,
                label: 'Customers',
                route: '/seller/customers',
                isActive: currentPath.startsWith('/seller/customers'),
              ),
            ],
          ),
          _SidebarSection(
            label: 'Finance',
            children: [
              _SidebarItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'Finances',
                route: '/seller/finances',
                isActive: currentPath.startsWith('/seller/finances'),
              ),
            ],
          ),
          _SidebarSection(
            label: 'Settings',
            children: [
              _SidebarItem(
                icon: Icons.store_outlined,
                activeIcon: Icons.store_rounded,
                label: 'Store Profile',
                route: '/seller/store-profile',
                isActive: currentPath.startsWith('/seller/store-profile'),
              ),
              _SidebarItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Settings',
                route: '/seller/settings',
                isActive: currentPath.startsWith('/seller/settings'),
              ),
            ],
          ),
          const Spacer(),
          const Divider(height: 1),
          _SidebarLogout(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _SidebarSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.lightTextSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isActive;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: AppRadius.borderMD,
        child: InkWell(
          borderRadius: AppRadius.borderMD,
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 20,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.lightTextSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarLogout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderMD,
        child: InkWell(
          borderRadius: AppRadius.borderMD,
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) context.go('/');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
                const SizedBox(width: 12),
                Text(
                  'Sign out',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SellerDrawer extends StatelessWidget {
  const _SellerDrawer();

  @override
  Widget build(BuildContext context) {
    return const Drawer(width: 280, child: _SellerSidebar());
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
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadius.borderLG,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
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
                  AppColors.lightTextSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  final int count;

  const _ShimmerList({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _ShimmerBox(width: 44, height: 44, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: double.infinity, height: 14, radius: 4),
                    const SizedBox(height: 6),
                    _ShimmerBox(width: 120, height: 12, radius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.8).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, state) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load dashboard',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
