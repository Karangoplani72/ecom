import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/seller_application_controller.dart';

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

  String? _selectedCategory;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _storeNameController.dispose();
    _gstController.dispose();
    _descriptionController.dispose();
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
              'Application submitted! We\'ll review it shortly.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(sellerApplicationControllerProvider);
    final isLoading = asyncState.isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Become a Seller'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    _DisclaimerCard(colorScheme: colorScheme),
                    const SizedBox(height: 40),
                    AppPrimaryButton(
                      text: 'Submit Application',
                      isLoading: isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
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
