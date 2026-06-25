import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final _adminOrdersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref
      .watch(firebaseFirestoreProvider)
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String _search = '';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(_adminOrdersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('d MMM yyyy, h:mm a');

    return AdminScaffold(
      title: 'Orders',
      subtitle: 'View and manage all marketplace orders',
      body: Column(
        children: [
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by order ID or buyer...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderLG,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in [
                        ('all', 'All'),
                        ('pending', 'Pending'),
                        ('processing', 'Processing'),
                        ('shipped', 'Shipped'),
                        ('delivered', 'Delivered'),
                        ('cancelled', 'Cancelled'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f.$2),
                            selected: _statusFilter == f.$1,
                            onSelected: (_) =>
                                setState(() => _statusFilter = f.$1),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: AdminEmptyRow(
                  icon: Icons.cloud_off_rounded,
                  message: e.toString(),
                ),
              ),
              data: (orders) {
                final filtered = orders.where((o) {
                  final id = (o['id'] as String).toLowerCase();
                  final buyerId = (o['buyerId'] as String? ?? '').toLowerCase();
                  final matchesSearch =
                      _search.isEmpty ||
                      id.contains(_search.toLowerCase()) ||
                      buyerId.contains(_search.toLowerCase());

                  final matchesStatus =
                      _statusFilter == 'all' ||
                      (o['status'] as String? ?? '') == _statusFilter;

                  return matchesSearch && matchesStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return const AdminEmptyRow(
                    icon: Icons.receipt_long_outlined,
                    message: 'No orders match your filters.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => InkWell(
                    onTap: () =>
                        context.push('/admin/orders/${filtered[i]['id']}'),
                    child: _OrderTile(
                      order: filtered[i],
                      currencyFmt: currencyFmt,
                      dateFmt: dateFmt,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends ConsumerWidget {
  final Map<String, dynamic> order;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;

  const _OrderTile({
    required this.order,
    required this.currencyFmt,
    required this.dateFmt,
  });

  static const _statusColors = <String, Color>{
    'pending': Color(0xFFF59E0B),
    'processing': Color(0xFF2563EB),
    'shipped': Color(0xFF7C3AED),
    'delivered': AppColors.success,
    'cancelled': AppColors.error,
    'refunded': Color(0xFF6B7280),
  };

  static const _nextStatuses = <String, List<String>>{
    'pending': ['cancelled'],
    'processing': ['cancelled'],
    'shipped': ['cancelled'],
    'delivered': ['refunded'],
    'cancelled': ['refunded'],
    'returnApproved': ['refunded'],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = order['status'] as String? ?? 'pending';
    final total = (order['totalAmount'] as num?)?.toDouble() ?? 0;
    final buyerId = order['buyerId'] as String? ?? 'Unknown';
    final orderId = order['id'] as String;
    final shortId = orderId.length > 10
        ? orderId.substring(0, 10).toUpperCase()
        : orderId.toUpperCase();

    final statusColor = _statusColors[status] ?? AppColors.lightTextSecondary;
    final nextStatuses = _nextStatuses[status] ?? [];

    return AdminSectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#$shortId',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              AdminStatusPill(label: status.toUpperCase(), color: statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Buyer: $buyerId',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white54
                        : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                currencyFmt.format(total),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (nextStatuses.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: nextStatuses.map((next) {
                final nextColor =
                    _statusColors[next] ?? AppColors.lightTextSecondary;
                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: nextColor,
                    side: BorderSide(color: nextColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    await ref
                        .read(firebaseFirestoreProvider)
                        .collection('orders')
                        .doc(orderId)
                        .update({'status': next});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Order status updated to ${next.toUpperCase()}',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    '→ ${next.toUpperCase()}',
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
