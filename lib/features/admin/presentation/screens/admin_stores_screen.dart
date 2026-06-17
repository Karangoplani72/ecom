// lib/features/admin/presentation/screens/admin_stores_screen.dart
//
// Store Directory (route: /admin/stores)
// Platform-wide directory of every store regardless of verification status,
// with search + status filtering. PLACEHOLDER: sample data only — replace
// with a paginated query against the stores collection (likely via a
// `AdminStoreRepository.watchAllStores()` style use case).

import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:flutter/material.dart';

enum _StoreStatus { verified, pending, suspended }

class _StoreRow {
  final String name;
  final String category;
  final _StoreStatus status;
  final double rating;
  final int products;
  final double totalSales;
  final String joined;

  const _StoreRow({
    required this.name,
    required this.category,
    required this.status,
    required this.rating,
    required this.products,
    required this.totalSales,
    required this.joined,
  });
}

const List<_StoreRow> _sampleStores = [
  _StoreRow(
    name: 'LuxeMarket Flagship',
    category: 'Fashion',
    status: _StoreStatus.verified,
    rating: 4.8,
    products: 214,
    totalSales: 482300,
    joined: 'Jan 2024',
  ),
  _StoreRow(
    name: 'Northline Electronics',
    category: 'Electronics',
    status: _StoreStatus.pending,
    rating: 0,
    products: 0,
    totalSales: 0,
    joined: 'Jun 2026',
  ),
  _StoreRow(
    name: 'Aurora Home Decor',
    category: 'Home & Living',
    status: _StoreStatus.pending,
    rating: 0,
    products: 0,
    totalSales: 0,
    joined: 'Jun 2026',
  ),
  _StoreRow(
    name: 'Studio Kalakar',
    category: 'Art & Crafts',
    status: _StoreStatus.verified,
    rating: 4.6,
    products: 58,
    totalSales: 96400,
    joined: 'Sep 2025',
  ),
  _StoreRow(
    name: 'QuickCart Essentials',
    category: 'Grocery',
    status: _StoreStatus.suspended,
    rating: 3.1,
    products: 132,
    totalSales: 51200,
    joined: 'Mar 2025',
  ),
  _StoreRow(
    name: 'Pawsome Pet Supplies',
    category: 'Pet Care',
    status: _StoreStatus.verified,
    rating: 4.9,
    products: 76,
    totalSales: 142800,
    joined: 'Nov 2024',
  ),
];

class AdminStoresScreen extends StatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen> {
  String _search = '';
  _StoreStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final filtered = _sampleStores.where((s) {
      final matchesSearch =
          _search.isEmpty ||
          s.name.toLowerCase().contains(_search) ||
          s.category.toLowerCase().contains(_search);
      final matchesFilter = _filter == null || s.status == _filter;
      return matchesSearch && matchesFilter;
    }).toList();

    return AdminScaffold(
      title: 'Stores',
      subtitle: 'Browse and manage every store on the platform',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const AdminSampleDataNotice(),
          const SizedBox(height: 20),
          const AdminMetricGrid(
            metrics: [
              AdminMetricCard(
                label: 'Total Stores',
                value: '356',
                icon: Icons.storefront_outlined,
                color: Color(0xFF2563EB),
              ),
              AdminMetricCard(
                label: 'Verified',
                value: '341',
                icon: Icons.verified_outlined,
                color: Color(0xFF16A34A),
              ),
              AdminMetricCard(
                label: 'Suspended',
                value: '4',
                icon: Icons.block_outlined,
                color: Color(0xFFDC2626),
              ),
              AdminMetricCard(
                label: 'New This Month',
                value: '11',
                icon: Icons.trending_up_rounded,
                color: Color(0xFF0EA5E9),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search by store name or category...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              _FilterChip(
                label: 'Verified',
                selected: _filter == _StoreStatus.verified,
                onTap: () => setState(() => _filter = _StoreStatus.verified),
              ),
              _FilterChip(
                label: 'Pending',
                selected: _filter == _StoreStatus.pending,
                onTap: () => setState(() => _filter = _StoreStatus.pending),
              ),
              _FilterChip(
                label: 'Suspended',
                selected: _filter == _StoreStatus.suspended,
                onTap: () => setState(() => _filter = _StoreStatus.suspended),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const AdminEmptyRow(
              icon: Icons.search_off_rounded,
              message: 'No stores match your search or filter.',
            )
          else
            ...filtered.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StoreCard(store: s),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StoreCard extends StatelessWidget {
  final _StoreRow store;

  const _StoreCard({required this.store});

  static const _statusColor = {
    _StoreStatus.verified: Color(0xFF16A34A),
    _StoreStatus.pending: Color(0xFFF59E0B),
    _StoreStatus.suspended: Color(0xFFDC2626),
  };

  static const _statusLabel = {
    _StoreStatus.verified: 'Verified',
    _StoreStatus.pending: 'Pending',
    _StoreStatus.suspended: 'Suspended',
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor[store.status]!;

    return AdminSectionCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.storefront_outlined, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${store.category} • Joined ${store.joined}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (store.status == _StoreStatus.verified) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${store.products} products • ₹${store.totalSales.toStringAsFixed(0)} sales • ★ ${store.rating}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          AdminStatusPill(label: _statusLabel[store.status]!, color: color),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) =>
                showPlaceholderActionSnack(context, action),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'View store', child: Text('View store')),
              PopupMenuItem(
                value: 'Suspend store',
                child: Text('Suspend store'),
              ),
              PopupMenuItem(
                value: 'View transactions',
                child: Text('View transactions'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
