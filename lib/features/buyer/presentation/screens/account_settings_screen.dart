import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/inputs/premium_form_field.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/shared/presentation/navigation/router.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';

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
        content: Text(message, style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFEF4444) : null,
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

  Widget _buildFrostedCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.2),
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18),
        color: isDark ? Colors.white : AppColors.lightTextPrimary,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(currentUserProfileProvider);

    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary,
      body: Stack(
        children: [
          const IgnorePointer(child: OrbBackgroundWidget()),
          profileAsync.when(
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

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    snap: true,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    leadingWidth: 70,
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Center(
                        child: _buildFrostedCircleButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onPressed: () => context.pop(),
                          isDark: isDark,
                        ),
                      ),
                    ),
                    title: Text(
                      'Account Settings',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    centerTitle: true,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Personal Info Label ──
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 12),
                                child: Text(
                                  'Personal Information',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              GlassCardWidget(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    PremiumFormField(
                                      controller: _nameController,
                                      hint: 'Your display name',
                                      label: 'Full Name',
                                      prefixIcon: Icons.person_outline,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Name cannot be empty';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    PremiumFormField(
                                      controller: _phoneController,
                                      hint: 'e.g. +91 98765 43210',
                                      label: 'Phone Number',
                                      prefixIcon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 18),
                                    // Read-only email field
                                    AbsorbPointer(
                                      child: PremiumFormField(
                                        hint: user.email,
                                        label: 'Email Address',
                                        controller: TextEditingController(text: user.email),
                                        prefixIcon: Icons.email_outlined,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8, left: 4),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Email address cannot be changed here.',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: subtitleColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              GradientButton(
                                label: 'Save Changes',
                                isLoading: _isSaving,
                                onTap: _save,
                              ),
                              const SizedBox(height: 36),

                              // ── Address Book ──
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 12),
                                child: Text(
                                  'Address Book',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              GlassCardWidget(
                                padding: EdgeInsets.zero,
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.location_on_outlined,
                                        size: 18,
                                        color: Color(0xFFA855F7),
                                      ),
                                    ),
                                    title: Text(
                                      'Manage Saved Addresses',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                    ),
                                    onTap: () => context.push(AppRoutes.buyerAddresses),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36),

                              // ── Security ──
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 12),
                                child: Text(
                                  'Security',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              GlassCardWidget(
                                padding: EdgeInsets.zero,
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: _isSendingReset
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFFA855F7),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.lock_reset_outlined,
                                              size: 18,
                                              color: Color(0xFFA855F7),
                                            ),
                                    ),
                                    title: Text(
                                      'Change Password',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Send password reset link to email',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: subtitleColor,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                    ),
                                    onTap: _isSendingReset ? null : _sendPasswordReset,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36),

                              // ── Account actions ──
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 12),
                                child: Text(
                                  'Account Actions',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await ref
                                        .read(authControllerProvider.notifier)
                                        .executeLogoutSequence();
                                    if (!context.mounted) return;
                                    context.go(AppRoutes.login);
                                  },
                                  icon: const Icon(Icons.logout, size: 18),
                                  label: Text(
                                    'Logout',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(color: Color(0xFFEF4444)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
