import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:ecom/features/seller/domain/entities/store_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminSellersScreen extends ConsumerStatefulWidget {
  const AdminSellersScreen({super.key});

  @override
  ConsumerState<AdminSellersScreen> createState() => _AdminSellersScreenState();
}

class _AdminSellersScreenState extends ConsumerState<AdminSellersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(adminAllStoresProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdminScaffold(
      title: 'Sellers',
      subtitle: 'View verified sellers and their performance',
      body: Column(
        children: [
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search sellers...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: AppRadius.borderLG),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: storesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, stack) => Center(
                child: AdminEmptyRow(
                  icon: Icons.cloud_off_rounded,
                  message: e.toString(),
                ),
              ),
              data: (stores) {
                final sellers = stores
                    .where((s) => s.isVerified)
                    .where((s) =>
                        _search.isEmpty ||
                        s.storeName
                            .toLowerCase()
                            .contains(_search.toLowerCase()))
                    .toList();

                if (sellers.isEmpty) {
                  return const AdminEmptyRow(
                    icon: Icons.badge_outlined,
                    message: 'No verified sellers found.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: sellers.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _SellerCard(store: sellers[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerCard extends ConsumerWidget {
  final StoreProfile store;
  const _SellerCard({required this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('d MMM yyyy');

    return AdminSectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.storeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (store.isVerified)
                          const AdminStatusPill(
                            label: 'Verified',
                            color: AppColors.success,
                            icon: Icons.verified_rounded,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (store.category != null)
                      Text(
                        store.category!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    Text(
                      'Joined ${dateFmt.format(store.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white38
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                label: 'Products',
                value: store.totalProducts.toString(),
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Orders',
                value: store.totalOrders.toString(),
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Rating',
                value: store.rating.toStringAsFixed(1),
                icon: Icons.star_rounded,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Reviews',
                value: store.totalReviews.toString(),
                icon: Icons.reviews_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    store.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    size: 16,
                  ),
                  label: Text(store.isActive ? 'Suspend' : 'Activate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: store.isActive
                        ? AppColors.error
                        : AppColors.success,
                    side: BorderSide(
                      color: store.isActive
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                  onPressed: () async {
                    final result = store.isActive
                        ? await ref
                            .read(adminControllerProvider.notifier)
                            .suspendStore(store.id)
                        : await ref
                            .read(adminControllerProvider.notifier)
                            .activateStore(store.id);

                    result.fold(
                      (err) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err)),
                          );
                        }
                      },
                      (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                store.isActive
                                    ? '${store.storeName} suspended'
                                    : '${store.storeName} activated',
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    if (store.logoUrl != null && store.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          store.logoUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _fallbackAvatar(),
        ),
      );
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.storefront_outlined, color: AppColors.primary),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
