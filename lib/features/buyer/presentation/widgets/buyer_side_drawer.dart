import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/profile_image_controller.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';
import 'package:ecom/features/buyer/presentation/widgets/profile_avatar.dart';
import 'package:ecom/shared/presentation/navigation/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BuyerSideDrawer extends ConsumerWidget {
  const BuyerSideDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userAsync = ref.watch(currentUserProfileProvider);
    final opt = ref.watch(optimisticProfileProvider);
    final user = userAsync.value;

    final userName = user?.displayName ?? 'Guest User';
    final userEmail = user?.email ?? 'Please log in';

    // Calculate bottom padding to prevent hiding behind the bottom navigation bar.
    // The drawer is likely within a child scaffold, so we add the standard bottom nav height (kBottomNavigationBarHeight) + safe area.
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16;

    return Drawer(
      backgroundColor: isDark
          ? AppColors.darkBgPrimary
          : AppColors.lightBgPrimary,
      child: Stack(
        children: [
          const OrbBackgroundWidget(),
          Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 24,
                  bottom: 24,
                  left: 24,
                  right: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5B21B6), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ProfileAvatar(
                        imageUrl: opt.imageUrl,
                        localImageBytes: opt.localBytes,
                        isUploading: opt.isUploading,
                        userName: userName,
                        radius: 28,
                        fallbackAsset: 'assets/images/3d/avatar_character.png',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(top: 16, bottom: bottomPadding),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _DrawerMenuItem(
                      icon: Icons.person_outline,
                      label: 'My Profile',
                      onTap: () {
                        context.pop();
                        context.go(AppRoutes.buyerProfile);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.shopping_bag_outlined,
                      label: 'My Orders',
                      onTap: () {
                        context.pop();
                        context.push(AppRoutes.buyerOrders);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.favorite_border,
                      label: 'Wishlist',
                      onTap: () {
                        context.pop();
                        context.push(AppRoutes.buyerWishlist);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.location_on_outlined,
                      label: 'Shipping Addresses',
                      onTap: () {
                        context.pop();
                        context.push(AppRoutes.buyerAddresses);
                      },
                    ),

                    const Divider(height: 32),
                    _DrawerMenuItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () {
                        context.pop();
                        context.push(AppRoutes.buyerAccountSettings);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      onTap: () {
                        context.pop();
                        context.push(AppRoutes.buyerHelp);
                      },
                    ),
                    const Divider(height: 32),
                    if (user != null)
                      _DrawerMenuItem(
                        icon: Icons.logout,
                        label: 'Logout',
                        color: const Color(0xFFEF4444),
                        onTap: () async {
                          context.pop();
                          await ref
                              .read(authControllerProvider.notifier)
                              .executeLogoutSequence();
                        },
                      )
                    else
                      _DrawerMenuItem(
                        icon: Icons.login,
                        label: 'Login',
                        color: AppColors.primary,
                        onTap: () {
                          context.pop();
                          context.go(AppRoutes.login);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: bottomPadding - 16,
            right: -20,
            child: FloatingProductWidget(
              floatHeight: 8,
              child: Image.asset(
                'assets/images/3d/hero_gift.png',
                width: 100,
                height: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemColor =
        color ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: itemColor),
      title: Text(
        label,
        style: TextStyle(
          color: itemColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond,
      ),
      onTap: onTap,
    );
  }
}
