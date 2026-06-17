// lib/features/admin/presentation/screens/admin_reports_screen.dart
//
// Reports & Disputes (route: /admin/reports)
// Trust & safety queue for transaction disputes / abuse reports, modeled
// after `DisputeTicket` in domain/entities/dispute_ticket.dart (priority:
// low/medium/high/critical, status: open/underInvestigation/resolved/
// rejected). PLACEHOLDER: sample tickets only — wire to a real
// `AdminDisputeRepository` before launch.

import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _Priority { low, medium, high, critical }

enum _TicketStatus { open, underInvestigation, resolved, rejected }

class _Ticket {
  final String id;
  final String reason;
  final String reportedStore;
  final _Priority priority;
  final _TicketStatus status;
  final DateTime createdAt;

  const _Ticket({
    required this.id,
    required this.reason,
    required this.reportedStore,
    required this.priority,
    required this.status,
    required this.createdAt,
  });
}

final List<_Ticket> _sampleTickets = [
  _Ticket(
    id: 'TKT-3081',
    reason: 'Item received does not match listing description',
    reportedStore: 'QuickCart Essentials',
    priority: _Priority.high,
    status: _TicketStatus.open,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  _Ticket(
    id: 'TKT-3079',
    reason: 'Payment captured but order never shipped',
    reportedStore: 'Northline Electronics',
    priority: _Priority.critical,
    status: _TicketStatus.underInvestigation,
    createdAt: DateTime.now().subtract(const Duration(hours: 10)),
  ),
  _Ticket(
    id: 'TKT-3074',
    reason: 'Buyer alleges counterfeit product',
    reportedStore: 'Aurora Home Decor',
    priority: _Priority.high,
    status: _TicketStatus.underInvestigation,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  _Ticket(
    id: 'TKT-3068',
    reason: 'Refund delayed beyond policy window',
    reportedStore: 'Studio Kalakar',
    priority: _Priority.medium,
    status: _TicketStatus.resolved,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  _Ticket(
    id: 'TKT-3061',
    reason: 'Seller used abusive language in chat',
    reportedStore: 'Pawsome Pet Supplies',
    priority: _Priority.low,
    status: _TicketStatus.rejected,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  _TicketStatus? _filter;

  static const _priorityColor = {
    _Priority.low: Color(0xFF64748B),
    _Priority.medium: Color(0xFF2563EB),
    _Priority.high: Color(0xFFF59E0B),
    _Priority.critical: Color(0xFFDC2626),
  };

  static const _priorityLabel = {
    _Priority.low: 'Low',
    _Priority.medium: 'Medium',
    _Priority.high: 'High',
    _Priority.critical: 'Critical',
  };

  static const _statusColor = {
    _TicketStatus.open: Color(0xFFF59E0B),
    _TicketStatus.underInvestigation: Color(0xFF2563EB),
    _TicketStatus.resolved: Color(0xFF16A34A),
    _TicketStatus.rejected: Color(0xFF64748B),
  };

  static const _statusLabel = {
    _TicketStatus.open: 'Open',
    _TicketStatus.underInvestigation: 'Under Investigation',
    _TicketStatus.resolved: 'Resolved',
    _TicketStatus.rejected: 'Rejected',
  };

  @override
  Widget build(BuildContext context) {
    final filtered = _sampleTickets
        .where((t) => _filter == null || t.status == _filter)
        .toList();

    return AdminScaffold(
      title: 'Reports & Disputes',
      subtitle: 'Handle abuse reports and transaction disputes',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const AdminSampleDataNotice(),
          const SizedBox(height: 20),
          const AdminMetricGrid(
            metrics: [
              AdminMetricCard(
                label: 'Open Tickets',
                value: '14',
                icon: Icons.markunread_mailbox_outlined,
                color: Color(0xFFF59E0B),
              ),
              AdminMetricCard(
                label: 'High / Critical',
                value: '5',
                icon: Icons.priority_high_rounded,
                color: Color(0xFFDC2626),
              ),
              AdminMetricCard(
                label: 'Resolved This Week',
                value: '22',
                icon: Icons.task_alt_rounded,
                color: Color(0xFF16A34A),
              ),
              AdminMetricCard(
                label: 'Avg. Resolution',
                value: '1.8 days',
                icon: Icons.timer_outlined,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusFilterChip(
                label: 'All',
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              _StatusFilterChip(
                label: 'Open',
                selected: _filter == _TicketStatus.open,
                onTap: () => setState(() => _filter = _TicketStatus.open),
              ),
              _StatusFilterChip(
                label: 'Under Investigation',
                selected: _filter == _TicketStatus.underInvestigation,
                onTap: () =>
                    setState(() => _filter = _TicketStatus.underInvestigation),
              ),
              _StatusFilterChip(
                label: 'Resolved',
                selected: _filter == _TicketStatus.resolved,
                onTap: () => setState(() => _filter = _TicketStatus.resolved),
              ),
              _StatusFilterChip(
                label: 'Rejected',
                selected: _filter == _TicketStatus.rejected,
                onTap: () => setState(() => _filter = _TicketStatus.rejected),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            const AdminEmptyRow(
              icon: Icons.inbox_outlined,
              message: 'No tickets match this filter.',
            )
          else
            ...filtered.map((t) {
              final dateStr = DateFormat('d MMM, h:mm a').format(t.createdAt);
              final isActionable =
                  t.status == _TicketStatus.open ||
                  t.status == _TicketStatus.underInvestigation;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      t.id,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AdminStatusPill(
                                      label: _priorityLabel[t.priority]!,
                                      color: _priorityColor[t.priority]!,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(t.reason),
                                const SizedBox(height: 4),
                                Text(
                                  '${t.reportedStore} · $dateStr',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          AdminStatusPill(
                            label: _statusLabel[t.status]!,
                            color: _statusColor[t.status]!,
                          ),
                        ],
                      ),
                      if (isActionable) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => showPlaceholderActionSnack(
                                  context,
                                  'Assign to me',
                                ),
                                child: const Text('Assign to me'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => showPlaceholderActionSnack(
                                  context,
                                  'Resolve ticket',
                                ),
                                child: const Text('Resolve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusFilterChip({
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
