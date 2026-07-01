import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SellerSidebar extends StatelessWidget {
  const SellerSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 256,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.border,
          ),
        ),
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
                    color: AppColors.primary,
                    borderRadius: AppRadius.borderSM,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
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
                      'Seller Portal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _SidebarSection(
            label: 'Overview',
            children: [
              _SidebarItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
                route: '/seller/dashboard',
                isActive: currentPath.startsWith('/seller/dashboard'),
              ),
              _SidebarItem(
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics_rounded,
                label: 'Analytics',
                route: '/seller/analytics',
                isActive: currentPath.startsWith('/seller/analytics'),
              ),
            ],
          ),
          _SidebarSection(
            label: 'Store',
            children: [
              _SidebarItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2_rounded,
                label: 'Inventory',
                route: '/seller/inventory',
                isActive: currentPath.startsWith('/seller/inventory'),
              ),
              _SidebarItem(
                icon: Icons.shopping_bag_outlined,
                activeIcon: Icons.shopping_bag_rounded,
                label: 'Orders',
                route: '/seller/orders',
                isActive: currentPath.startsWith('/seller/orders'),
              ),
              _SidebarItem(
                icon: Icons.people_outline_rounded,
                activeIcon: Icons.people_rounded,
                label: 'Customers',
                route: '/seller/customers',
                isActive: currentPath.startsWith('/seller/customers'),
              ),
              _SidebarItem(
                icon: Icons.people_alt_outlined,
                activeIcon: Icons.people_alt_rounded,
                label: 'Staff',
                route: '/seller/staff',
                isActive: currentPath.startsWith('/seller/staff'),
              ),
            ],
          ),
          _SidebarSection(
            label: 'Communication',
            children: [
              _SidebarItem(
                icon: Icons.forum_outlined,
                activeIcon: Icons.forum_rounded,
                label: 'Messages',
                route: '/chat-rooms',
                isActive: currentPath.startsWith('/chat'),
              ),
            ],
          ),
          _SidebarSection(
            label: 'Finance',
            children: [
              _SidebarItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'Finances',
                route: '/seller/finances',
                isActive: currentPath.startsWith('/seller/finances'),
              ),
            ],
          ),
          _SidebarSection(
            label: 'Settings',
            children: [
              _SidebarItem(
                icon: Icons.store_outlined,
                activeIcon: Icons.store_rounded,
                label: 'Store Profile',
                route: '/seller/store-profile',
                isActive: currentPath.startsWith('/seller/store-profile'),
              ),
              _SidebarItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Settings',
                route: '/seller/settings',
                isActive: currentPath.startsWith('/seller/settings'),
              ),
            ],
          ),
          const Spacer(),
          const Divider(height: 1),
          const _SidebarLogout(),
          const SizedBox(height: 16),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.lightTextSecondary,
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

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: AppRadius.borderMD,
        child: InkWell(
          borderRadius: AppRadius.borderMD,
          onTap: () {
            if (Scaffold.of(context).isDrawerOpen) {
              Navigator.of(context).pop();
            }
            context.push(route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 20,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.lightTextSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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

class _SidebarLogout extends ConsumerWidget {
  const _SidebarLogout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderMD,
        child: InkWell(
          borderRadius: AppRadius.borderMD,
          onTap: () async {
            await ref.read(firebaseAuthProvider).signOut();
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
                const Text(
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

class SellerDrawer extends StatelessWidget {
  const SellerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Drawer(width: 280, child: SellerSidebar());
  }
}
