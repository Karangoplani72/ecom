import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';

class BuyerShellScreen extends ConsumerWidget {
  final Widget child;

  const BuyerShellScreen({
    super.key,
    required this.child,
  });

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/buyer/products')) {
      return 1;
    }

    if (location.startsWith('/buyer/menu')) {
      return 2;
    }

    if (location.startsWith('/buyer/profile')) {
      return 3;
    }

    return 0;
  }

  void _onDestinationSelected(
    BuildContext context,
    int index,
  ) {
    switch (index) {
      case 0:
        context.go('/buyer/home');
        break;

      case 1:
        context.go('/buyer/products');
        break;

      case 2:
        context.go('/buyer/menu');
        break;

      case 3:
        context.go('/buyer/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = _calculateIndex(context);

    final cartAsync = ref.watch(cartStreamProvider);
    final cartCount = cartAsync.value?.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        ) ??
        0;

    final navItems = [
      _NavItemData(
        icon: Icons.home_rounded,
        label: 'Home',
      ),
      _NavItemData(
        icon: Icons.grid_view_rounded,
        label: 'Products',
      ),
      _NavItemData(
        icon: Icons.shopping_bag_rounded,
        label: 'Cart',
        badgeCount: cartCount,
      ),
      _NavItemData(
        icon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.80),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  final isSelected = currentIndex == index;
                  final unselectedColor =
                      isDark ? Colors.white54 : Colors.black45;

                  return GestureDetector(
                    onTap: () => _onDestinationSelected(context, index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 16 : 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                item.icon,
                                color: isSelected
                                    ? Colors.white
                                    : unselectedColor,
                                size: 24,
                              ),
                              if (item.badgeCount > 0)
                                Positioned(
                                  right: -8,
                                  top: -8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEC4899),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${item.badgeCount}',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Text(
                              item.label,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final int badgeCount;

  _NavItemData({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });
}