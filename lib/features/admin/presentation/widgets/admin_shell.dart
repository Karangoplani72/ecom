// lib/features/admin/presentation/widgets/admin_shell.dart
//
// Shared navigation shell for every screen under /admin/*.
// Mirrors the seller portal's sidebar pattern so the admin console reads
// like a single cohesive product instead of a set of disconnected pages:
//   - Persistent left sidebar on desktop / wide tablet layouts
//   - Slide-out Drawer with the same nav on mobile layouts
//   - A lightweight top bar that carries the page title + contextual actions
//
// Every admin screen should wrap its content in `AdminScaffold` rather than
// building its own `Scaffold`, so navigation stays consistent as more
// screens are added.

import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/shared/presentation/widgets/notification_bell.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────
// AdminScaffold — page-level wrapper
// ─────────────────────────────────────────────────────────────
class AdminScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: isDesktop
          ? null
          : Drawer(
              width: 280,
              backgroundColor: sidebarColor,
              elevation: 0,
              child: const AdminSidebar(inDrawer: true),
            ),
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          if (isDesktop) const AdminSidebar(),
          Expanded(
            child: SafeArea(
              left: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AdminTopBar(
                    title: title,
                    subtitle: subtitle,
                    actions: actions,
                    isDesktop: isDesktop,
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.border,
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool isDesktop;

  const _AdminTopBar({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              if (!isDesktop)
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (!isDesktop) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700, fontSize: 22),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecond
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const NotificationBell(),
              if (actions != null) ...[const SizedBox(width: 12), ...actions!],
            ],
          ),
        ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AdminSidebar (desktop) + Drawer content (mobile)
// ─────────────────────────────────────────────────────────────
class AdminSidebar extends ConsumerWidget {
  final bool inDrawer;

  const AdminSidebar({super.key, this.inDrawer = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminDashboardMetricsProvider);
    final metrics = metricsAsync.asData?.value;
    final pendingApprovals = metrics?.pendingApplications ?? 0;
    final openDisputes = metrics?.openDisputes ?? 0;

    final currentPath = GoRouterState.of(context).uri.toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.border;
    final mutedText =
        isDark ? AppColors.darkTextSecond : AppColors.lightTextSecondary;

    return Material(
      color: sidebarColor,
      child: Container(
      width: inDrawer ? null : 256,
      height: double.infinity,
      decoration: BoxDecoration(
        border: inDrawer
            ? null
            : Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: AppRadius.borderSM,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LuxeMarket',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Admin Console',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SidebarSection(
                    label: 'Overview',
                    children: [
                      _SidebarItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        route: '/admin/control-panel',
                        isActive: currentPath.startsWith(
                          '/admin/control-panel',
                        ),
                      ),
                    ],
                  ),
                  _SidebarSection(
                    label: 'Marketplace',
                    children: [
                      _SidebarItem(
                        icon: Icons.fact_check_outlined,
                        activeIcon: Icons.fact_check_rounded,
                        label: 'Store Approvals',
                        route: '/admin/store-approvals',
                        isActive: currentPath.startsWith(
                          '/admin/store-approvals',
                        ),
                        badgeCount: pendingApprovals,
                      ),
                      _SidebarItem(
                        icon: Icons.category_outlined,
                        activeIcon: Icons.category_rounded,
                        label: 'Category Requests',
                        route: '/admin/category-requests',
                        isActive: currentPath.startsWith(
                          '/admin/category-requests',
                        ),
                      ),
                      _SidebarItem(
                        icon: Icons.storefront_outlined,
                        activeIcon: Icons.storefront_rounded,
                        label: 'Stores',
                        route: '/admin/stores',
                        isActive: currentPath.startsWith('/admin/stores'),
                      ),
                      _SidebarItem(
                        icon: Icons.badge_outlined,
                        activeIcon: Icons.badge_rounded,
                        label: 'Sellers',
                        route: '/admin/sellers',
                        isActive: currentPath.startsWith('/admin/sellers'),
                      ),
                      _SidebarItem(
                        icon: Icons.inventory_2_outlined,
                        activeIcon: Icons.inventory_2_rounded,
                        label: 'Products',
                        route: '/admin/products',
                        isActive: currentPath.startsWith('/admin/products'),
                      ),
                      _SidebarItem(
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long_rounded,
                        label: 'Orders',
                        route: '/admin/orders',
                        isActive: currentPath.startsWith('/admin/orders'),
                      ),
                      _SidebarItem(
                        icon: Icons.local_offer_outlined,
                        activeIcon: Icons.local_offer,
                        label: 'Coupons',
                        route: '/admin/coupons',
                        isActive: currentPath.startsWith('/admin/coupons'),
                      ),
                    ],
                  ),
                  _SidebarSection(
                    label: 'People',
                    children: [
                      _SidebarItem(
                        icon: Icons.people_outline_rounded,
                        activeIcon: Icons.people_rounded,
                        label: 'Users & Roles',
                        route: '/admin/users',
                        isActive: currentPath.startsWith('/admin/users'),
                      ),
                    ],
                  ),
                  _SidebarSection(
                    label: 'Finance',
                    children: [
                      _SidebarItem(
                        icon: Icons.account_balance_wallet_outlined,
                        activeIcon: Icons.account_balance_wallet_rounded,
                        label: 'Settlements',
                        route: '/admin/settlements',
                        isActive: currentPath.startsWith('/admin/settlements'),
                      ),
                      _SidebarItem(
                        icon: Icons.analytics_outlined,
                        activeIcon: Icons.analytics_rounded,
                        label: 'Analytics',
                        route: '/admin/analytics',
                        isActive: currentPath.startsWith('/admin/analytics'),
                      ),
                    ],
                  ),
                  _SidebarSection(
                    label: 'Trust & Safety',
                    children: [
                      _SidebarItem(
                        icon: Icons.report_problem_outlined,
                        activeIcon: Icons.report_rounded,
                        label: 'Reports & Disputes',
                        route: '/admin/reports',
                        isActive: currentPath.startsWith('/admin/reports'),
                        badgeCount: openDisputes,
                      ),
                    ],
                  ),
                  _SidebarSection(
                    label: 'System',
                    children: [
                      _SidebarItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings_rounded,
                        label: 'Platform Settings',
                        route: '/admin/settings',
                        isActive: currentPath.startsWith('/admin/settings'),
                      ),
                      _SidebarItem(
                        icon: Icons.history_toggle_off_outlined,
                        activeIcon: Icons.history_rounded,
                        label: 'Audit Logs',
                        route: '/admin/audit-logs',
                        isActive: currentPath.startsWith('/admin/audit-logs'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.border,
          ),
          const _SidebarLogout(),
          const SizedBox(height: 16),
        ],
      ),
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _SidebarSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionLabelColor =
        isDark ? AppColors.darkTextSecond : AppColors.lightTextSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: sectionLabelColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isActive;
  final int? badgeCount;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.isActive,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark
        ? AppColors.darkTextSecond
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isActive
            ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.1)
            : Colors.transparent,
        borderRadius: AppRadius.borderMD,
        child: InkWell(
          borderRadius: AppRadius.borderMD,
          onTap: () {
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
            context.go(route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 20,
                  color: isActive ? AppColors.primary : inactiveColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? AppColors.primary : inactiveColor,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarLogout extends StatelessWidget {
  const _SidebarLogout();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderMD,
        child: InkWell(
          borderRadius: AppRadius.borderMD,
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) context.go('/');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
                const SizedBox(width: 12),
                Text(
                  'Sign out',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
