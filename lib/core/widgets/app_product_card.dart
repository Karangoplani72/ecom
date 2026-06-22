import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_network_image.dart';
import 'app_price_text.dart';
import 'cards/glass_card.dart';

class AppProductCard extends StatefulWidget {
  final String title;
  final String imageUrl;
  final double rating;
  final double price;
  final VoidCallback onTap;

  const AppProductCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.price,
    required this.onTap,
  });

  @override
  State<AppProductCard> createState() => _AppProductCardState();
}

class _AppProductCardState extends State<AppProductCard>
    with SingleTickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) =>
                Transform.scale(scale: _scaleAnimation.value, child: child),
            child: GlassCard(
              isDark: isDark,
              padding: EdgeInsets.zero,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final imageHeight = constraints.maxHeight * 0.65;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: Matrix4.diagonal3Values(
                              _isHovered ? 1.05 : 1.0,
                              _isHovered ? 1.05 : 1.0,
                              1.0,
                            ),
                            transformAlignment: Alignment.center,
                            child: AppNetworkImage(
                              imageUrl: widget.imageUrl,
                              width: double.infinity,
                              height: imageHeight,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark ? Colors.black : Colors.white)
                                            .withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.favorite_border,
                                    size: 14,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  height: 1.2,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Price',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        AppPriceText(
                                          amount: widget.price,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 11,
                                          color: AppColors.warning,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          widget.rating.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
