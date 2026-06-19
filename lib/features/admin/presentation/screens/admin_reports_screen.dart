import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/domain/entities/dispute_ticket.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() =>
      _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final disputesAsync = ref.watch(adminAllDisputesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdminScaffold(
      title: 'Reports & Disputes',
      subtitle: 'Review and resolve buyer–seller disputes',
      body: Column(
        children: [
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in [
                    ('all', 'All'),
                    (TicketStatus.open.name, 'Open'),
                    (TicketStatus.underInvestigation.name,
                        'Under Investigation'),
                    (TicketStatus.resolved.name, 'Resolved'),
                    (TicketStatus.rejected.name, 'Rejected'),
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
          ),
          Expanded(
            child: disputesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: AdminEmptyRow(
                  icon: Icons.cloud_off_rounded,
                  message: e.toString(),
                ),
              ),
              data: (disputes) {
                final filtered = _statusFilter == 'all'
                    ? disputes
                    : disputes
                        .where((d) => d.status.name == _statusFilter)
                        .toList();

                if (filtered.isEmpty) {
                  return const AdminEmptyRow(
                    icon: Icons.gavel_outlined,
                    message: 'No disputes found.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _DisputeCard(ticket: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DisputeCard extends ConsumerWidget {
  final DisputeTicket ticket;
  const _DisputeCard({required this.ticket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('d MMM yyyy');
    final adminUser = ref.watch(authStateSignalingProvider).value;

    Color priorityColor;
    switch (ticket.priority) {
      case TicketPriority.critical:
        priorityColor = Colors.red.shade700;
        break;
      case TicketPriority.high:
        priorityColor = AppColors.error;
        break;
      case TicketPriority.medium:
        priorityColor = const Color(0xFFF59E0B);
        break;
      case TicketPriority.low:
        priorityColor = AppColors.success;
        break;
    }

    Color statusColor;
    switch (ticket.status) {
      case TicketStatus.open:
        statusColor = const Color(0xFFF59E0B);
        break;
      case TicketStatus.underInvestigation:
        statusColor = AppColors.primary;
        break;
      case TicketStatus.resolved:
        statusColor = AppColors.success;
        break;
      case TicketStatus.rejected:
        statusColor = AppColors.error;
        break;
    }

    return AdminSectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderSM,
                ),
                child: Icon(
                  Icons.gavel_rounded,
                  color: priorityColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.reason,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateFmt.format(ticket.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white38
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AdminStatusPill(
                    label: ticket.status.name
                        .replaceAll(RegExp(r'(?<=[a-z])(?=[A-Z])'), ' '),
                    color: statusColor,
                  ),
                  const SizedBox(height: 4),
                  AdminStatusPill(
                    label: ticket.priority.name,
                    color: priorityColor,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Order ID',
            value: ticket.transactionId.length > 12
                ? '${ticket.transactionId.substring(0, 12)}...'
                : ticket.transactionId,
          ),
          _InfoRow(label: 'Reporter ID', value: ticket.reporterId),
          _InfoRow(label: 'Store ID', value: ticket.reportedStoreId),
          if (ticket.assignedAgentId != null)
            _InfoRow(label: 'Agent', value: ticket.assignedAgentId!),
          const SizedBox(height: 12),
          if (ticket.status != TicketStatus.resolved)
            Row(
              children: [
                if (ticket.status == TicketStatus.open) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon:
                          const Icon(Icons.assignment_ind_outlined, size: 16),
                      label: const Text('Investigate'),
                      onPressed: () async {
                        if (adminUser == null) return;
                        final result = await ref
                            .read(adminControllerProvider.notifier)
                            .assignTicket(ticket.id, adminUser.uid);
                        result.fold(
                          (err) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(err)));
                            }
                          },
                          (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Ticket assigned')));
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Resolve'),
                    onPressed: () async {
                      final result = await ref
                          .read(adminControllerProvider.notifier)
                          .resolveTicket(ticket.id);
                      result.fold(
                        (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(err)));
                          }
                        },
                        (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Dispute resolved')));
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
