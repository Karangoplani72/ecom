import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminSettlementsScreen extends ConsumerStatefulWidget {
  const AdminSettlementsScreen({super.key});

  @override
  ConsumerState<AdminSettlementsScreen> createState() =>
      _AdminSettlementsScreenState();
}

class _AdminSettlementsScreenState extends ConsumerState<AdminSettlementsScreen> {
  String _statusFilter = 'all';
  String _dateFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firebaseFirestoreProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('d MMM yyyy');

    // Query settlements
    Query settlementsQuery = firestore.collection('settlements').orderBy('createdAt', descending: true);
    
    if (_statusFilter != 'all') {
      settlementsQuery = settlementsQuery.where('status', isEqualTo: _statusFilter);
    }

    if (_dateFilter == 'week') {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      settlementsQuery = settlementsQuery.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo));
    } else if (_dateFilter == 'month') {
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));
      settlementsQuery = settlementsQuery.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo));
    }

    return AdminScaffold(
      title: 'Seller Settlements',
      subtitle: 'Manage seller payouts and settlements',
      body: Column(
        children: [
          // Filters
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in [
                        ('all', 'All'),
                        ('pending', 'Pending'),
                        ('processing', 'Processing'),
                        ('completed', 'Completed'),
                        ('failed', 'Failed'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f.$2),
                            selected: _statusFilter == f.$1,
                            onSelected: (_) => setState(() => _statusFilter = f.$1),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in [
                        ('all', 'All Time'),
                        ('week', 'Last 7 Days'),
                        ('month', 'Last 30 Days'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f.$2),
                            selected: _dateFilter == f.$1,
                            onSelected: (_) => setState(() => _dateFilter = f.$1),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Settlements List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: settlementsQuery.limit(100).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return AdminEmptyRow(icon: Icons.error_outline, message: snapshot.error.toString());
                }

                final settlements = snapshot.data?.docs ?? [];
                if (settlements.isEmpty) {
                  return const AdminEmptyRow(
                    icon: Icons.account_balance_wallet_outlined,
                    message: 'No settlements found',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: settlements.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _SettlementTile(
                    settlement: settlements[i].data() as Map<String, dynamic>,
                    docId: settlements[i].id,
                    currencyFmt: currencyFmt,
                    dateFmt: dateFmt,
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

class _SettlementTile extends ConsumerWidget {
  final Map<String, dynamic> settlement;
  final String docId;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;

  const _SettlementTile({
    required this.settlement,
    required this.docId,
    required this.currencyFmt,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = settlement['status'] as String? ?? 'pending';
    final amount = (settlement['amount'] as num?)?.toDouble() ?? 0;
    final sellerId = settlement['sellerId'] as String? ?? 'Unknown';

    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'processing':
        statusColor = const Color(0xFF2563EB);
        break;
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'failed':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = Colors.grey;
    }

    return AdminSectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settlement #${docId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              AdminStatusPill(label: status.toUpperCase(), color: statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 14,
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Seller: $sellerId',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                currencyFmt.format(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Created: ${settlement['createdAt'] != null ? dateFmt.format((settlement['createdAt'] as Timestamp).toDate()) : 'Unknown'}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (status == 'pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Process'),
                    onPressed: () => _processSettlement(context, ref, docId),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () => _rejectSettlement(context, ref, docId),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _processSettlement(BuildContext context, WidgetRef ref, String settlementId) async {
    final firestore = ref.read(firebaseFirestoreProvider);
    await firestore.collection('settlements').doc(settlementId).update({
      'status': 'processing',
      'processedAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settlement marked for processing')),
      );
    }
  }

  Future<void> _rejectSettlement(BuildContext context, WidgetRef ref, String settlementId) async {
    final firestore = ref.read(firebaseFirestoreProvider);
    await firestore.collection('settlements').doc(settlementId).update({
      'status': 'failed',
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settlement rejected')),
      );
    }
  }
}
