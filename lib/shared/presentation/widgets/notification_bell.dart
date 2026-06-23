import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecom/features/marketplace/presentation/controllers/notification_controller.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/constants/app_radius.dart';

class NotificationBell extends ConsumerWidget {
  final Color? color;
  final bool isStyledContainer;

  const NotificationBell({
    super.key,
    this.color,
    this.isStyledContainer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unreadCount = notificationsAsync.maybeWhen(
      data: (list) => list.where((n) => !n.isRead).length,
      orElse: () => 0,
    );

    final iconColor = color ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    final iconWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.notifications_outlined,
          color: isStyledContainer ? null : iconColor,
          size: isStyledContainer ? 22 : 26,
        ),
        if (unreadCount > 0)
          Positioned(
            right: isStyledContainer ? -2 : -2,
            top: isStyledContainer ? -2 : -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary,
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              child: Center(
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );

    String currentPath = '';
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (_) {}

    final String notificationPath;
    if (currentPath.startsWith('/admin')) {
      notificationPath = '/admin/notifications';
    } else if (currentPath.startsWith('/seller')) {
      notificationPath = '/seller/notifications';
    } else {
      notificationPath = '/buyer/notifications';
    }

    if (isStyledContainer) {
      return GestureDetector(
        onTap: () => context.push(notificationPath),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.borderMD,
          ),
          child: Center(child: iconWidget),
        ),
      );
    }

    return IconButton(
      icon: iconWidget,
      onPressed: () => context.push(notificationPath),
    );
  }
}
