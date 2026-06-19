import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _adminProductsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(firebaseFirestoreProvider)
      .collection('catalog')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList());
});

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  String _search = '';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(_adminProductsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return AdminScaffold(
      title: 'Products',
      subtitle: 'Browse and moderate all catalog products',
      body: Column(
        children: [
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border:
                        OutlineInputBorder(borderRadius: AppRadius.borderLG),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in [
                        ('all', 'All'),
                        ('active', 'Active'),
                        ('inactive', 'Inactive'),
                        ('outOfStock', 'Out of Stock'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f.$2),
                            selected: _statusFilter == f.$1,
                            onSelected: (_) =>
                                setState(() => _statusFilter = f.$1),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, stack) => Center(
                child: AdminEmptyRow(
                  icon: Icons.cloud_off_rounded,
                  message: e.toString(),
                ),
              ),
              data: (products) {
                final filtered = products.where((p) {
                  final name = (p['name'] as String? ?? '').toLowerCase();
                  final matchesSearch = _search.isEmpty ||
                      name.contains(_search.toLowerCase());

                  bool matchesStatus;
                  switch (_statusFilter) {
                    case 'active':
                      matchesStatus = p['isActive'] == true;
                      break;
                    case 'inactive':
                      matchesStatus = p['isActive'] == false;
                      break;
                    case 'outOfStock':
                      matchesStatus = (p['stockQuantity'] as int? ?? 1) == 0;
                      break;
                    default:
                      matchesStatus = true;
                  }

                  return matchesSearch && matchesStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return const AdminEmptyRow(
                    icon: Icons.inventory_2_outlined,
                    message: 'No products match your filters.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _ProductTile(
                    product: filtered[i],
                    currencyFmt: currencyFmt,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final Map<String, dynamic> product;
  final NumberFormat currencyFmt;
  const _ProductTile({required this.product, required this.currencyFmt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = product['isActive'] as bool? ?? true;
    final stockQty = product['stockQuantity'] as int? ?? 0;
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final imageUrl = (product['imageUrls'] as List?)?.isNotEmpty == true
        ? (product['imageUrls'] as List).first as String?
        : null;

    return AdminSectionCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
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
                  product['name'] as String? ?? 'Unnamed Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      currencyFmt.format(price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stock: $stockQty',
                      style: TextStyle(
                        fontSize: 11,
                        color: stockQty == 0
                            ? AppColors.error
                            : (isDark
                                ? Colors.white54
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              AdminStatusPill(
                label: isActive ? 'Active' : 'Inactive',
                color: isActive ? AppColors.success : AppColors.error,
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 30,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    foregroundColor:
                        isActive ? AppColors.error : AppColors.success,
                    side: BorderSide(
                      color: isActive ? AppColors.error : AppColors.success,
                    ),
                  ),
                  onPressed: () async {
                    await ref
                        .read(firebaseFirestoreProvider)
                        .collection('catalog')
                        .doc(product['id'] as String)
                        .update({
                      'isActive': !isActive,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isActive ? 'Product deactivated' : 'Product activated',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    isActive ? 'Deactivate' : 'Activate',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}
