import 'dart:ui';

import 'package:ecom/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable AppBar with transparent blurred background and properly visible text
/// Matches the design from BuyerHomeScreen
class BlurAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showLeading;
  final VoidCallback? onLeadingTap;
  final bool isDark;
  final bool automaticallyImplyLeading;

  const BlurAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showLeading = true,
    this.onLeadingTap,
    required this.isDark,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      floating: true,
      pinned: true,
      snap: true,
      leading: showLeading && automaticallyImplyLeading
          ? Builder(
              builder: (context) {
                return IconButton(
                  icon: _buildLeadingIcon(isDark),
                  onPressed:
                      onLeadingTap ?? () => Scaffold.of(context).openDrawer(),
                );
              },
            )
          : null,

      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty)
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? Colors.white70 : AppColors.lightTextSecond,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      centerTitle: false,
      actions: actions,
      expandedHeight: 80,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        AppColors.darkBgPrimary.withValues(alpha: 0.95),
                        AppColors.darkBgPrimary.withValues(alpha: 0.7),
                      ]
                    : [
                        AppColors.lightBgPrimary.withValues(alpha: 0.95),
                        AppColors.lightBgPrimary.withValues(alpha: 0.7),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(bool isDark) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.15),
        ),
      ),
      child: Icon(
        Icons.menu_rounded,
        size: 18,
        color: isDark ? Colors.white : AppColors.lightTextPrimary,
      ),
    );
  }
}

/// A regular AppBar version for scaffolds that don't use slivers
class BlurAppBarRegular extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showLeading;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double elevation;
  final bool isDark;

  const BlurAppBarRegular({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showLeading = true,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation = 0,
    required this.isDark,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty)
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? Colors.white70 : AppColors.lightTextSecond,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      centerTitle: false,
      actions: actions,
      elevation: elevation,
      backgroundColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Blurred background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              AppColors.darkBgPrimary.withValues(alpha: 0.95),
                              AppColors.darkBgPrimary.withValues(alpha: 0.7),
                            ]
                          : [
                              AppColors.lightBgPrimary.withValues(alpha: 0.95),
                              AppColors.lightBgPrimary.withValues(alpha: 0.7),
                            ],
                    ),
                  ),
                ),
              ),
              // Optional: Add a subtle overlay for better text readability
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.transparent,
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
