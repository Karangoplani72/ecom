import 'package:ecom/core/constants/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
        children: [
          // ── App identity ──
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shopping_bag_outlined,
                      size: 56, color: colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  AppInfo.appName,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version ${AppInfo.version}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your trusted local marketplace — connecting buyers\nwith verified sellers across India.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // ── Contact ──
          _SectionLabel(title: 'Contact'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: _LeadingIcon(icon: Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: const Text(AppInfo.supportEmail),
                  trailing: const Icon(Icons.copy, size: 16),
                  onTap: () => _copyToClipboard(
                      context, AppInfo.supportEmail, 'Email copied'),
                ),
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: colorScheme.outlineVariant),
                ListTile(
                  leading: _LeadingIcon(icon: Icons.phone_outlined),
                  title: const Text('Phone'),
                  subtitle: const Text(AppInfo.supportPhone),
                  trailing: const Icon(Icons.copy, size: 16),
                  onTap: () => _copyToClipboard(
                      context, AppInfo.supportPhone, 'Phone number copied'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Legal ──
          _SectionLabel(title: 'Legal'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: _LeadingIcon(icon: Icons.policy_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => _copyToClipboard(
                      context, AppInfo.privacyPolicyUrl, 'Link copied'),
                ),
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: colorScheme.outlineVariant),
                ListTile(
                  leading: _LeadingIcon(icon: Icons.description_outlined),
                  title: const Text('Terms & Conditions'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => _copyToClipboard(
                      context, AppInfo.termsUrl, 'Link copied'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              '© 2025 ${AppInfo.appName}. All rights reserved.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(
      BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final IconData icon;
  const _LeadingIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: colorScheme.onSurface),
    );
  }
}
