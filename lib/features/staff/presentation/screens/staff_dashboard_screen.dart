import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/seller/domain/entities/staff_permission.dart';
import 'package:ecom/features/seller/presentation/controllers/staff_permission_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final permsAsync = ref.watch(staffPermissionsProvider);
    final perms = permsAsync.value ?? StaffPermissions.none();
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isDesktop) ...[
                    IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Welcome back, ${user?.displayName.split(' ').firstOrNull ?? 'Staff'}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here is your quick access dashboard. Choose a module below to get started.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: (isDark ? AppColors.darkTextSecond : AppColors.lightTextSecondary),
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildListDelegate([
                if (perms.has(StaffPermission.inventory))
                  _ModuleCard(
                    title: 'Inventory',
                    subtitle: 'Manage products & stock',
                    icon: Icons.inventory_2_rounded,
                    color: Colors.blue,
                    onTap: () => context.go('/staff/inventory'),
                    isDark: isDark,
                  ),
                if (perms.has(StaffPermission.orders))
                  _ModuleCard(
                    title: 'Orders',
                    subtitle: 'View & fulfill orders',
                    icon: Icons.shopping_bag_rounded,
                    color: Colors.green,
                    onTap: () => context.go('/staff/orders'),
                    isDark: isDark,
                  ),
                if (perms.has(StaffPermission.customers))
                  _ModuleCard(
                    title: 'Customers',
                    subtitle: 'View customer data',
                    icon: Icons.people_rounded,
                    color: Colors.orange,
                    onTap: () => context.go('/staff/customers'),
                    isDark: isDark,
                  ),
                if (perms.has(StaffPermission.staff))
                  _ModuleCard(
                    title: 'Staff',
                    subtitle: 'Manage team access',
                    icon: Icons.people_alt_rounded,
                    color: Colors.purple,
                    onTap: () => context.go('/staff/staff'),
                    isDark: isDark,
                  ),
                if (perms.has(StaffPermission.messages))
                  _ModuleCard(
                    title: 'Messages',
                    subtitle: 'Chat with customers',
                    icon: Icons.forum_rounded,
                    color: Colors.teal,
                    onTap: () => context.go('/chat-rooms'),
                    isDark: isDark,
                  ),
              ]),
            ),
          ),
          if (!perms.has(StaffPermission.inventory) &&
              !perms.has(StaffPermission.orders) &&
              !perms.has(StaffPermission.customers) &&
              !perms.has(StaffPermission.staff) &&
              !perms.has(StaffPermission.messages))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 64,
                        color: (isDark ? AppColors.darkTextSecond : AppColors.lightTextSecondary).withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Modules Available',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: (isDark ? AppColors.darkTextSecond : AppColors.lightTextSecondary),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You currently do not have permission to access any modules. Please contact the store owner to update your permissions.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: (isDark ? AppColors.darkTextSecond : AppColors.lightTextSecondary),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLG,
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: AppRadius.borderLG,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: AppRadius.borderMD,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: (isDark ? AppColors.darkTextSecond : AppColors.lightTextSecondary),
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
