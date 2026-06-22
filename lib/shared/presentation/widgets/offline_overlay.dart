import 'package:flutter/material.dart';
import 'package:ecom/core/theme/app_colors.dart';

class OfflineOverlay extends StatelessWidget {
  const OfflineOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing/Neumorphic WiFi Off Icon Container
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBgSurface.withValues(alpha: 0.8)
                        : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Heading
                Text(
                  'No Internet Connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  'Please turn on internet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
