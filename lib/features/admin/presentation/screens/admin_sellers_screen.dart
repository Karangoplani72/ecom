// lib/features/admin/presentation/screens/admin_sellers_screen.dart
//
// Seller Management (route: /admin/sellers)
// Roster of verified sellers (the people, not the stores) with performance
// stats and account-status controls. PLACEHOLDER: sample data only —
// replace with a use case that joins AdminUser (role == seller) with their
// store/sales aggregates.

import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:flutter/material.dart';

class _SellerRow {
  final String name;
  final String email;
  final String storeName;
  final double totalRevenue;
  final int ordersFulfilled;
  final double rating;
  final bool isActive;

  const _SellerRow({
    required this.name,
    required this.email,
    required this.storeName,
    required this.totalRevenue,
    required this.ordersFulfilled,
    required this.rating,
    required this.isActive,
  });
}

const List<_SellerRow> _sampleSellers = [
  _SellerRow(
    name: 'Kavya Reddy',
    email: 'kavya.reddy@luxemarket.com',
    storeName: 'LuxeMarket Flagship',
    totalRevenue: 482300,
    ordersFulfilled: 1284,
    rating: 4.8,
    isActive: true,
  ),
  _SellerRow(
    name: 'Vikram Desai',
    email: 'vikram.d@studiokalakar.com',
    storeName: 'Studio Kalakar',
    totalRevenue: 96400,
    ordersFulfilled: 312,
    rating: 4.6,
    isActive: true,
  ),
  _SellerRow(
    name: 'Neha Kapoor',
    email: 'neha.kapoor@pawsome.shop',
    storeName: 'Pawsome Pet Supplies',
    totalRevenue: 142800,
    ordersFulfilled: 540,
    rating: 4.9,
    isActive: true,
  ),
  _SellerRow(
    name: 'Arjun Nair',
    email: 'arjun.nair@quickcart.in',
    storeName: 'QuickCart Essentials',
    totalRevenue: 51200,
    ordersFulfilled: 198,
    rating: 3.1,
    isActive: false,
  ),
];

class AdminSellersScreen extends StatefulWidget {
  const AdminSellersScreen({super.key});

  @override
  State<AdminSellersScreen> createState() => _AdminSellersScreenState();
}

class _AdminSellersScreenState extends State<AdminSellersScreen> {
  String _search = '';
  bool _activeOnly = false;

  @override
  Widget build(BuildContext context) {
    final filtered = _sampleSellers.where((s) {
      final matchesSearch =
          _search.isEmpty ||
          s.name.toLowerCase().contains(_search) ||
          s.storeName.toLowerCase().contains(_search);
      final matchesFilter = !_activeOnly || s.isActive;
      return matchesSearch && matchesFilter;
    }).toList();

    return AdminScaffold(
      title: 'Sellers',
      subtitle: 'View verified sellers and their performance',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const AdminSampleDataNotice(),
          const SizedBox(height: 20),
          const AdminMetricGrid(
            metrics: [
              AdminMetricCard(
                label: 'Total Sellers',
                value: '298',
                icon: Icons.badge_outlined,
                color: Color(0xFF2563EB),
              ),
              AdminMetricCard(
                label: 'New This Month',
                value: '9',
                icon: Icons.person_add_outlined,
                color: Color(0xFF0EA5E9),
              ),
              AdminMetricCard(
                label: 'Avg. Rating',
                value: '4.5',
                icon: Icons.star_outline_rounded,
                color: Color(0xFFF59E0B),
              ),
              AdminMetricCard(
                label: 'Suspended',
                value: '6',
                icon: Icons.person_off_outlined,
                color: Color(0xFFDC2626),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search by seller or store name...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 10),
          FilterChip(
            label: const Text('Active only'),
            selected: _activeOnly,
            onSelected: (v) => setState(() => _activeOnly = v),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            const AdminEmptyRow(
              icon: Icons.search_off_rounded,
              message: 'No sellers match your search or filter.',
            )
          else
            ...filtered.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SellerCard(seller: s),
              ),
            ),
        ],
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  final _SellerRow seller;

  const _SellerCard({required this.seller});

  @override
  Widget build(BuildContext context) {
    final statusColor = seller.isActive
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return AdminSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                seller.name.isNotEmpty ? seller.name[0] : '?',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seller.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(seller.email, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  '${seller.storeName} · ${seller.ordersFulfilled} orders · ₹${seller.totalRevenue.toStringAsFixed(0)} · ★ ${seller.rating}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AdminStatusPill(
                label: seller.isActive ? 'Active' : 'Suspended',
                color: statusColor,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    showPlaceholderActionSnack(context, 'View seller profile'),
                child: const Text('View profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
