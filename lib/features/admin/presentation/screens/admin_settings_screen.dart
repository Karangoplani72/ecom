// lib/features/admin/presentation/screens/admin_settings_screen.dart
//
// Platform Settings (route: /admin/settings)
// System-wide configuration, modeled after `PlatformConfig` in
// domain/entities/platform_config.dart (commission rate, per-category
// overrides, maintenance mode, global rate limit). PLACEHOLDER: toggles and
// fields below hold local sample state only and are not persisted — wire
// to an `AdminSettingsRepository.updatePlatformConfig()` use case.

import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  double _commissionRate = 8.5;
  bool _maintenanceMode = false;
  int _rateLimit = 600;

  final _categoryOverrides = const {
    'Electronics': 6.0,
    'Fashion': 10.0,
    'Grocery': 4.0,
  };

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Platform Settings',
      subtitle: 'Commission rates, platform controls and access',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const AdminSampleDataNotice(
            message:
                'Values below are local placeholders for layout preview — nothing here is saved yet.',
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Commission & Payouts',
            subtitle: 'Default platform commission and category overrides',
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Default commission rate',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${_commissionRate.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Slider(
                value: _commissionRate,
                min: 0,
                max: 25,
                divisions: 50,
                label: '${_commissionRate.toStringAsFixed(1)}%',
                onChanged: (v) => setState(() => _commissionRate = v),
              ),
              const SizedBox(height: 8),
              Text(
                'Category overrides',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ..._categoryOverrides.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.key)),
                      Text(
                        '${e.value.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => showPlaceholderActionSnack(
                          context,
                          'Edit ${e.key} commission',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    showPlaceholderActionSnack(context, 'Add category override'),
                icon: const Icon(Icons.add),
                label: const Text('Add category override'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Platform Controls',
            subtitle: 'Maintenance mode and API rate limiting',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Maintenance mode'),
                subtitle: const Text(
                  'Temporarily block buyer/seller access for scheduled maintenance',
                ),
                value: _maintenanceMode,
                onChanged: (v) => setState(() => _maintenanceMode = v),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Global API rate limit',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '$_rateLimit req/min',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Slider(
                value: _rateLimit.toDouble(),
                min: 100,
                max: 2000,
                divisions: 19,
                label: '$_rateLimit req/min',
                onChanged: (v) => setState(() => _rateLimit = v.round()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Security & Access',
            subtitle: 'Admin roles, two-factor auth and audit logs',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Manage admin roles'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    showPlaceholderActionSnack(context, 'Manage admin roles'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.security_outlined),
                title: const Text('Require 2FA for admin accounts'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    showPlaceholderActionSnack(context, 'Require 2FA'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_outlined),
                title: const Text('View audit log'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    showPlaceholderActionSnack(context, 'View audit log'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Notifications',
            subtitle: 'Alerts sent to the admin team',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('New store applications'),
                value: true,
                onChanged: (_) =>
                    showPlaceholderActionSnack(context, 'Toggle notification'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Critical disputes'),
                value: true,
                onChanged: (_) =>
                    showPlaceholderActionSnack(context, 'Toggle notification'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Weekly platform summary'),
                value: false,
                onChanged: (_) =>
                    showPlaceholderActionSnack(context, 'Toggle notification'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _commissionRate = 8.5;
                    _maintenanceMode = false;
                    _rateLimit = 600;
                  }),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      showPlaceholderActionSnack(context, 'Save settings'),
                  child: const Text('Save changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
