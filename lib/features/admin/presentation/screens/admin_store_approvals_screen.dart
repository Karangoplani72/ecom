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
                  const AdminMetricCard(
                    label: 'Applications',
                    value: '--',
                    icon: Icons.storefront_outlined,
                    color: Color(0xFF2563EB),
                  ),
                  const AdminMetricCard(
                    label: 'Approved',
                    value: '--',
                    icon: Icons.check_circle_outline,
                    color: Color(0xFF16A34A),
                  ),
                  const AdminMetricCard(
                    label: 'Rejected',
                    value: '--',
                    icon: Icons.cancel_outlined,
                    color: Color(0xFFDC2626),
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

          Text(application.description),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                  onPressed: () async {
                    final currentUser = ref
                        .read(authStateSignalingProvider)
                        .value;

                    if (currentUser == null || application.id == null) {
                      return;
                    }

                    await ref
                        .read(adminControllerProvider.notifier)
                        .rejectSellerApplication(
                          application.id!,
                          currentUser.uid,
                          'Rejected by admin',
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Application rejected')),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Approve'),
                  onPressed: () async {
                    final currentUser = ref
                        .read(authStateSignalingProvider)
                        .value;

                    if (currentUser == null || application.id == null) {
                      return;
                    }

                    await ref
                        .read(adminControllerProvider.notifier)
                        .approveSellerApplication(
                          application.id!,
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
}
