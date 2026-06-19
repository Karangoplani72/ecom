import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_shadows.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool isGlass;
  final bool isElevated;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.isGlass = false,
    this.isElevated = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) {
    _controller.reverse();
    widget.onTap?.call();
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(24);

    Widget content = Padding(
      padding: widget.padding ?? const EdgeInsets.all(24),
      child: widget.child,
    );

    if (widget.isGlass) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05) 
                  : Colors.white.withValues(alpha: 0.4),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: borderRadius,
            ),
            child: content,
          ),
        ),
      );
    } else {
      content = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: borderRadius,
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : theme.dividerColor,
          ),
          boxShadow: widget.isElevated
              ? (_isHovered
                  ? (isDark ? AppShadows.darkLg : AppShadows.lightLg)
                  : (isDark ? AppShadows.darkMd : AppShadows.lightMd))
              : [],
        ),
        child: content,
      );
    }

    if (widget.onTap != null) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}