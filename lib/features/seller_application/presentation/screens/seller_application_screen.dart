// lib/features/seller/presentation/screens/seller_application_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
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
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted! We\'ll review it shortly.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
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
      appBar: AppBar(
        title: const Text('Become a Seller'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 720;
            final horizontalPad = isWide
                ? (constraints.maxWidth - 680) / 2
                : AppSpacing.md;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPad,
                vertical: AppSpacing.lg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(colorScheme: colorScheme, theme: theme),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionLabel(label: 'Personal Information', theme: theme),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hint: 'Enter your legal full name',
                      enabled: !isLoading,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: '+91 9876543210',
                      keyboardType: TextInputType.phone,
                      enabled: !isLoading,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionLabel(label: 'Business Details', theme: theme),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _storeNameController,
                      label: 'Store Name',
                      hint: 'Your brand or store name',
                      enabled: !isLoading,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Store name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CategoryDropdown(
                      value: _selectedCategory,
                      isLoading: isLoading,
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _gstController,
                      label: 'GST Number (Optional)',
                      hint: '22AAAAA0000A1Z5',
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _descriptionController,
                      label: 'Business Description',
                      hint:
                          'Describe your business, products, and what makes you unique...',
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
                    const SizedBox(height: AppSpacing.xl),
                    _DisclaimerCard(colorScheme: colorScheme),
                    const SizedBox(height: AppSpacing.xl),
                    AppPrimaryButton(
                      text: 'Submit Application',
                      icon: Icons.send_rounded,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _submit,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.storefront_rounded,
              size: 36,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Selling Today',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete the form below and our team will review your application within 2–3 business days.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.8,
                    ),
                  ),
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
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.value,
    required this.isLoading,
    required this.onChanged,
  });

  final String? value;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  static const _categories = [
    'Electronics',
    'Fashion & Apparel',
    'Home & Garden',
    'Health & Beauty',
    'Sports & Outdoors',
    'Books & Stationery',
    'Food & Beverages',
    'Toys & Games',
    'Automotive',
    'Jewellery & Accessories',
    'Art & Crafts',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Business Category'),
      isExpanded: true,
      items: _categories
          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
          .toList(),
      onChanged: isLoading ? null : onChanged,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Business category is required';
        return null;
      },
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'By submitting this application, you agree to our Seller Terms of Service and confirm that all information provided is accurate.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
