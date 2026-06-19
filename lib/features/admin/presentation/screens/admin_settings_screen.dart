import 'package:ecom/core/providers/theme_provider.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/domain/entities/platform_config.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  double _commissionRate = 0.085;
  bool _maintenanceMode = false;
  int _rateLimitPerMinute = 600;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final result = await ref
        .read(adminRepositoryProvider)
        .fetchSystemGlobalConfigurations();
    if (!mounted) return;
    result.fold(
      (err) => setState(() => _loading = false),
      (config) => setState(() {
        _commissionRate = config.defaultCommissionRate;
        _maintenanceMode = config.maintenanceModeActive;
        _rateLimitPerMinute = config.globalRateLimitPerMinute;
        _loading = false;
      }),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref
        .read(adminRepositoryProvider)
        .savePlatformConfig(
          PlatformConfig(
            defaultCommissionRate: _commissionRate,
            categoryCommissionOverrides: const {},
            maintenanceModeActive: _maintenanceMode,
            globalRateLimitPerMinute: _rateLimitPerMinute,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (err) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Platform settings saved')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (_loading) {
      return const AdminScaffold(
        title: 'Platform Settings',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AdminScaffold(
      title: 'Platform Settings',
      subtitle: 'Commission, maintenance mode and appearance',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // ── Commission ──────────────────────────────────────────────────
          _SectionHeader('Commission'),
          AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Default commission rate',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${(_commissionRate * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _commissionRate,
                  min: 0.01,
                  max: 0.30,
                  divisions: 29,
                  label: '${(_commissionRate * 100).toStringAsFixed(1)}%',
                  onChanged: (v) => setState(() => _commissionRate = v),
                ),
                Text(
                  'Platform earns ${(_commissionRate * 100).toStringAsFixed(1)}% of every successful order.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Maintenance Mode ─────────────────────────────────────────────
          _SectionHeader('Platform Status'),
          AdminSectionCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Maintenance Mode',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'When enabled, only admins can access the platform. All buyers and sellers see a maintenance page.',
              ),
              value: _maintenanceMode,
              onChanged: (v) => setState(() => _maintenanceMode = v),
              activeThumbColor: AppColors.error,
            ),
          ),
          if (_maintenanceMode)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AdminSectionCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Maintenance mode is ACTIVE. Buyers and sellers cannot access the platform.',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          // ── Rate Limit ───────────────────────────────────────────────────
          _SectionHeader('API Rate Limiting'),
          AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Requests per minute',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '$_rateLimitPerMinute',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _rateLimitPerMinute.toDouble(),
                  min: 60,
                  max: 2400,
                  divisions: 39,
                  label: '$_rateLimitPerMinute/min',
                  onChanged: (v) =>
                      setState(() => _rateLimitPerMinute = v.toInt()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Appearance ───────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme Mode',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final themeMode = ref.watch(themeProvider);
                    return Row(
                      children: [
                        for (final option in [
                          (ThemeMode.system, Icons.brightness_auto_rounded,
                              'System'),
                          (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
                          (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
                        ])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _ThemeChip(
                                icon: option.$2,
                                label: option.$3,
                                selected: themeMode == option.$1,
                                onTap: () => ref
                                    .read(themeProvider.notifier)
                                    .setThemeMode(option.$1),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Save ─────────────────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving...' : 'Save Settings'),
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.lightTextSecondary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                color: selected
                    ? AppColors.primary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
