import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/domain/entities/admin_user.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _search = '';
  String _roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminAllUsersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdminScaffold(
      title: 'User Management',
      subtitle: 'Assign roles and manage account status',
      body: Column(
        children: [
          _buildFilters(isDark),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: AdminEmptyRow(
                  icon: Icons.error_outline_rounded,
                  message: e.toString(),
                ),
              ),
              data: (users) {
                final filtered = users.where((u) {
                  final matchesSearch = _search.isEmpty ||
                      u.email.toLowerCase().contains(_search.toLowerCase());
                  final matchesRole = _roleFilter == 'all' ||
                      u.roles
                          .map((r) => r.name)
                          .contains(_roleFilter);
                  return matchesSearch && matchesRole;
                }).toList();

                if (filtered.isEmpty) {
                  return const AdminEmptyRow(
                    icon: Icons.people_outline_rounded,
                    message: 'No users match your filters.',
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _UserTile(user: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by email...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderLG,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in [
                  ('all', 'All Users'),
                  ('buyer', 'Buyers'),
                  ('seller', 'Sellers'),
                  ('admin', 'Admins'),
                  ('superAdmin', 'Super Admins'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter.$2),
                      selected: _roleFilter == filter.$1,
                      onSelected: (_) =>
                          setState(() => _roleFilter = filter.$1),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final AdminUser user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdminSectionCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          user.email,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          user.roles.isEmpty
              ? 'No roles'
              : user.roles.map((r) => r.name).join(' · '),
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? Colors.white54
                : AppColors.lightTextSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminStatusPill(
              label: user.isActive ? 'Active' : 'Suspended',
              color: user.isActive ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded, size: 20),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Roles',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: UserRole.values
                      .where((r) => r != UserRole.guest)
                      .map((role) {
                    final selected = user.roles.contains(role);
                    return FilterChip(
                      label: Text(role.name),
                      selected: selected,
                      onSelected: (val) async {
                        final roles = user.roles.map((r) => r.name).toList();
                        if (val) {
                          roles.add(role.name);
                        } else {
                          roles.remove(role.name);
                        }
                        await ref
                            .read(adminControllerProvider.notifier)
                            .updateUserRoles(user.uid, roles);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          user.isActive
                              ? Icons.block_rounded
                              : Icons.check_circle_outline,
                          size: 16,
                        ),
                        label: Text(
                          user.isActive ? 'Suspend' : 'Reinstate',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              user.isActive ? AppColors.error : AppColors.success,
                          side: BorderSide(
                            color: user.isActive
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                        onPressed: () async {
                          await ref
                              .read(adminControllerProvider.notifier)
                              .setUserActiveStatus(user.uid, !user.isActive);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  user.isActive
                                      ? '${user.email} suspended'
                                      : '${user.email} reinstated',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: Colors.red),
                        label: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () async {
                          final confirm = await _confirmDelete(context);
                          if (!confirm) return;
                          await ref
                              .read(adminControllerProvider.notifier)
                              .deleteUser(user.uid);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User deleted')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete User'),
            content: Text('Are you sure you want to delete ${user.email}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
