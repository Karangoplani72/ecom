import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_primary_button.dart';

import 'package:ecom/core/widgets/scaffolds/premium_25d_scaffold.dart';
import 'package:ecom/core/widgets/cards/glass_card.dart';
import 'package:ecom/core/widgets/inputs/premium_form_field.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/shared/presentation/navigation/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ecom/features/buyer/presentation/widgets/buyer_side_drawer.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;
  bool _isSendingReset = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final success = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          displayName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          onFailure: (msg) => _showSnack(msg, isError: true),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) _showSnack('Profile updated successfully');
  }

  Future<void> _sendPasswordReset() async {
    setState(() => _isSendingReset = true);

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(onFailure: (msg) => _showSnack(msg, isError: true));

    if (!mounted) return;
    setState(() => _isSendingReset = false);
    if (success) {
      final email = ref.read(currentUserProfileProvider).value?.email ?? '';
      _showSnack('Password reset link sent to $email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Premium25DScaffold(
      isDark: theme.brightness == Brightness.dark,
      drawer: const BuyerSideDrawer(),
      appBar: AppBar(title: const Text('Account Settings'), centerTitle: true, backgroundColor: Colors.transparent, elevation: 0),
      body: profileAsync.when(
        loading: () => const AppLoadingView(),
        error: (err, _) => AppErrorView(
          message: 'Error loading settings: $err',
          onRetry: () => ref.invalidate(currentUserProfileProvider),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User profile not found.'));
          }

          if (_nameController.text.isEmpty && _phoneController.text.isEmpty) {
            _nameController.text = user.displayName;
            _phoneController.text = user.phoneNumber ?? '';
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              children: [
                // ── Personal info ──
                Text(
                  'Personal Information',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                PremiumFormField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Your display name',
                  prefixIcon: Icons.person_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PremiumFormField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'e.g. +91 98765 43210',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                // Email — read only
                AbsorbPointer(
                  child: PremiumFormField(
                    label: 'Email Address',
                    hint: user.email,
                    controller: TextEditingController(text: user.email),
                    prefixIcon: Icons.email_outlined,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Email address cannot be changed here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                AppPrimaryButton(
                  text: 'Save Changes',
                  isLoading: _isSaving,
                  onPressed: _save,
                ),

                const SizedBox(height: 36),
                Divider(color: colorScheme.outlineVariant),
                const SizedBox(height: 24),

                // ── Addresses ──
                Text(
                  'Address Book',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  isDark: theme.brightness == Brightness.dark,
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    title: const Text('Manage Saved Addresses'),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.push(AppRoutes.buyerAddresses),
                  ),
                ),

                const SizedBox(height: 36),
                Divider(color: colorScheme.outlineVariant),
                const SizedBox(height: 24),

                // ── Security ──
                Text(
                  'Security',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  isDark: theme.brightness == Brightness.dark,
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isSendingReset
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          : Icon(
                              Icons.lock_reset_outlined,
                              size: 20,
                              color: colorScheme.onSurface,
                            ),
                    ),
                    title: const Text('Change Password'),
                    subtitle: const Text(
                      'Send a password-reset link to your email',
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: _isSendingReset ? null : _sendPasswordReset,
                  ),
                ),

                const SizedBox(height: 36),
                Divider(color: colorScheme.outlineVariant),
                const SizedBox(height: 24),

                // ── Danger zone ──
                Text(
                  'Account',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(authControllerProvider.notifier)
                          .executeLogoutSequence();
                      if (!context.mounted) return;
                      context.go(AppRoutes.login);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
