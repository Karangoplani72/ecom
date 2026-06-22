import 'package:flutter/material.dart';
import 'cards/glass_card.dart';

class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool locked;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Opacity(
      opacity: locked ? 0.45 : 1.0,
      child: GlassCard(
        isDark: theme.brightness == Brightness.dark,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Icon(icon, size: 24, color: colorScheme.primary),
                    if (locked)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Icon(
                          Icons.lock,
                          size: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
