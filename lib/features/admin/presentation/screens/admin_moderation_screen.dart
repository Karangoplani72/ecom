// lib/features/admin/presentation/screens/admin_moderation_screen.dart
//
// Admin Dashboard (route: /admin/control-panel)
// The landing screen admins/superAdmins are redirected to after login.
// Gives a platform-wide snapshot (metrics) plus quick navigation into every
// other admin area. Metric values below are placeholder/sample data — see
// ADMIN_SCREENS_GUIDE.txt for what should back each card once the admin
// analytics use case is implemented.

import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminModerationScreen extends StatelessWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Admin Dashboard',
      subtitle: 'Platform overview and quick actions',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const AdminSampleDataNotice(
            message:
                'Metrics below are sample placeholders for layout preview only.',
          ),
          const SizedBox(height: 20),
          const AdminMetricGrid(
            metrics: [
              AdminMetricCard(
                label: 'Total Users',
                value: '12,480',
                icon: Icons.people_outline_rounded,
                color: Color(0xFF2563EB),
                trend: '+4.2%',
              ),
              AdminMetricCard(
                label: 'Pending Approvals',
                value: '7',
                icon: Icons.fact_check_outlined,
                color: Color(0xFFF59E0B),
              ),
              AdminMetricCard(
                label: 'Active Disputes',
                value: '3',
                icon: Icons.report_problem_outlined,
                color: Color(0xFFDC2626),
              ),
              AdminMetricCard(
                label: 'Verified Stores',
                value: '356',
                icon: Icons.storefront_outlined,
                color: Color(0xFF16A34A),
                trend: '+1.8%',
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Management',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _AdminTile(
            title: 'User Management',
            subtitle: 'Assign roles, suspend or reinstate accounts',
            icon: Icons.people_outline_rounded,
            onTap: () => context.go('/admin/users'),
          ),
          _AdminTile(
            title: 'Store Approvals',
            subtitle: 'Review and approve pending seller store applications',
            icon: Icons.fact_check_outlined,
            onTap: () => context.go('/admin/store-approvals'),
          ),
          _AdminTile(
            title: 'Stores',
            subtitle: 'Browse and manage every store on the platform',
            icon: Icons.storefront_outlined,
            onTap: () => context.go('/admin/stores'),
          ),
          _AdminTile(
            title: 'Seller Management',
            subtitle: 'View verified sellers and their performance',
            icon: Icons.badge_outlined,
            onTap: () => context.go('/admin/sellers'),
          ),
          _AdminTile(
            title: 'Reports & Disputes',
            subtitle: 'Handle abuse reports and transaction disputes',
            icon: Icons.report_problem_outlined,
            onTap: () => context.go('/admin/reports'),
          ),
          _AdminTile(
            title: 'System Settings',
            subtitle: 'Commission rates, platform controls and access',
            icon: Icons.settings_outlined,
            onTap: () => context.go('/admin/settings'),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminSectionCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Icon(icon),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
