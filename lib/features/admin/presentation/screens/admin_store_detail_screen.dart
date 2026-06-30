import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/features/admin/presentation/providers/store_live_stats_provider.dart';
import 'package:fpdart/fpdart.dart' hide State;
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

    // The store document ID is the seller UID; products use storeId == seller UID
    final storeId = store['id'] as String? ?? '';
    final sellerId = store['sellerId'] as String? ?? storeId;

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
        // ── Store Header ──────────────────────────────────────────────────────
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
                    if ((store['businessCategory'] ?? store['category']) != null)
                      Text(
                        (store['businessCategory'] ?? store['category']) as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Live Store Statistics (computed from Firestore, cached) ───────────
        _SectionHeader('Store Statistics'),
        _LiveStoreStats(storeId: storeId, ref: ref),
        const SizedBox(height: 16),

        // ── Store Information ─────────────────────────────────────────────────
        _SectionHeader('Store Information'),
        AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'Store ID',
                value: storeId.isNotEmpty ? storeId : 'Unknown',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Seller ID',
                value: sellerId.isNotEmpty ? sellerId : 'Unknown',
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

        // ── Contact Information ───────────────────────────────────────────────
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

        // ── Business Details ──────────────────────────────────────────────────
        _SectionHeader('Business Details'),
        AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'Business Category',
                value: store['businessCategory'] as String? ?? store['category'] as String? ?? 'Unknown',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Description',
                value: store['storeDescription'] as String? ??
                    store['description'] as String? ??
                    'No description',
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

        // ── Bank Details ──────────────────────────────────────────────────────
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
                    ? 'XXXX${(store['accountNumber'] as String).substring((store['accountNumber'] as String).length.clamp(4, 999) - 4)}'
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

        // ── Recent Products (live from catalog, shares the cached fetch) ──────
        _SectionHeader('Products'),
        _ProductsPreview(storeId: storeId),
        const SizedBox(height: 16),

        // ── Store Actions ─────────────────────────────────────────────────────
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
    final storeDocId = store['id'] as String? ?? '';
    final Either<String, Unit> result;
    if (currentStatus) {
      result = await ref
          .read(adminControllerProvider.notifier)
          .suspendStore(storeDocId);
    } else {
      result = await ref
          .read(adminControllerProvider.notifier)
          .activateStore(storeDocId);
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

    final storeDocId = store['id'] as String? ?? '';
    final result = await ref
        .read(adminControllerProvider.notifier)
        .deleteStore(storeDocId);

    if (!context.mounted) return;
    result.fold(
      (err) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err))),
      (_) {
        ref.invalidate(storeLiveStatsProvider(storeDocId));
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

// ─────────────────────────────────────────────────────────────────────────────
// Live stats widget — backed by storeLiveStatsProvider, which is cached
// (keepAlive) per storeId. Riverpod shares this single fetch with
// _ProductsPreview below, so scrolling/rebuilding this screen never
// re-triggers Firestore reads after the first successful load.
// ─────────────────────────────────────────────────────────────────────────────
class _LiveStoreStats extends ConsumerWidget {
  final String storeId;
  final WidgetRef ref;

  const _LiveStoreStats({required this.storeId, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final statsAsync = ref.watch(storeLiveStatsProvider(storeId));

    return statsAsync.when(
      loading: () => _buildCard(context, isLoading: true, stats: null),
      error: (e, _) => AdminEmptyRow(
        icon: Icons.cloud_off_rounded,
        message: 'Failed to load stats: $e',
      ),
      data: (stats) => _buildCard(context, isLoading: false, stats: stats),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required bool isLoading,
    required StoreLiveStats? stats,
  }) {
    final productCount = stats?.totalProducts ?? 0;
    final orderCount = stats?.totalOrders ?? 0;
    final rating = stats?.rating ?? 0.0;
    final reviewCount = stats?.totalReviews ?? 0;

    return AdminSectionCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Products',
            value: isLoading ? '…' : productCount.toString(),
            icon: Icons.inventory_2_outlined,
          ),
          _StatItem(
            label: 'Orders',
            value: isLoading ? '…' : orderCount.toString(),
            icon: Icons.receipt_long_outlined,
          ),
          _StatItem(
            label: 'Rating',
            value: isLoading ? '…' : rating.toStringAsFixed(1),
            icon: Icons.star_outline_rounded,
          ),
          _StatItem(
            label: 'Reviews',
            value: isLoading ? '…' : reviewCount.toString(),
            icon: Icons.reviews_outlined,
          ),
        ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Products preview — queries catalog by storeId, shows variant count
// ─────────────────────────────────────────────────────────────────────────────
class _ProductsPreview extends ConsumerWidget {
  final String storeId;
  const _ProductsPreview({required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Shares the same cached fetch as _LiveStoreStats — Riverpod dedupes
    // identical family-provider reads, so this does not trigger a second
    // Firestore query.
    final statsAsync = ref.watch(storeLiveStatsProvider(storeId));

    return statsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          AdminEmptyRow(icon: Icons.error_outline, message: e.toString()),
      data: (stats) {
        var products = stats.products;
        if (products.isEmpty) {
          return const AdminEmptyRow(
            icon: Icons.inventory_2_outlined,
            message: 'No products found',
          );
        }

        // Sort by createdAt descending client-side
        products = List.from(products);
        products.sort((a, b) {
          final dateA = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final dateB = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });

        return Column(
          children: products.map((doc) {
            final product = doc.data();

            // Determine variant info
            final variantSkus = product['variantSkus'] as List?;
            final hasVariants = variantSkus != null && variantSkus.isNotEmpty;
            final variantCount = hasVariants ? variantSkus.length : 0;

            // Determine stock
            final stock = hasVariants
                ? variantSkus.fold<int>(
                    0,
                    (acc, sku) =>
                        acc + ((sku as Map<String, dynamic>?)?['stock'] as int? ?? 0),
                  )
                : ((product['metadata'] as Map<String, dynamic>?)?['stock'] as int? ?? 0);

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
                              width: 56,
                              height: 56,
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
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                '₹${(product['basePrice'] as num?)?.toInt() ?? 0}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                              AdminStatusPill(
                                label: product['isActive'] == true ? 'Active' : 'Inactive',
                                color: product['isActive'] == true
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                              if (hasVariants)
                                AdminStatusPill(
                                  label: '$variantCount variant${variantCount == 1 ? '' : 's'}',
                                  color: const Color(0xFF7C3AED),
                                ),
                              AdminStatusPill(
                                label: 'Stock: $stock',
                                color: stock > 0
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ],
                          ),
                          if (hasVariants) ...[
                            const SizedBox(height: 4),
                            _VariantChips(variantSkus: variantSkus),
                          ],
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
      width: 56,
      height: 56,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 24),
    );
  }
}

/// Renders a compact chip row summarising the variant combination labels.
class _VariantChips extends StatelessWidget {
  final List variantSkus;
  const _VariantChips({required this.variantSkus});

  @override
  Widget build(BuildContext context) {
    // Collect unique combinations for display
    final labels = variantSkus
        .take(6)
        .map((sku) {
          final m = sku as Map<String, dynamic>?;
          final combination = m?['combination'];
          if (combination is Map) {
            return combination.values.join(' / ');
          }
          return m?['skuId']?.toString() ?? '';
        })
        .where((l) => l.isNotEmpty)
        .toList();

    if (labels.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        ...labels.map(
          (label) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.primary),
            ),
          ),
        ),
        if (variantSkus.length > 6)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '+${variantSkus.length - 6} more',
              style: const TextStyle(fontSize: 10),
            ),
          ),
      ],
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
          width: 130,
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
