import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/seller_application/domain/entities/seller_application.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminStoreApprovalsScreen extends ConsumerWidget {
  const AdminStoreApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(pendingSellerApplicationsProvider);
    final metricsAsync = ref.watch(adminDashboardMetricsProvider);

    return AdminScaffold(
      title: 'Store Approvals',
      subtitle: 'Review and approve seller applications',
      body: applications.when(
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              AdminMetricGrid(
                metrics: [
                  AdminMetricCard(
                    label: 'Pending Review',
                    value: items.length.toString(),
                    icon: Icons.hourglass_empty_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  AdminMetricCard(
                    label: 'Total Applications',
                    value: metricsAsync.when(
                      data: (m) =>
                          (m.pendingApplications +
                                  m.approvedSellers +
                                  m.rejectedSellers)
                              .toString(),
                      loading: () => '...',
                      error: (err, stack) => '--',
                    ),
                    icon: Icons.storefront_outlined,
                    color: const Color(0xFF2563EB),
                  ),
                  AdminMetricCard(
                    label: 'Approved',
                    value: metricsAsync.when(
                      data: (m) => m.approvedSellers.toString(),
                      loading: () => '...',
                      error: (err, stack) => '--',
                    ),
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF16A34A),
                  ),
                  AdminMetricCard(
                    label: 'Rejected',
                    value: metricsAsync.when(
                      data: (m) => m.rejectedSellers.toString(),
                      loading: () => '...',
                      error: (err, stack) => '--',
                    ),
                    icon: Icons.cancel_outlined,
                    color: const Color(0xFFDC2626),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                'Pending Applications',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 12),

              if (items.isEmpty)
                const AdminEmptyRow(
                  icon: Icons.inbox_outlined,
                  message: 'No pending seller applications.',
                )
              else
                ...items.map(
                  (application) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ApplicationCard(application: application),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends ConsumerWidget {
  final SellerApplication application;

  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProfileProvider).value;
    final dateText = DateFormat(
      'd MMM yyyy, h:mm a',
    ).format(application.submittedAt);

    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.10),
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
                      application.storeName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),

                    const SizedBox(height: 2),

                    Text(application.fullName),

                    Text(application.phoneNumber),
                  ],
                ),
              ),

              const AdminStatusPill(label: 'Pending', color: Color(0xFFF59E0B)),
            ],
          ),

          const SizedBox(height: 12),

          Text('Category: ${application.businessCategory}'),

          const SizedBox(height: 4),

          Text('Submitted: $dateText'),

          if (application.gstNumber != null &&
              application.gstNumber!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('GST: ${application.gstNumber}'),
          ],

          const SizedBox(height: 12),

          Text(application.storeDescription),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    if (currentUser == null || application.applicationId == null) return;

                    final reason = await _showFeedbackDialog(
                      context,
                      'Reject Application',
                      'Provide rejection reason',
                    );

                    if (reason == null || reason.isEmpty) return;

                    await ref
                        .read(adminControllerProvider.notifier)
                        .rejectSellerApplication(
                          application.applicationId!,
                          currentUser.uid,
                          reason,
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Application rejected')),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Request Changes'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    if (currentUser == null || application.applicationId == null) return;

                    final feedback = await _showFeedbackDialog(
                      context,
                      'Request Changes',
                      'What details should the user update?',
                    );

                    if (feedback == null || feedback.isEmpty) return;

                    await ref
                        .read(adminControllerProvider.notifier)
                        .requestChangesOnSellerApplication(
                          application.applicationId!,
                          currentUser.uid,
                          feedback,
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Changes requested')),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    if (currentUser == null || application.applicationId == null) {
                      return;
                    }

                    await ref
                        .read(adminControllerProvider.notifier)
                        .approveSellerApplication(
                          application.applicationId!,
                          currentUser.uid,
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Application approved')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String?> _showFeedbackDialog(
    BuildContext context,
    String title,
    String label,
  ) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: label,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
