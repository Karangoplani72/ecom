import 'package:ecom/core/providers/theme_provider.dart';
import 'package:ecom/core/providers/categories_provider.dart';
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
  Map<String, double> _categoryOverrides = {};
  bool _maintenanceMode = false;
  int _rateLimitPerMinute = 600;
  String _razorpayKey = 'rzp_test_placeholder_key';
  late TextEditingController _razorpayKeyController;
  late TextEditingController _announcementController;
  String _featuredCategory = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _razorpayKeyController = TextEditingController();
    _announcementController = TextEditingController();
    _loadConfig();
  }

  @override
  void dispose() {
    _razorpayKeyController.dispose();
    _announcementController.dispose();
    super.dispose();
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
        _categoryOverrides = Map<String, double>.from(config.categoryCommissionOverrides);
        _maintenanceMode = config.maintenanceModeActive;
        _rateLimitPerMinute = config.globalRateLimitPerMinute;
        _razorpayKey = config.razorpayKey;
        _razorpayKeyController.text = config.razorpayKey;
        _announcementController.text = config.announcementText;
        _featuredCategory = config.featuredCategory;
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
            categoryCommissionOverrides: _categoryOverrides,
            maintenanceModeActive: _maintenanceMode,
            globalRateLimitPerMinute: _rateLimitPerMinute,
            razorpayKey: _razorpayKey,
            announcementText: _announcementController.text,
            featuredCategory: _featuredCategory,
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

          // ── Category Commission Overrides ────────────────────────────────
          _SectionHeader('Category Commission Overrides'),
          Consumer(
            builder: (context, ref, _) {
              final categoriesAsync = ref.watch(activeCategoriesStreamProvider);
              return categoriesAsync.when(
                data: (categories) {
                  return AdminSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Set custom commission rates for specific categories. If disabled, the default commission rate applies.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        for (final category in categories) ...[
                          _CategoryOverrideRow(
                            category: category,
                            rate: _categoryOverrides[category] ?? _commissionRate,
                            isOverridden: _categoryOverrides.containsKey(category),
                            onChanged: (double? newRate) {
                              setState(() {
                                if (newRate == null) {
                                  _categoryOverrides.remove(category);
                                } else {
                                  _categoryOverrides[category] = newRate;
                                }
                              });
                            },
                          ),
                          if (category != categories.last) const Divider(),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading categories: $e'),
              );
            },
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

          // ── Announcement & Marketing ──────────────────────────
          _SectionHeader('Announcement & Marketing'),
          AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Announcement Banner Text',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _announcementController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Flash Sale Live! Use code FLASH50 for 50% off.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Featured Category ID/Name',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);
                    return categoriesAsync.maybeWhen(
                      data: (categories) {
                        return DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: categories.contains(_featuredCategory) ? _featuredCategory : null,
                          hint: const Text('Select a category to feature'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('None (Disable Feature)'),
                            ),
                            for (final category in categories)
                              DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                          ],
                          onChanged: (val) {
                            setState(() => _featuredCategory = val ?? '');
                          },
                        );
                      },
                      orElse: () => const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Razorpay Configuration ──────────────────────────────────────
          _SectionHeader('Razorpay Configuration'),
          AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security, color: AppColors.success),
                    const SizedBox(width: 12),
                    Text(
                      'Managed via Cloud Functions',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Razorpay API keys are securely managed within Firebase Cloud Functions and are not stored in the database.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
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

class _CategoryOverrideRow extends StatelessWidget {
  final String category;
  final double rate;
  final bool isOverridden;
  final ValueChanged<double?> onChanged;

  const _CategoryOverrideRow({
    required this.category,
    required this.rate,
    required this.isOverridden,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              if (isOverridden)
                Text(
                  '${(rate * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
              else
                const Text(
                  'Default',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              const SizedBox(width: 12),
              Switch(
                value: isOverridden,
                onChanged: (enabled) {
                  if (enabled) {
                    onChanged(0.085); // Set to default initial override
                  } else {
                    onChanged(null); // Clear override
                  }
                },
              ),
            ],
          ),
          if (isOverridden) ...[
            const SizedBox(height: 4),
            Slider(
              value: rate,
              min: 0.01,
              max: 0.50,
              divisions: 49,
              label: '${(rate * 100).toStringAsFixed(1)}%',
              onChanged: (v) => onChanged(v),
            ),
          ],
        ],
      ),
    );
  }
}
