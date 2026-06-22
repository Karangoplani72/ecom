import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Icon Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppConfigTheme.primaryColor(isDark).withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppConfigTheme.primaryColor(isDark).withValues(alpha: 0.1),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.build_circle_outlined,
                  size: 80,
                  color: AppConfigTheme.primaryColor(isDark),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Under Scheduled Maintenance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                'LuxeMarket is currently undergoing maintenance to perform system upgrades. We will be back online shortly. Thank you for your patience!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond,
                ),
              ),
              const SizedBox(height: 40),

              // Controls / Admin Switch
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).executeLogoutSequence();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  'Sign Out / Login as Admin',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple helper class to safely match Theme settings
class AppConfigTheme {
  static Color primaryColor(bool isDark) {
    return AppColors.primary;
  }
}
