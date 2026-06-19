import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/widgets/app_avatar.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/core/widgets/app_stat_card.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';
import 'package:ecom/features/auth/presentation/controllers/address_controller.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/wishlist_controller.dart';
import 'package:ecom/features/orders/presentation/controllers/order_controller.dart';
import 'package:ecom/shared/presentation/navigation/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Firebase Auth is the source of truth for *whether* someone is
    // signed in. We gate Guest vs. Authenticated on this — never on the
    // Firestore profile stream — so an authenticated user can never see
    // the Guest UI just because their profile doc is still loading.
    final authState = ref.watch(firebaseAuthStateProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Account'),
        centerTitle: true,
        actions: [
          if (authState.value != null)
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push(AppRoutes.buyerNotifications),
            ),
        ],
      ),
      body: authState.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: 'Could not determine your sign-in status.',
          onRetry: () => ref.invalidate(firebaseAuthStateProvider),
        ),
        data: (firebaseUser) {
          if (firebaseUser == null) return const _GuestBody();

          // Authenticated with Firebase Auth from here on — Firestore
          // only supplies the profile *data*, never the guest/authed
          // decision, so a slow or momentarily-null profile read can
          // only show loading, never Guest.
          final profileAsync = ref.watch(currentUserProfileProvider);
          return profileAsync.when(
            loading: () => const AppLoadingView(),
            error: (error, _) => AppErrorView(
              message: 'Could not load your profile.',
              onRetry: () => ref.invalidate(currentUserProfileProvider),
            ),
            data: (user) => user == null
                ? const AppLoadingView()
                : _AuthenticatedBody(user: user),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Guest state
// ─────────────────────────────────────────────

class _GuestBody extends StatelessWidget {
  const _GuestBody();

  void _promptSignIn(BuildContext context, {required String feature}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Sign in required',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a free account or sign in to use $feature.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                text: 'Sign In',
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  if (context.mounted) context.push(AppRoutes.login);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    if (context.mounted) context.push(AppRoutes.signup);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Create Account'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.person_outline,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome to ecom',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to track orders, save your wishlist,\nand check out faster.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          AppPrimaryButton(
            text: 'Sign In',
            onPressed: () => context.push(AppRoutes.login),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push(AppRoutes.signup),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Create Account'),
            ),
          ),
          const SizedBox(height: 40),
          _SectionHeader(title: 'Quick Access'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppStatCard(
                  title: 'Orders',
                  value: '—',
                  icon: Icons.receipt_long_outlined,
                  locked: true,
                  onTap: () => _promptSignIn(context, feature: 'order history'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppStatCard(
                  title: 'Wishlist',
                  value: '—',
                  icon: Icons.favorite_border,
                  locked: true,
                  onTap: () => _promptSignIn(context, feature: 'your wishlist'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppStatCard(
                  title: 'Addresses',
                  value: '—',
                  icon: Icons.location_on_outlined,
                  locked: true,
                  onTap: () =>
                      _promptSignIn(context, feature: 'saved addresses'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          _ProfileSection(
            title: 'Help & Legal',
            items: [
              _ProfileLink(
                icon: Icons.help_outline,
                title: 'Help Center',
                onTap: () => context.push(AppRoutes.buyerHelp),
              ),
              _ProfileLink(
                icon: Icons.policy_outlined,
                title: 'Privacy Policy',
                onTap: () => context.push(AppRoutes.buyerPrivacy),
              ),
              _ProfileLink(
                icon: Icons.info_outline,
                title: 'About ecom',
                onTap: () => context.push(AppRoutes.buyerAbout),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Authenticated state
// ─────────────────────────────────────────────

class _AuthenticatedBody extends ConsumerWidget {
  final AppUser user;

  const _AuthenticatedBody({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final ordersCount = ref.watch(buyerOrdersProvider).value?.length ?? 0;
    final wishlistCount = ref.watch(wishlistStreamProvider).value?.length ?? 0;
    final addressCount = ref.watch(userAddressesProvider).value?.length ?? 0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentUserProfileProvider);
        ref.invalidate(buyerOrdersProvider);
        ref.invalidate(wishlistStreamProvider);
        ref.invalidate(userAddressesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Identity header ──
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: AppAvatar(imageUrl: user.photoUrl, radius: 44),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () =>
                              context.push(AppRoutes.buyerAccountSettings),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.displayName.isEmpty ? 'My Account' : user.displayName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (user.hasPhoneNumber) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.phoneNumber!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ] else
                    TextButton(
                      onPressed: () =>
                          context.push(AppRoutes.buyerAccountSettings),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('+ Add phone number'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Quick stats ──
            Row(
              children: [
                Expanded(
                  child: AppStatCard(
                    title: 'Orders',
                    value: '$ordersCount',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => context.push(AppRoutes.buyerOrders),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppStatCard(
                    title: 'Wishlist',
                    value: '$wishlistCount',
                    icon: Icons.favorite_border,
                    onTap: () => context.push(AppRoutes.buyerWishlist),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppStatCard(
                    title: 'Addresses',
                    value: '$addressCount',
                    icon: Icons.location_on_outlined,
                    onTap: () => context.push(AppRoutes.buyerAddresses),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            _ProfileSection(
              title: 'Account',
              items: [
                _ProfileLink(
                  icon: Icons.settings_outlined,
                  title: 'Account Settings',
                  onTap: () => context.push(AppRoutes.buyerAccountSettings),
                ),
                _ProfileLink(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () => context.push(AppRoutes.buyerNotifications),
                ),
              ],
            ),

            _ProfileSection(
              title: 'Seller Portal',
              items: [
                if (user.roles.contains(UserRole.seller))
                  _ProfileLink(
                    icon: Icons.dashboard_outlined,
                    title: 'Seller Dashboard',
                    subtitle: 'Manage inventory, orders & analytics',
                    onTap: () => context.go(AppRoutes.sellerDashboard),
                  )
                else if (user.sellerApplicationStatus == 'pending')
                  _ProfileLink(
                    icon: Icons.hourglass_empty_rounded,
                    title: 'Application Under Review',
                    subtitle: 'Admin team is verifying your details',
                    trailing: const Icon(Icons.access_time_filled_rounded, color: Colors.amber, size: 18),
                    onTap: () => context.push(AppRoutes.sellerApply),
                  )
                else if (user.sellerApplicationStatus == 'changes_requested')
                  _ProfileLink(
                    icon: Icons.warning_amber_rounded,
                    title: 'Action Required',
                    subtitle: 'Admin requested changes. Tap to edit.',
                    trailing: const Icon(Icons.error_rounded, color: Colors.orange, size: 18),
                    onTap: () => context.push(AppRoutes.sellerApply),
                  )
                else if (user.sellerApplicationStatus == 'rejected')
                  _ProfileLink(
                    icon: Icons.cancel_outlined,
                    title: 'Application Rejected',
                    subtitle: 'Tap to see reason or reapply',
                    trailing: const Icon(Icons.cancel_rounded, color: Colors.red, size: 18),
                    onTap: () => context.push(AppRoutes.sellerApply),
                  )
                else
                  _ProfileLink(
                    icon: Icons.storefront_outlined,
                    title: 'Register as Seller',
                    subtitle: 'Launch your store on LuxeMarket',
                    onTap: () => context.push(AppRoutes.sellerApply),
                  ),
              ],
            ),

            _ProfileSection(
              title: 'Help & Legal',
              items: [
                _ProfileLink(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () => context.push(AppRoutes.buyerHelp),
                ),
                _ProfileLink(
                  icon: Icons.policy_outlined,
                  title: 'Privacy Policy',
                  onTap: () => context.push(AppRoutes.buyerPrivacy),
                ),
                _ProfileLink(
                  icon: Icons.info_outline,
                  title: 'About ecom',
                  onTap: () => context.push(AppRoutes.buyerAbout),
                ),
              ],
            ),

            const SizedBox(height: 8),
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
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared layout helpers
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileLink> items;

  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          Material(
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: items.asMap().entries.map((entry) {
                final isLast = entry.key == items.length - 1;
                final item = entry.value;
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          size: 20,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      title: Text(item.title, style: theme.textTheme.bodyLarge),
                      subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
                      trailing: item.trailing ?? const Icon(Icons.chevron_right, size: 18),
                      onTap: item.onTap,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          height: 1,
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLink {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ProfileLink({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });
}
