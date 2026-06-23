import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/features/marketplace/presentation/controllers/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => ref
                .read(notificationControllerProvider.notifier)
                .markAllAsRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: ResponsiveLayout(
        maxWidth: 800,
        child: notificationsAsync.when(
          loading: () => const AppLoadingView(),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const AppEmptyView(
                title: 'No notifications',
                subtitle: 'We will notify you about your order updates here.',
                icon: Icons.notifications_none_outlined,
              );
            }

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notif.isRead
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.primaryContainer,
                      child: Icon(
                        Icons.notifications_outlined,
                        color: notif.isRead
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: notif.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notif.body),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, h:mm a').format(notif.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      ref
                          .read(notificationControllerProvider.notifier)
                          .markAsRead(notif.id);
                      if (notif.deepLinkPath.isNotEmpty) {
                        context.push(notif.deepLinkPath);
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
