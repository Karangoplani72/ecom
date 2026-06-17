import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text('Anjali'),
            accountEmail: Text('anjali@example.com'),
          ),

          ListTile(
            title: const Text('My Orders'),
            leading: const Icon(Icons.shopping_bag),
            onTap: () => context.push('/buyer/orders'),
          ),

          ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.logout),
            onTap: () async {
              await ref
                  .read(authControllerProvider.notifier)
                  .executeLogoutSequence();

              if (!context.mounted) return;

              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
