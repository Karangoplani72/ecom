import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/admin_user.dart';
import '../controllers/admin_user_controller.dart';
import '../widgets/admin_shell.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return AdminScaffold(
      title: 'User Management',
      subtitle: 'Assign roles and suspend or reinstate accounts',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),

            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value.trim().toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),

              error: (e, st) => Center(child: Text(e.toString())),

              data: (users) {
                final filtered = users.where((u) {
                  if (_search.isEmpty) {
                    return true;
                  }

                  return u.email.toLowerCase().contains(_search);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];

                    return _UserTile(user: user);
                  },
                );
              },
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(user.email),
        subtitle: Text(user.roles.map((e) => e.name).join(', ')),
        trailing: Switch(
          value: user.isActive,
          onChanged: (value) async {
            await ref
                .read(adminUserControllerProvider.notifier)
                .toggleUserStatus(uid: user.uid, isActive: value);
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: UserRole.values.map((role) {
                final selected = user.roles.contains(role);

                return FilterChip(
                  label: Text(role.name),
                  selected: selected,
                  onSelected: (value) async {
                    final roles = user.roles.map((e) => e.name).toList();

                    if (value) {
                      if (!roles.contains(role.name)) {
                        roles.add(role.name);
                      }
                    } else {
                      roles.remove(role.name);
                    }

                    await ref
                        .read(adminUserControllerProvider.notifier)
                        .updateRoles(uid: user.uid, roles: roles);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
