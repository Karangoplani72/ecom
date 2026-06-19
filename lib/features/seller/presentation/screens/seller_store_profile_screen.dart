import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/core/widgets/app_text_field.dart';
import 'package:ecom/features/seller/domain/entities/store_profile.dart';
import 'package:ecom/features/seller/presentation/controllers/seller_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerStoreProfileScreen extends ConsumerStatefulWidget {
  const SellerStoreProfileScreen({super.key});

  @override
  ConsumerState<SellerStoreProfileScreen> createState() =>
      _SellerStoreProfileScreenState();
}

class _SellerStoreProfileScreenState
    extends ConsumerState<SellerStoreProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _storeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _bannerUrlController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstNumberController = TextEditingController();

  String? _selectedCategory;
  bool _initialized = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _descriptionController.dispose();
    _logoUrlController.dispose();
    _bannerUrlController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstNumberController.dispose();
    super.dispose();
  }

  void _initFields(StoreProfile store) {
    if (_initialized) return;
    _storeNameController.text = store.storeName;
    _descriptionController.text = store.description;
    _logoUrlController.text = store.logoUrl ?? '';
    _bannerUrlController.text = store.bannerUrl ?? '';
    _phoneController.text = store.phone ?? '';
    _emailController.text = store.email ?? '';
    _addressController.text = store.address ?? '';
    _gstNumberController.text = store.gstNumber ?? '';
    _selectedCategory = store.category;
    _initialized = true;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final updates = {
      'storeName': _storeNameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'logoUrl': _logoUrlController.text.trim().isEmpty ? null : _logoUrlController.text.trim(),
      'bannerUrl': _bannerUrlController.text.trim().isEmpty ? null : _bannerUrlController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'category': _selectedCategory,
    };

    await ref.read(sellerControllerProvider.notifier).patchStoreSettings(updates);

    if (!mounted) return;

    final stateVal = ref.read(sellerControllerProvider);
    if (!stateVal.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store Profile updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${stateVal.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(sellerControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Store Profile & Branding'), centerTitle: true),
      body: storeState.when(
        loading: () => const AppLoadingView(),
        error: (err, _) => AppErrorView(
          message: 'Error loading store: $err',
          onRetry: () => ref.invalidate(sellerControllerProvider),
        ),
        data: (store) {
          if (store == null) {
            return const Center(child: Text('No store profile loaded.'));
          }

          _initFields(store);

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Badge Card
                  _buildStatusCard(store, theme, colorScheme),
                  const SizedBox(height: 24),

                  // Store Branding Section
                  _buildSectionHeader('Branding & Media', theme),
                  const SizedBox(height: 16),
                  _buildBrandingInputs(theme, colorScheme),
                  const SizedBox(height: 32),

                  // Store Information Section
                  _buildSectionHeader('Store Information', theme),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _storeNameController,
                    label: 'Store Name',
                    hint: 'Enter your brand store name',
                    prefixIcon: Icons.storefront_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryDropdown(theme, colorScheme),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _descriptionController,
                    label: 'Store Description',
                    hint: 'Tell customers about your products...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _gstNumberController,
                    label: 'GST Number',
                    hint: 'e.g. 22AAAAA0000A1Z5',
                    prefixIcon: Icons.badge_outlined,
                    enabled: false, // GST cannot be altered directly after onboarding
                  ),
                  const SizedBox(height: 32),

                  // Contact Details Section
                  _buildSectionHeader('Contact details', theme),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _phoneController,
                    label: 'Support Phone Number',
                    hint: '+91 9876543210',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _emailController,
                    label: 'Support Email',
                    hint: 'support@yourstore.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _addressController,
                    label: 'Warehouse Address',
                    hint: 'Full physical address for pickup/returns',
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  AppPrimaryButton(
                    text: 'Save Changes',
                    isLoading: storeState.isLoading,
                    onPressed: _saveProfile,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const Divider(height: 16),
      ],
    );
  }

  Widget _buildStatusCard(StoreProfile store, ThemeData theme, ColorScheme colorScheme) {
    final statusColor = store.isActive ? Colors.green : Colors.red;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: Icon(store.isActive ? Icons.verified_user_rounded : Icons.gpp_bad_rounded, color: statusColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.storeSlug,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          store.status.name.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        store.isActive ? 'Active storefront' : 'Suspended storefront',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandingInputs(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // Logo URL Input & Preview
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: _logoUrlController.text.trim().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        _logoUrlController.text.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_outlined),
                      ),
                    )
                  : const Icon(Icons.storefront_rounded, size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                controller: _logoUrlController,
                label: 'Logo Image URL',
                hint: 'https://example.com/logo.png',
                prefixIcon: Icons.image_outlined,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Banner URL Input & Preview
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: _bannerUrlController.text.trim().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        _bannerUrlController.text.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_outlined)),
                      ),
                    )
                  : const Center(child: Icon(Icons.add_photo_alternate_outlined, size: 36)),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _bannerUrlController,
              label: 'Banner Image URL',
              hint: 'https://example.com/banner.png',
              prefixIcon: Icons.landscape_outlined,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(ThemeData theme, ColorScheme colorScheme) {
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
            hintText: 'Select category',
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
          onChanged: (val) => setState(() => _selectedCategory = val),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Category is required' : null,
        ),
      ],
    );
  }
}
