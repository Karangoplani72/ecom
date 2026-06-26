import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:ecom/features/admin/data/services/csv_export_helper.dart';
import 'package:ecom/features/admin/domain/entities/audit_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminAuditLogsScreen extends ConsumerStatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  ConsumerState<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends ConsumerState<AdminAuditLogsScreen> {
  String _search = '';
  String _actionFilter = 'all';
  int _pageSize = 50;
  DateTimeRange? _dateRange;
  bool _isExporting = false;

  Future<void> _exportLogs(List<AuditLog> logs) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final rows = <List<dynamic>>[
        ['Audit Logs Export'],
        ['Export Date', DateTime.now().toIso8601String()],
        [],
        ['Timestamp', 'Action', 'User Email', 'Target Type', 'Target ID', 'Metadata'],
      ];

      for (final log in logs) {
        rows.add([
          log.createdAt.toIso8601String(),
          log.action,
          log.userEmail,
          log.targetType,
          log.targetId,
          log.metadata.toString(),
        ]);
      }

      await CsvExportHelper.exportToCsv(
        fileName: 'audit_logs_export.csv',
        rows: rows,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit logs exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auditLogsAsync = ref.watch(adminAuditLogsProvider);

    return AdminScaffold(
      title: 'Audit Logs',
      subtitle: 'Track system administration actions and edits',
      actions: [
        auditLogsAsync.maybeWhen(
          data: (logs) {
            return _isExporting
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.download_rounded),
                    tooltip: 'Export CSV',
                    onPressed: () => _exportLogs(logs),
                  );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
      body: Column(
        children: [
          // Filters card
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by action, user email or target ID...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.borderLG,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (v) => setState(() {
                          _search = v;
                          _pageSize = 50;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range_rounded),
                      label: Text(_dateRange == null
                          ? 'Date Range'
                          : '${DateFormat('MM/dd').format(_dateRange!.start)} - ${DateFormat('MM/dd').format(_dateRange!.end)}'),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                          initialDateRange: _dateRange,
                        );
                        if (picked != null) {
                          setState(() {
                            _dateRange = picked;
                            _pageSize = 50;
                          });
                        }
                      },
                    ),
                    if (_dateRange != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() {
                          _dateRange = null;
                          _pageSize = 50;
                        }),
                        tooltip: 'Clear Date Filter',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in [
                        ('all', 'All Actions'),
                        ('suspend_store', 'Suspend Store'),
                        ('activate_store', 'Activate Store'),
                        ('delete_store', 'Delete Store'),
                        ('resolve_ticket', 'Resolve Dispute'),
                        ('reject_ticket', 'Reject Dispute'),
                        ('update_order_status', 'Order Status'),
                        ('approve_seller_application', 'Approve Application'),
                        ('reject_seller_application', 'Reject Application'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter.$2),
                            selected: _actionFilter == filter.$1,
                            onSelected: (_) => setState(() {
                              _actionFilter = filter.$1;
                              _pageSize = 50;
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: auditLogsAsync.when(
              data: (logs) {
                final filtered = logs.where((log) {
                  final matchesSearch = _search.isEmpty ||
                      log.action.toLowerCase().contains(_search.toLowerCase()) ||
                      log.userEmail.toLowerCase().contains(_search.toLowerCase()) ||
                      log.targetId.toLowerCase().contains(_search.toLowerCase()) ||
                      log.targetType.toLowerCase().contains(_search.toLowerCase());

                  final matchesAction = _actionFilter == 'all' || log.action == _actionFilter;

                  final matchesDate = _dateRange == null ||
                      (log.createdAt.isAfter(_dateRange!.start) &&
                       log.createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1))));

                  return matchesSearch && matchesAction && matchesDate;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No matching audit logs found.',
                      style: GoogleFonts.inter(
                        color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond,
                      ),
                    ),
                  );
                }

                final displayed = filtered.take(_pageSize).toList();
                final hasMore = filtered.length > _pageSize;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayed.length + (hasMore ? 1 : 0),
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == displayed.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _pageSize += 50),
                            child: const Text('Load More'),
                          ),
                        ),
                      );
                    }
                    final log = displayed[index];
                    return AdminSectionCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.history_toggle_off_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        log.action.replaceAll('_', ' ').toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(log.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'By: ${log.userEmail}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Target: ${log.targetType} (${log.targetId})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                                  ),
                                ),
                                if (log.metadata.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.03)
                                          : Colors.black.withValues(alpha: 0.02),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Table(
                                      columnWidths: const {
                                        0: IntrinsicColumnWidth(),
                                        1: FlexColumnWidth(),
                                      },
                                      children: log.metadata.entries.map((e) {
                                        return TableRow(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(right: 12, bottom: 4),
                                              child: Text(
                                                '${e.key}:',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Text(
                                                e.value.toString(),
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
