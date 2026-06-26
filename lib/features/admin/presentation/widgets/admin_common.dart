// lib/features/admin/presentation/widgets/admin_common.dart
//
// Small, reusable presentational pieces shared by the admin screens:
// metric cards, section cards, status pills, and a "sample data" notice
// banner that flags screens which are still wired to placeholder data
// rather than live Firestore/backend sources.

import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Metric card — used for the stat rows at the top of each screen
// ─────────────────────────────────────────────────────────────
class AdminMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final VoidCallback? onTap;

  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadius.borderLG,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: AppRadius.borderSM,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (trend != null)
                  Text(
                    trend!,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      card = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Responsive grid wrapper so screens don't repeat the LayoutBuilder logic.
class AdminMetricGrid extends StatelessWidget {
  final List<AdminMetricCard> metrics;

  const AdminMetricGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: crossAxisCount >= 4 ? 1.55 : 1.4,
          ),
          itemCount: metrics.length,
          itemBuilder: (_, i) => metrics[i],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section card — generic content container matching the seller portal
// ─────────────────────────────────────────────────────────────
class AdminSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AdminSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: AppRadius.borderLG,
      elevation: isDark ? 2 : 1,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
      child: Container(width: double.infinity, padding: padding, child: child),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Status pill — color-coded chip for statuses/priorities
// ─────────────────────────────────────────────────────────────
class AdminStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const AdminStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sample-data notice — flags that a screen shows placeholder content
// ─────────────────────────────────────────────────────────────
class AdminSampleDataNotice extends StatelessWidget {
  final String message;

  const AdminSampleDataNotice({
    super.key,
    this.message =
        'Showing sample data for layout preview — this screen is not yet connected to live backend data.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state row — small inline empty state used inside lists
// ─────────────────────────────────────────────────────────────
class AdminEmptyRow extends StatelessWidget {
  final IconData icon;
  final String message;

  const AdminEmptyRow({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: AppColors.lightTextSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a consistent "not wired up yet" snackbar for placeholder actions
/// (approve/reject/suspend buttons etc.) until real use cases exist.
void showPlaceholderActionSnack(BuildContext context, String action) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$action — coming soon, not yet connected to backend.'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
