import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ecom/core/widgets/app_avatar.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Menu',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding:
              const EdgeInsets.all(20),
              child: Row(
                children: [
                  const AppAvatar(
                    radius: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          'John Doe',
                          style: theme
                              .textTheme
                              .titleLarge,
                        ),
                        const SizedBox(
                            height: 4),
                        Text(
                          'john@example.com',
                          style: theme
                              .textTheme
                              .bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      context.push(
                        '/buyer/profile',
                      );
                    },
                    child: const Text(
                      'Profile',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          _SectionTitle(
            title: 'Shopping',
          ),

          _MenuTile(
            icon: Icons.receipt_long,
            title: 'My Orders',
            onTap: () {
              context.push(
                '/buyer/orders',
              );
            },
          ),

          _MenuTile(
            icon: Icons.favorite_border,
            title: 'Wishlist',
            onTap: () {
              context.push(
                '/buyer/wishlist',
              );
            },
          ),

          _MenuTile(
            icon: Icons.location_on_outlined,
            title: 'Addresses',
            onTap: () {},
          ),

          _MenuTile(
            icon: Icons.credit_card,
            title: 'Payment Methods',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          _SectionTitle(
            title: 'Preferences',
          ),

          _MenuTile(
            icon: Icons.notifications_none,
            title: 'Notifications',
            onTap: () {},
          ),

          _MenuTile(
            icon: Icons.language,
            title: 'Language',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          _SectionTitle(
            title: 'Support',
          ),

          _MenuTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () {},
          ),

          _MenuTile(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),

          _MenuTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          FilledButton.tonalIcon(
            onPressed: () {
              // logout
            },
            icon: const Icon(
              Icons.logout,
            ),
            label: const Text(
              'Logout',
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium,
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}