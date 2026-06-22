import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool isDark;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
    this.isDark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF6A5ACD)).withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    final interactiveCard = onTap != null
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: cardContent,
            ),
          )
        : cardContent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: interactiveCard,
      ),
    );
  }
}
