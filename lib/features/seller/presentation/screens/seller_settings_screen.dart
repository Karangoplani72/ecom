import 'package:ecom/core/providers/theme_provider.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/core/widgets/app_text_field.dart';
import 'package:ecom/features/seller/presentation/controllers/seller_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SellerSettingsScreen extends ConsumerStatefulWidget {
  const SellerSettingsScreen({super.key});

  @override
  ConsumerState<SellerSettingsScreen> createState() => _SellerSettingsScreenState();
}

class _SellerSettingsScreenState extends ConsumerState<SellerSettingsScreen> {
  final _addressController = TextEditingController();
  bool _emailNotifications = true;
  bool _orderUpdates = true;
  bool _initialized = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _initFields(dynamic store) {
    if (_initialized) return;
    _addressController.text = store.address ?? '';
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(sellerControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/seller/dashboard'),
        ),
        title: const Text('Store Settings'),
        centerTitle: true,
      ),
      body: storeState.when(
        loading: () => const AppLoadingView(),
        error: (err, _) => AppErrorView(
          message: 'Error loading settings: $err',
          onRetry: () => ref.invalidate(sellerControllerProvider),
        ),
        data: (store) {
          if (store == null) {
            return const Center(child: Text('No store profile loaded.'));
          }

          _initFields(store);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Store Status Pausing Card
              Card(
                elevation: 0,
                color: store.isActive
                    ? Colors.green.withValues(alpha: 0.08)
                    : Colors.red.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: store.isActive
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            store.isActive ? 'Storefront is Online' : 'Storefront is Offline/Paused',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: store.isActive ? Colors.green : Colors.red,
                            ),
                          ),
                          Switch.adaptive(
                            value: store.isActive,
                            activeThumbColor: Colors.green,
                            onChanged: (val) async {
                              await ref
                                  .read(sellerControllerProvider.notifier)
                                  .patchStoreSettings({'isActive': val});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        store.isActive
                            ? 'Your store is active. Customers can browse and purchase your listed products.'
                            : 'Your store is currently paused. Products will be hidden from searches and buyers cannot check out.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Verification Status Section
              _buildSectionHeader('Verification & Status', theme),
              ListTile(
                leading: const Icon(Icons.verified_rounded, color: Colors.blue),
                title: const Text('Store Verification'),
                subtitle: Text('Status: ${store.status.name.toUpperCase()}'),
                trailing: store.isVerified
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.pending, color: Colors.orange),
              ),
              const Divider(),

              // Warehouse Logistics Address
              const SizedBox(height: 16),
              _buildSectionHeader('Logistics & Shipping', theme),
              const SizedBox(height: 12),
              AppTextField(
                controller: _addressController,
                label: 'Pickup Address (For Delivery Agents)',
                hint: 'Enter your warehouse or store physical address...',
                maxLines: 3,
                prefixIcon: Icons.local_shipping_outlined,
              ),
              const SizedBox(height: 16),
              AppPrimaryButton(
                text: 'Update Pickup Address',
                isLoading: storeState.isLoading,
                onPressed: () async {
                  await ref
                      .read(sellerControllerProvider.notifier)
                      .patchStoreSettings({'address': _addressController.text.trim()});

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pickup address updated successfully!')),
                    );
                  }
                },
              ),
              const SizedBox(height: 32),

              // Notification Preferences
              _buildSectionHeader('Notifications', theme),
              SwitchListTile.adaptive(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive invoices and payout statements by email'),
                value: _emailNotifications,
                onChanged: (val) => setState(() => _emailNotifications = val),
              ),
              SwitchListTile.adaptive(
                title: const Text('New Order Alerts'),
                subtitle: const Text('Receive push alerts when customers make a purchase'),
                value: _orderUpdates,
                onChanged: (val) => setState(() => _orderUpdates = val),
              ),
              const SizedBox(height: 32),

              // Appearance
              _buildSectionHeader('Appearance', theme),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, _) {
                  final themeMode = ref.watch(themeProvider);
                  return Row(
                    children: [
                      for (final opt in [
                        (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
                        (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
                        (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _ThemeOption(
                              icon: opt.$2,
                              label: opt.$3,
                              selected: themeMode == opt.$1,
                              onTap: () => ref
                                  .read(themeProvider.notifier)
                                  .setThemeMode(opt.$1),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
