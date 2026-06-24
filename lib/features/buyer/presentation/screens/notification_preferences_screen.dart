import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool orderUpdates = true;
  bool promotions = false;
  bool chatMessages = true;
  bool systemAlerts = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            title: 'Order Updates',
            subtitle: 'Get notified when your order status changes',
            value: orderUpdates,
            onChanged: (val) => setState(() => orderUpdates = val),
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Promotions & Offers',
            subtitle: 'Receive special discounts and sale alerts',
            value: promotions,
            onChanged: (val) => setState(() => promotions = val),
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Chat Messages',
            subtitle: 'Stay updated when sellers reply to your messages',
            value: chatMessages,
            onChanged: (val) => setState(() => chatMessages = val),
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'System Alerts',
            subtitle: 'Important account and security notifications',
            value: systemAlerts,
            onChanged: (val) => setState(() => systemAlerts = val),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
