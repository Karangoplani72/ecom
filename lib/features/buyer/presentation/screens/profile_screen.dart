import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';
import 'package:ecom/features/auth/presentation/controllers/address_controller.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/profile_image_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/profile_image_state.dart';
import 'package:ecom/features/buyer/presentation/controllers/wishlist_controller.dart';
import 'package:ecom/features/buyer/presentation/widgets/profile_avatar.dart';
import 'package:ecom/features/orders/presentation/controllers/order_controller.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_side_drawer.dart';
import 'package:ecom/shared/presentation/navigation/router.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';
import 'package:ecom/shared/presentation/widgets/blur_app_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static void _showImageSourceActionSheet(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkBgSurface : AppColors.lightBgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Select Profile Photo',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: isDark ? Colors.white70 : Colors.black54),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.inter(color: textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(profileImageControllerProvider.notifier)
                      .pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: isDark ? Colors.white70 : Colors.black54),
                title: Text(
                  'Take a Photo',
                  style: GoogleFonts.inter(color: textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(profileImageControllerProvider.notifier)
                      .pickAndUploadImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFrostedCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.2),
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18),
        color: isDark ? Colors.white : AppColors.lightTextPrimary,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(firebaseAuthStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen<ProfileImageState>(profileImageControllerProvider, (prev, next) {
      if (next.status == ProfileImageStatus.error &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.status == ProfileImageStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile image updated successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary,
      drawer: const BuyerSideDrawer(),
      body: Stack(
        children: [
          const IgnorePointer(child: OrbBackgroundWidget()),
          authState.when(
            loading: () => const AppLoadingView(),
            error: (error, _) => AppErrorView(
              message: 'Could not determine your sign-in status.',
              onRetry: () => ref.invalidate(firebaseAuthStateProvider),
            ),
            data: (firebaseUser) {
              final Widget content;
              if (firebaseUser == null) {
                content = const _GuestBody();
              } else {
                final profileAsync = ref.watch(currentUserProfileProvider);
                content = profileAsync.when(
                  skipLoadingOnReload: true,
                  loading: () => const AppLoadingView(),
                  error: (error, _) => AppErrorView(
                    message: 'Could not load your profile.',
                    onRetry: () => ref.invalidate(currentUserProfileProvider),
                  ),
                  data: (user) => user == null
                      ? const AppLoadingView()
                      : _AuthenticatedBody(user: user),
                );
              }

              return NestedScrollView(
                physics: const BouncingScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    BlurAppBar(
                      title: 'My Account',
                      showLeading: true,
                      actions: [
                        if (firebaseUser != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _buildFrostedCircleButton(
                              icon: Icons.notifications_outlined,
                              onPressed: () => context.push(AppRoutes.buyerNotifications),
                              isDark: isDark,
                            ),
                          ),
                      ],
                      isDark: isDark,
                    ),
                  ];
                },
                body: content,
              );
            },
          ),
        ],
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
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
        final subtitleColor = isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond;

        return GlassCardWidget(
          borderRadius: 24,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 32,
                    color: Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sign in Required',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Create a free account or sign in to use $feature.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: subtitleColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              GradientButton(
                label: 'Sign In',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  if (context.mounted) context.push(AppRoutes.login);
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    if (context.mounted) context.push(AppRoutes.signup);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF7C3AED)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Create Account',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF7C3AED),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        children: [
          // Glass Avatar Container
          GlassCardWidget(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person_outline,
                    size: 48,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to ecom',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to track orders, save your wishlist, and check out faster.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: subtitleColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Sign In',
                  onTap: () => context.push(AppRoutes.login),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => context.push(AppRoutes.signup),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Create Account',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7C3AED),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Quick Access Header
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                'Quick Access',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),

          // Stats cards
          Row(
            children: [
              Expanded(
                child: _GuestStatCard(
                  title: 'Orders',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => _promptSignIn(context, feature: 'order history'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GuestStatCard(
                  title: 'Wishlist',
                  icon: Icons.favorite_border,
                  onTap: () => _promptSignIn(context, feature: 'your wishlist'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GuestStatCard(
                  title: 'Addresses',
                  icon: Icons.location_on_outlined,
                  onTap: () => _promptSignIn(context, feature: 'saved addresses'),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Support and legal
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
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// Guest stat card helper
class _GuestStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _GuestStatCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    return GestureDetector(
      onTap: onTap,
      child: GlassCardWidget(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: const Color(0xFFA855F7),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Icon(
              Icons.lock_outline,
              size: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ],
        ),
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
    final isDark = theme.brightness == Brightness.dark;
    final opt = ref.watch(optimisticProfileProvider);

    final ordersCount = ref.watch(buyerOrdersProvider).value?.length ?? 0;
    final wishlistCount = ref.watch(wishlistStreamProvider).value?.length ?? 0;
    final addressCount = ref.watch(userAddressesProvider).value?.length ?? 0;

    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentUserProfileProvider);
        ref.invalidate(buyerOrdersProvider);
        ref.invalidate(wishlistStreamProvider);
        ref.invalidate(userAddressesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Identity Header card
            GlassCardWidget(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Row(
                children: [
                  ProfileAvatar(
                    imageUrl: opt.imageUrl,
                    localImageBytes: opt.localBytes,
                    userName: user.displayName,
                    radius: 38,
                    isUploading: opt.isUploading,
                    onEditTap: () =>
                        ProfileScreen._showImageSourceActionSheet(context, ref, isDark),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName.isEmpty ? 'My Account' : user.displayName,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: subtitleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (user.hasPhoneNumber)
                          Text(
                            user.phoneNumber!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: subtitleColor,
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.buyerAccountSettings),
                            child: Text(
                              '+ Add phone number',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF7C3AED),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick stats Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Orders',
                    value: '$ordersCount',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => context.push(AppRoutes.buyerOrders),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Wishlist',
                    value: '$wishlistCount',
                    icon: Icons.favorite_border,
                    onTap: () => context.push(AppRoutes.buyerWishlist),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Addresses',
                    value: '$addressCount',
                    icon: Icons.location_on_outlined,
                    onTap: () => context.push(AppRoutes.buyerAddresses),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Navigation sections
            _ProfileSection(
              title: 'Account Settings',
              items: [
                _ProfileLink(
                  icon: Icons.settings_outlined,
                  title: 'Account Details',
                  subtitle: 'Manage names, phones & emails',
                  onTap: () => context.push(AppRoutes.buyerAccountSettings),
                ),
                _ProfileLink(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Change alert preferences',
                  onTap: () => context.push(AppRoutes.notificationPreferences),
                ),
              ],
              isDark: isDark,
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
                    trailing: const Icon(
                      Icons.access_time_filled_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                    onTap: () => context.push(AppRoutes.sellerApply),
                  )
                else if (user.sellerApplicationStatus == 'changes_requested')
                  _ProfileLink(
                    icon: Icons.warning_amber_rounded,
                    title: 'Action Required',
                    subtitle: 'Admin requested changes. Tap to edit.',
                    trailing: const Icon(
                      Icons.error_rounded,
                      color: Colors.orange,
                      size: 18,
                    ),
                    onTap: () => context.push(AppRoutes.sellerApply),
                  )
                else if (user.sellerApplicationStatus == 'rejected')
                  _ProfileLink(
                    icon: Icons.cancel_outlined,
                    title: 'Application Rejected',
                    subtitle: 'Tap to see reason or reapply',
                    trailing: const Icon(
                      Icons.cancel_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
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
              isDark: isDark,
            ),

            _ProfileSection(
              title: 'Help & Legal',
              items: [
                _ProfileLink(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  subtitle: 'FAQs, contact support & requests',
                  onTap: () => context.push(AppRoutes.buyerHelp),
                ),
                _ProfileLink(
                  icon: Icons.policy_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'How we manage customer privacy',
                  onTap: () => context.push(AppRoutes.buyerPrivacy),
                ),
                _ProfileLink(
                  icon: Icons.info_outline,
                  title: 'About ecom',
                  subtitle: 'Application details and licensing',
                  onTap: () => context.push(AppRoutes.buyerAbout),
                ),
              ],
              isDark: isDark,
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(authControllerProvider.notifier)
                      .executeLogoutSequence();
                  if (!context.mounted) return;
                  context.go(AppRoutes.login);
                },
                icon: const Icon(Icons.logout, size: 18),
                label: Text(
                  'Logout',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond;

    return GestureDetector(
      onTap: onTap,
      child: GlassCardWidget(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFA855F7), size: 24),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileLink> items;
  final bool isDark;

  const _ProfileSection({
    required this.title,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          GlassCardWidget(
            padding: EdgeInsets.zero,
            child: Column(
              children: items.asMap().entries.map((entry) {
                final isLast = entry.key == items.length - 1;
                final item = entry.value;
                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.icon,
                            size: 18,
                            color: const Color(0xFFA855F7),
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        subtitle: item.subtitle != null
                            ? Text(
                                item.subtitle!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: subtitleColor,
                                ),
                              )
                            : null,
                        trailing: item.trailing ??
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                        onTap: item.onTap,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
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
