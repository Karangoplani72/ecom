import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:ecom/features/seller/domain/entities/store_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminStoresScreen extends ConsumerStatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  ConsumerState<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends ConsumerState<AdminStoresScreen> {
  String _search = '';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(adminAllStoresProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdminScaffold(
      title: 'Stores',
      subtitle: 'Browse and manage all marketplace stores',
      body: Column(
        children: [
          _buildFilters(isDark),
          Expanded(
            child: storesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: AdminEmptyRow(
                  icon: Icons.cloud_off_rounded,
                  message: e.toString(),
                ),
              ),
              data: (stores) {
                final filtered = stores.where((s) {
                  final matchesSearch = _search.isEmpty ||
                      s.storeName
                          .toLowerCase()
                          .contains(_search.toLowerCase()) ||
                      (s.email ?? '')
                          .toLowerCase()
                          .contains(_search.toLowerCase());

                  final matchesStatus = _statusFilter == 'all' ||
                      (_statusFilter == 'active' && s.isActive) ||
                      (_statusFilter == 'suspended' && !s.isActive) ||
                      (_statusFilter == 'verified' && s.isVerified);

                  return matchesSearch && matchesStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return const AdminEmptyRow(
                    icon: Icons.storefront_outlined,
                    message: 'No stores match your filters.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _StoreTile(store: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search stores...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: AppRadius.borderLG),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  ('suspended', 'Suspended'),
                  ('verified', 'Verified'),
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
    );
  }
}

class _StoreTile extends ConsumerWidget {
  final StoreProfile store;
  const _StoreTile({required this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('d MMM yyyy');

    Color statusColor;
    String statusLabel;
    if (store.isSuspended) {
      statusColor = AppColors.error;
      statusLabel = 'Suspended';
    } else if (store.isVerified) {
      statusColor = AppColors.success;
      statusLabel = 'Verified';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'Unverified';
    }

    return AdminSectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StoreAvatar(store: store),
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
                        AdminStatusPill(
                          label: statusLabel,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                      'Since ${dateFmt.format(store.createdAt)}',
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
          Row(
            children: [
              _Stat(
                label: 'Products',
                value: store.totalProducts.toString(),
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 16),
              _Stat(
                label: 'Orders',
                value: store.totalOrders.toString(),
                icon: Icons.receipt_outlined,
              ),
              const SizedBox(width: 16),
              _Stat(
                label: 'Rating',
                value: store.rating.toStringAsFixed(1),
                icon: Icons.star_outline_rounded,
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
                    minimumSize: const Size(0, 36),
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
                      (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
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
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: Colors.red),
                label: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Store'),
                      content: Text(
                          'This will permanently delete "${store.storeName}" and hide all its products. This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true || !context.mounted) return;
                  final result = await ref
                      .read(adminControllerProvider.notifier)
                      .deleteStore(store.id);
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
                          const SnackBar(content: Text('Store deleted')),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreAvatar extends StatelessWidget {
  final StoreProfile store;
  const _StoreAvatar({required this.store});

  @override
  Widget build(BuildContext context) {
    if (store.logoUrl != null && store.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          store.logoUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.storefront_outlined,
        color: AppColors.primary,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 14,
            color: isDark ? Colors.white54 : AppColors.lightTextSecondary),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
