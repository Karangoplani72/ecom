import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final categoryRequestsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(firebaseFirestoreProvider)
      .collection('category_requests')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

class AdminCategoryRequestsScreen extends ConsumerWidget {
  const AdminCategoryRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(categoryRequestsStreamProvider);

    return AdminScaffold(
      title: 'Category Requests',
      subtitle: 'Review and moderate seller requests for new categories',
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AdminEmptyRow(
              icon: Icons.error_outline,
              message: error.toString(),
            ),
          ),
        ),
        data: (items) {
          final pending = items.where((i) => i['status'] == 'pending').toList();
          final approved = items.where((i) => i['status'] == 'approved').toList();
          final rejected = items.where((i) => i['status'] == 'rejected').toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              AdminMetricGrid(
                metrics: [
                  AdminMetricCard(
                    label: 'Pending Approval',
                    value: pending.length.toString(),
                    icon: Icons.hourglass_empty_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  AdminMetricCard(
                    label: 'Total Requests',
                    value: items.length.toString(),
                    icon: Icons.assignment_outlined,
                    color: const Color(0xFF2563EB),
                  ),
                  AdminMetricCard(
                    label: 'Approved',
                    value: approved.length.toString(),
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF16A34A),
                  ),
                  AdminMetricCard(
                    label: 'Rejected',
                    value: rejected.length.toString(),
                    icon: Icons.cancel_outlined,
                    color: const Color(0xFFDC2626),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Category Addition Requests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const AdminEmptyRow(
                  icon: Icons.inbox_outlined,
                  message: 'No category requests submitted yet.',
                )
              else
                ...items.map(
                  (req) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RequestCard(request: req),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> request;

  const _RequestCard({required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _isProcessing = false;

  Future<void> _approve() async {
    setState(() => _isProcessing = true);
    try {
      final firestore = ref.read(firebaseFirestoreProvider);
      final batch = firestore.batch();
      final reqId = widget.request['id'] as String;
      final name = widget.request['name'] as String;
      final desc = widget.request['description'] as String? ?? '';

      // 1. Update request status to approved
      batch.update(firestore.collection('category_requests').doc(reqId), {
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // 2. Add new category to categories collection
      batch.set(firestore.collection('categories').doc(name), {
        'createdAt': FieldValue.serverTimestamp(),
        'description': desc,
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category request approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _isProcessing = true);
    try {
      final firestore = ref.read(firebaseFirestoreProvider);
      final reqId = widget.request['id'] as String;

      await firestore.collection('category_requests').doc(reqId).update({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category request rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejection failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = widget.request['status'] as String? ?? 'pending';
    final name = widget.request['name'] as String? ?? '';
    final description = widget.request['description'] as String? ?? 'No description provided.';
    final sellerName = widget.request['sellerName'] as String? ?? 'Unknown Seller';
    final createdAtVal = widget.request['createdAt'];
    
    String dateStr = '';
    if (createdAtVal is Timestamp) {
      dateStr = DateFormat('yMMMd').add_jm().format(createdAtVal.toDate());
    }

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF16A34A);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = const Color(0xFFDC2626);
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.hourglass_full_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadius.borderLG,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.borderSM,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requested by: $sellerName',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
                if (status == 'pending')
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderMD,
                          ),
                        ),
                        onPressed: _isProcessing ? null : _approve,
                        child: _isProcessing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Approve', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFDC2626)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderMD,
                          ),
                        ),
                        onPressed: _isProcessing ? null : _reject,
                        child: const Text('Reject', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
