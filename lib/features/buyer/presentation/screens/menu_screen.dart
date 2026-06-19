import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/providers/theme_provider.dart';
import 'package:ecom/core/widgets/app_avatar.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/shared/presentation/navigation/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Firebase Auth is the source of truth for whether someone is signed
    // in; Firestore only supplies the profile *data* to display. Gating
    // on Firebase Auth — not on the profile stream — means an
    // authenticated user always sees the authenticated sections, even
    // while their profile doc is still loading.
    final authState = ref.watch(firebaseAuthStateProvider);

    if (authState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Menu'), centerTitle: true),
        body: const AppLoadingView(),
      );
    }

    final firebaseUser = authState.value;
    final isAuthenticated = firebaseUser != null;
    final user = isAuthenticated
        ? ref.watch(currentUserProfileProvider).value
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Menu'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // ── Identity card ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: !isAuthenticated
                  ? Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(
                                Icons.person_outline,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Sign in to access your account',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AppPrimaryButton(
                                text: 'Sign In',
                                onPressed: () => context.push(AppRoutes.login),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.push(AppRoutes.signup),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Register'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        AppAvatar(imageUrl: user?.photoUrl, radius: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user == null
                                    ? 'My Account'
                                    : (user.displayName.isEmpty
                                          ? 'My Account'
                                          : user.displayName),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? firebaseUser.email ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () => context.push(AppRoutes.buyerProfile),
                          child: const Text('Profile'),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Shopping section (authenticated only) ──
          if (isAuthenticated) ...[
            const _SectionLabel(title: 'Shopping'),
            _MenuTile(
              icon: Icons.receipt_long_outlined,
              title: 'My Orders',
              onTap: () => context.push(AppRoutes.buyerOrders),
            ),
            _MenuTile(
              icon: Icons.favorite_border,
              title: 'Wishlist',
              onTap: () => context.push(AppRoutes.buyerWishlist),
            ),
            _MenuTile(
              icon: Icons.location_on_outlined,
              title: 'Saved Addresses',
              onTap: () => context.push(AppRoutes.buyerAddresses),
            ),
            _MenuTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () => context.push(AppRoutes.buyerNotifications),
            ),
            const SizedBox(height: 24),
          ],

          // ── Account settings (authenticated only) ──
          if (isAuthenticated) ...[
            const _SectionLabel(title: 'Account'),
            _MenuTile(
              icon: Icons.settings_outlined,
              title: 'Account Settings',
              onTap: () => context.push(AppRoutes.buyerAccountSettings),
            ),
            const SizedBox(height: 24),
          ],

          // ── Seller Portal (authenticated only) ──
          if (isAuthenticated) ...[
            const _SectionLabel(title: 'Seller Portal'),
            if (user != null && user.roles.contains(UserRole.seller))
              _MenuTile(
                icon: Icons.dashboard_outlined,
                title: 'Seller Dashboard',
                subtitle: 'Manage your inventory, orders & analytics',
                onTap: () => context.go(AppRoutes.sellerDashboard),
              )
            else if (user != null && user.sellerApplicationStatus == 'pending')
              _MenuTile(
                icon: Icons.hourglass_empty_rounded,
                title: 'Application Under Review',
                subtitle: 'We are verifying your storefront details',
                trailing: const Icon(Icons.access_time_filled_rounded, color: Colors.amber, size: 20),
                onTap: () => context.push(AppRoutes.sellerApply),
              )
            else if (user != null && user.sellerApplicationStatus == 'changes_requested')
              _MenuTile(
                icon: Icons.warning_amber_rounded,
                title: 'Action Required',
                subtitle: 'Admin requested changes to your application',
                trailing: const Icon(Icons.error_rounded, color: Colors.orange, size: 20),
                onTap: () => context.push(AppRoutes.sellerApply),
              )
            else if (user != null && user.sellerApplicationStatus == 'rejected')
              _MenuTile(
                icon: Icons.cancel_outlined,
                title: 'Application Rejected',
                subtitle: 'Tap to see reason or reapply',
                trailing: const Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
                onTap: () => context.push(AppRoutes.sellerApply),
              )
            else
              _MenuTile(
                icon: Icons.storefront_outlined,
                title: 'Register as Seller',
                subtitle: 'Launch your store on LuxeMarket',
                onTap: () => context.push(AppRoutes.sellerApply),
              ),
            const SizedBox(height: 24),
          ],

          // ── Appearance ──
          const _SectionLabel(title: 'Appearance'),
          Consumer(
            builder: (context, ref, _) {
              final themeMode = ref.watch(themeProvider);
              return Row(
                children: [
                  for (final opt in [
                    (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
                    (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
                    (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _ThemeOption(
                          icon: opt.$2,
                          label: opt.$3,
                          selected: themeMode == opt.$1,
                          onTap: () => ref
                              .read(themeProvider.notifier)
                              .setThemeMode(opt.$1),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Support & legal (always visible) ──
          const _SectionLabel(title: 'Support & Legal'),
          _MenuTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () => context.push(AppRoutes.buyerHelp),
          ),
          _MenuTile(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            onTap: () => context.push(AppRoutes.buyerPrivacy),
          ),
          _MenuTile(
            icon: Icons.info_outline,
            title: 'About ecom',
            onTap: () => context.push(AppRoutes.buyerAbout),
          ),

          // ── Logout ──
          if (isAuthenticated) ...[
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(authControllerProvider.notifier)
                      .executeLogoutSequence();
                  if (!context.mounted) return;
                  context.go(AppRoutes.login);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: colorScheme.onSurface),
        ),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
