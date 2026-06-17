// lib/features/admin/presentation/screens/admin_store_approvals_screen.dart
//
// Store Approvals (route: /admin/store-approvals)
// Queue of newly-applied / under-review seller stores awaiting a verification
// decision (see `VerificationStatus` in store_profile.dart: applied ->
// underReview -> verified | suspended). PLACEHOLDER: the list below is
// hardcoded sample data and the action buttons only show a confirmation
// snackbar — wire this up to a real `AdminStoreApprovalRepository` /
// use case before shipping.

import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _ApprovalStatus { applied, underReview }

class _PendingStore {
  final String id;
  final String storeName;
  final String ownerName;
  final String category;
  final DateTime appliedAt;
  final _ApprovalStatus status;

  const _PendingStore({
    required this.id,
    required this.storeName,
    required this.ownerName,
    required this.category,
    required this.appliedAt,
    required this.status,
  });
}

final List<_PendingStore> _sampleQueue = [
  _PendingStore(
    id: 'STR-1042',
    storeName: 'Aurora Home Decor',
    ownerName: 'Priya Sharma',
    category: 'Home & Living',
    appliedAt: DateTime.now().subtract(const Duration(hours: 4)),
    status: _ApprovalStatus.applied,
  ),
  _PendingStore(
    id: 'STR-1041',
    storeName: 'Northline Electronics',
    ownerName: 'Rahul Mehta',
    category: 'Electronics',
    appliedAt: DateTime.now().subtract(const Duration(hours: 9)),
    status: _ApprovalStatus.underReview,
  ),
  _PendingStore(
    id: 'STR-1039',
    storeName: 'Verde Organic Foods',
    ownerName: 'Ananya Iyer',
    category: 'Grocery',
    appliedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    status: _ApprovalStatus.underReview,
  ),
  _PendingStore(
    id: 'STR-1037',
    storeName: 'Studio Kalakar',
    ownerName: 'Vikram Desai',
    category: 'Art & Crafts',
    appliedAt: DateTime.now().subtract(const Duration(days: 2)),
    status: _ApprovalStatus.applied,
  ),
  _PendingStore(
    id: 'STR-1035',
    storeName: 'Pawsome Pet Supplies',
    ownerName: 'Neha Kapoor',
    category: 'Pet Care',
    appliedAt: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
    status: _ApprovalStatus.applied,
  ),
];

class AdminStoreApprovalsScreen extends StatefulWidget {
  const AdminStoreApprovalsScreen({super.key});

  @override
  State<AdminStoreApprovalsScreen> createState() =>
      _AdminStoreApprovalsScreenState();
}

class _AdminStoreApprovalsScreenState
    extends State<AdminStoreApprovalsScreen> {
  _ApprovalStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final filtered = _sampleQueue
        .where((s) => _filter == null || s.status == _filter)
        .toList();

    return AdminScaffold(
      title: 'Store Approvals',
      subtitle: 'Review and act on pending seller store applications',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const AdminSampleDataNotice(),
          const SizedBox(height: 20),
          const AdminMetricGrid(
            metrics: [
              AdminMetricCard(
                label: 'Pending Review',
                value: '5',
                icon: Icons.hourglass_empty_rounded,
                color: Color(0xFFF59E0B),
              ),
              AdminMetricCard(
                label: 'Approved This Week',
                value: '18',
                icon: Icons.check_circle_outline_rounded,
                color: Color(0xFF16A34A),
              ),
              AdminMetricCard(
                label: 'Rejected This Week',
                value: '2',
                icon: Icons.cancel_outlined,
                color: Color(0xFFDC2626),
              ),
              AdminMetricCard(
                label: 'Avg. Review Time',
                value: '1.4 days',
                icon: Icons.timer_outlined,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Queue',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _FilterChip(
                label: 'All',
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Applied',
                selected: _filter == _ApprovalStatus.applied,
                onTap: () => setState(() => _filter = _ApprovalStatus.applied),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Under Review',
                selected: _filter == _ApprovalStatus.underReview,
                onTap: () =>
                    setState(() => _filter = _ApprovalStatus.underReview),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const AdminEmptyRow(
              icon: Icons.inbox_outlined,
              message: 'No applications match this filter.',
            )
          else
            ...filtered.map(
              (store) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PendingStoreCard(store: store),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PendingStoreCard extends StatelessWidget {
  final _PendingStore store;

  const _PendingStoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final isUnderReview = store.status == _ApprovalStatus.underReview;
    final dateStr = DateFormat('d MMM, h:mm a').format(store.appliedAt);

    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.storeName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${store.ownerName} • ${store.category}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Applied $dateStr',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              AdminStatusPill(
                label: isUnderReview ? 'Under Review' : 'Applied',
                color: isUnderReview
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      showPlaceholderActionSnack(context, 'Review documents'),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Review'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      showPlaceholderActionSnack(context, 'Reject store'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      showPlaceholderActionSnack(context, 'Approve store'),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
