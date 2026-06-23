import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../controllers/seller_application_controller.dart';
import '../../domain/entities/seller_application.dart';

class SellerApplicationScreen extends ConsumerStatefulWidget {
  const SellerApplicationScreen({super.key});

  @override
  ConsumerState<SellerApplicationScreen> createState() =>
      _SellerApplicationScreenState();
}

class _SellerApplicationScreenState
    extends ConsumerState<SellerApplicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _accountHolderNameController = TextEditingController();

  String? _selectedCategory;
  bool _hasPrefilled = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _storeNameController.dispose();
    _gstController.dispose();
    _descriptionController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _accountHolderNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref
        .read(sellerApplicationControllerProvider.notifier)
        .submit(
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          storeName: _storeNameController.text.trim(),
          businessCategory: _selectedCategory!,
          gstNumber: _gstController.text.trim(),
          description: _descriptionController.text.trim(),
          bankName: _bankNameController.text.trim(),
          accountNumber: _accountNumberController.text.trim(),
          ifscCode: _ifscCodeController.text.trim(),
          accountHolderName: _accountHolderNameController.text.trim(),
        );

    if (!mounted) return;

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Application submitted successfully!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appAsync = ref.watch(userSellerApplicationProvider);
    final controllerState = ref.watch(sellerApplicationControllerProvider);
    final isLoading = controllerState.isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen<AsyncValue<SellerApplication?>>(userSellerApplicationProvider, (previous, next) {
      if (next.hasValue && next.value != null && !_hasPrefilled) {
        final app = next.value!;
        if (app.status == 'rejected' || app.status == 'changes_requested') {
          _fullNameController.text = app.fullName;
          _phoneController.text = app.phoneNumber;
          _storeNameController.text = app.storeName;
          _gstController.text = app.gstNumber ?? '';
          _descriptionController.text = app.storeDescription;
          _bankNameController.text = app.bankName ?? '';
          _accountNumberController.text = app.accountNumber ?? '';
          _ifscCodeController.text = app.ifscCode ?? '';
          _accountHolderNameController.text = app.accountHolderName ?? '';
          setState(() {
            _selectedCategory = app.businessCategory;
            _hasPrefilled = true;
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Become a Seller'), centerTitle: true),
      body: SafeArea(
        child: appAsync.when(
          loading: () => const AppLoadingView(),
          error: (err, _) => Center(
            child: Text('Error loading application: $err', style: TextStyle(color: colorScheme.error)),
          ),
          data: (application) {
            // Check if there is an active/approved application
            if (application != null && application.status == 'approved') {
              return _buildApprovedView(theme, colorScheme);
            }

            // Check if pending
            if (application != null && application.status == 'pending') {
              return _buildPendingView(application, theme, colorScheme);
            }

            // For none, rejected, changes_requested: Show Form
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (application != null && application.status == 'changes_requested')
                          _buildChangesRequestedBanner(application, theme, colorScheme)
                        else if (application != null && application.status == 'rejected')
                          _buildRejectedBanner(application, theme, colorScheme)
                        else
                          _Header(colorScheme: colorScheme, theme: theme),
                        const SizedBox(height: 32),
                        _SectionLabel(label: 'Personal Information', theme: theme),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          hint: 'e.g. John Doe',
                          prefixIcon: Icons.person_outline,
                          enabled: !isLoading,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Full name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: 'e.g. +91 9876543210',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          enabled: !isLoading,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Phone number is required'
                              : null,
                        ),
                        const SizedBox(height: 32),
                        _SectionLabel(label: 'Business Details', theme: theme),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _storeNameController,
                          label: 'Store Name',
                          hint: 'e.g. Luxe Electronics',
                          prefixIcon: Icons.storefront_outlined,
                          enabled: !isLoading,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Store name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryDropdown(theme, colorScheme, isLoading),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _gstController,
                          label: 'GST Number (Optional)',
                          hint: 'e.g. 22AAAAA0000A1Z5',
                          prefixIcon: Icons.description_outlined,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _descriptionController,
                          label: 'Business Description',
                          hint: 'Describe your products and brand...',
                          maxLines: 4,
                          enabled: !isLoading,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Description is required';
                            }
                            if (v.trim().length < 20) {
                              return 'Please provide at least 20 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        _SectionLabel(label: 'Settlement Bank Account Details', theme: theme),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _bankNameController,
                          label: 'Bank Name',
                          hint: 'e.g. State Bank of India',
                          prefixIcon: Icons.account_balance_outlined,
                          enabled: !isLoading,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Bank name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _accountNumberController,
                          label: 'Account Number',
                          hint: 'e.g. 123456789012',
                          prefixIcon: Icons.payment_outlined,
                          enabled: !isLoading,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Account number is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _ifscCodeController,
                          label: 'IFSC Code',
                          hint: 'e.g. SBIN0001234',
                          prefixIcon: Icons.code_rounded,
                          enabled: !isLoading,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'IFSC code is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _accountHolderNameController,
                          label: 'Account Holder Name',
                          hint: 'e.g. John Doe',
                          prefixIcon: Icons.person_pin_outlined,
                          enabled: !isLoading,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Account holder name is required'
                              : null,
                        ),
                        const SizedBox(height: 32),
                        _DisclaimerCard(colorScheme: colorScheme),
                        const SizedBox(height: 40),
                        AppPrimaryButton(
                          text: application != null ? 'Resubmit Application' : 'Submit Application',
                          isLoading: isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Category',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: InputDecoration(
            hintText: 'Select a category',
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items:
              [
                    'Electronics',
                    'Fashion',
                    'Home',
                    'Beauty',
                    'Sports',
                    'Books',
                    'Other',
                  ]
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
          onChanged: isLoading
              ? null
              : (val) => setState(() => _selectedCategory = val),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Category is required' : null,
        ),
      ],
    );
  }

  Widget _buildPendingView(SellerApplication app, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 64,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Application Pending Review',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We have received your seller application for "${app.storeName}" and it is currently being verified by our administrator team. This usually takes 24-48 hours.',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildTimelineStep('1', 'Application Submitted', 'Done', Colors.green, true),
              _buildTimelineDivider(Colors.green),
              _buildTimelineStep('2', 'Admin Audit & Verification', 'In Progress', Colors.amber, false),
              _buildTimelineDivider(colorScheme.outlineVariant),
              _buildTimelineStep('3', 'Store Activation', 'Pending', colorScheme.outline, false),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovedView(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Congratulations!',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your seller account has been approved and activated. You can now access the seller dashboard and start managing your store.',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              AppPrimaryButton(
                text: 'Go to Seller Dashboard',
                onPressed: () => context.go('/seller/dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangesRequestedBanner(SellerApplication app, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                'Action Required: Changes Requested',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The administrator team reviewed your application and requested the following changes:',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            app.rejectionReason ?? 'Please verify and correct your shop description and contact information.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Please update the information below and resubmit for verification.',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedBanner(SellerApplication app, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                'Application Rejected',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Unfortunately, your application was not approved due to the following reason:',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            app.rejectionReason ?? 'Information provided could not be verified.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'You can revise your information below and submit a new application.',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String stepNumber, String title, String subtitle, Color color, bool isDone) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(stepNumber, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider(Color color) {
    return Container(
      width: 2,
      height: 30,
      color: color,
      margin: const EdgeInsets.only(left: 15),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.colorScheme, required this.theme});
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Selling Today',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Join our marketplace and reach millions of customers globally.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.theme});
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'By submitting, you agree to our Seller Terms and Privacy Policy.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
