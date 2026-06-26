import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminStoreDetailScreen extends ConsumerStatefulWidget {
  final String storeId;
  const AdminStoreDetailScreen({super.key, required this.storeId});

  @override
  ConsumerState<AdminStoreDetailScreen> createState() =>
      _AdminStoreDetailScreenState();
}

class _AdminStoreDetailScreenState extends ConsumerState<AdminStoreDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firebaseFirestoreProvider);

    return AdminScaffold(
      title: 'Store Details',
      subtitle: 'View complete store information',
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.collection('stores').doc(widget.storeId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AdminEmptyRow(icon: Icons.error_outline, message: snapshot.error.toString());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const AdminEmptyRow(
              icon: Icons.storefront_outlined,
              message: 'Store not found',
            );
          }
          final store = <String, dynamic>{'id': snapshot.data!.id, ...snapshot.data!.data()! as Map<String, dynamic>};
          return _StoreDetailView(store: store);
        },
      ),
    );
  }
}

class _StoreDetailView extends ConsumerWidget {
  final Map<String, dynamic> store;
  const _StoreDetailView({required this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('d MMM yyyy');

    final isActive = store['isActive'] as bool? ?? true;
    final isVerified = store['isVerified'] as bool? ?? false;

    Color statusColor;
    String statusLabel;
    if (!isActive) {
      statusColor = AppColors.error;
      statusLabel = 'Suspended';
    } else if (isVerified) {
      statusColor = AppColors.success;
      statusLabel = 'Verified';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'Unverified';
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Store Header
        AdminSectionCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Store Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (store['logoUrl'] as String? ?? '').isNotEmpty
                    ? Image.network(
                        store['logoUrl'] as String,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => _fallbackLogo(),
                      )
                    : _fallbackLogo(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store['storeName'] as String? ?? 'Unknown Store',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        AdminStatusPill(label: statusLabel, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (store['category'] != null)
                      Text(
                        store['category'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          (store['rating'] as num?)?.toStringAsFixed(1) ?? '0.0',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${store['totalReviews'] ?? 0} reviews)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Store Stats
        _SectionHeader('Store Statistics'),
        AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Products',
                value: (store['totalProducts'] ?? 0).toString(),
                icon: Icons.inventory_2_outlined,
              ),
              _StatItem(
                label: 'Orders',
                value: (store['totalOrders'] ?? 0).toString(),
                icon: Icons.receipt_long_outlined,
              ),
              _StatItem(
                label: 'Rating',
                value: ((store['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'),
                icon: Icons.star_outline_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Store Information
        _SectionHeader('Store Information'),
        AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'Store ID',
                value: store['storeId'] as String? ?? store['id'] as String? ?? 'Unknown',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Seller ID',
                value: store['sellerId'] as String? ?? 'Unknown',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Store Slug',
                value: store['storeSlug'] as String? ?? 'Unknown',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Created At',
                value: store['createdAt'] != null
                    ? dateFmt.format((store['createdAt'] as Timestamp).toDate())
                    : 'Unknown',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Contact Information
        _SectionHeader('Contact Information'),
        AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'Email',
                value: store['email'] as String? ?? 'Not provided',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Phone',
                value: store['phone'] as String? ?? 'Not provided',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'GST Number',
                value: store['gstNumber'] as String? ?? 'Not provided',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Business Details
        _SectionHeader('Business Details'),
        AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'Business Category',
                value: store['businessCategory'] as String? ?? 'Unknown',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Description',
                value: store['storeDescription'] as String? ?? 'No description',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Address',
                value: store['address'] as String? ?? 'Not provided',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bank Details
        _SectionHeader('Bank Details'),
        AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'Bank Name',
                value: store['bankName'] as String? ?? 'Not provided',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Account Number',
                value: store['accountNumber'] != null
                    ? 'XXXX${(store['accountNumber'] as String).substring((store['accountNumber'] as String).length - 4)}'
                    : 'Not provided',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'IFSC Code',
                value: store['ifscCode'] as String? ?? 'Not provided',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Account Holder',
                value: store['accountHolderName'] as String? ?? 'Not provided',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Store Products Preview
        _SectionHeader('Recent Products'),
        _ProductsPreview(storeId: store['id'] as String),
        const SizedBox(height: 16),

        // Store Actions
        _SectionHeader('Store Actions'),
        AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                        size: 16,
                      ),
                      label: Text(isActive ? 'Suspend Store' : 'Activate Store'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isActive ? AppColors.error : AppColors.success,
                        side: BorderSide(color: isActive ? AppColors.error : AppColors.success),
                      ),
                      onPressed: () => _toggleStoreStatus(context, ref, isActive),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                      label: const Text('Delete Store', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                      onPressed: () => _deleteStore(context, ref),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Future<void> _toggleStoreStatus(
    BuildContext context,
    WidgetRef ref,
    bool currentStatus,
  ) async {
    final storeId = store['sellerId'] as String? ?? store['id'] as String? ?? '';
    final Either<String, Unit> result;
    if (currentStatus) {
      result = await ref
          .read(adminControllerProvider.notifier)
          .suspendStore(storeId);
    } else {
      result = await ref
          .read(adminControllerProvider.notifier)
          .activateStore(storeId);
    }
    if (!context.mounted) return;
    result.fold(
      (err) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentStatus ? 'Store suspended' : 'Store activated'),
        ),
      ),
    );
  }

  Future<void> _deleteStore(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Store'),
        content: Text(
          'This will permanently delete "${store['storeName']}" and all its products. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final storeId = store['sellerId'] as String? ?? store['id'] as String? ?? '';
    final result = await ref
        .read(adminControllerProvider.notifier)
        .deleteStore(storeId);

    if (!context.mounted) return;
    result.fold(
      (err) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store deleted')),
        );
        Navigator.pop(context);
      },
    );
  }

  Widget _fallbackLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.storefront_outlined,
        color: AppColors.primary,
        size: 40,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _ProductsPreview extends ConsumerStatefulWidget {
  final String storeId;
  const _ProductsPreview({required this.storeId});

  @override
  ConsumerState<_ProductsPreview> createState() => _ProductsPreviewState();
}

class _ProductsPreviewState extends ConsumerState<_ProductsPreview> {
  late Future<QuerySnapshot<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = ref.read(firebaseFirestoreProvider)
        .collection('catalog')
        .where('sellerId', isEqualTo: widget.storeId)
        .get();
  }

  @override
  void didUpdateWidget(covariant _ProductsPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storeId != widget.storeId) {
      _productsFuture = ref.read(firebaseFirestoreProvider)
          .collection('catalog')
          .where('sellerId', isEqualTo: widget.storeId)
          .get();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AdminEmptyRow(icon: Icons.error_outline, message: snapshot.error.toString());
        }

        var products = snapshot.data?.docs ?? [];
        if (products.isEmpty) {
          return const AdminEmptyRow(
            icon: Icons.inventory_2_outlined,
            message: 'No products found',
          );
        }

        // Sort by createdAt descending client-side
        products.sort((a, b) {
          final dataA = a.data();
          final dataB = b.data();
          final dateA = (dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final dateB = (dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });

        // Limit to 5 products preview
        if (products.length > 5) {
          products = products.sublist(0, 5);
        }

        return Column(
          children: products.map((doc) {
            final product = doc.data();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AdminSectionCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (product['imageUrls'] as List?)?.isNotEmpty == true
                          ? Image.network(
                              (product['imageUrls'] as List).first as String,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => _fallbackImage(),
                            )
                          : _fallbackImage(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['title'] as String? ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '₹${(product['basePrice'] as num?)?.toInt() ?? 0}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AdminStatusPill(
                                label: product['isActive'] == true ? 'Active' : 'Inactive',
                                color: product['isActive'] == true ? AppColors.success : AppColors.error,
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
          }).toList(),
        );
      },
    );
  }

  Widget _fallbackImage() {
    return Container(
      width: 50,
      height: 50,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 24),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
