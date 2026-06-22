import 'package:flutter/material.dart';
import 'package:ecom/core/widgets/cards/glass_card.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 8),
      child: GlassCard(
        isDark: isDark,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home', theme),
            _buildNavItem(1, Icons.grid_view_outlined, Icons.grid_view, 'Products', theme),
            _buildNavItem(2, Icons.person_outline, Icons.person, 'Profile', theme),
            _buildNavItem(3, Icons.menu, Icons.menu, 'Menu', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, ThemeData theme) {
    final isSelected = currentIndex == index;
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}