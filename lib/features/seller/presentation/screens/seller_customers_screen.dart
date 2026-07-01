import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/features/seller/presentation/controllers/seller_customers_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SellerCustomersScreen extends ConsumerStatefulWidget {
  const SellerCustomersScreen({super.key});

  @override
  ConsumerState<SellerCustomersScreen> createState() => _SellerCustomersScreenState();
}

class _SellerCustomersScreenState extends ConsumerState<SellerCustomersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'spend'; // 'spend', 'orders', 'date'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(sellerCustomersProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Directory'),
      ),
      body: customersAsync.when(
        loading: () => const AppLoadingView(),
        error: (err, _) => AppErrorView(
          message: 'Failed to load customers: $err',
          onRetry: () => ref.invalidate(sellerCustomersProvider),
        ),
        data: (customers) {
          // Filter customers based on search query
          var filtered = customers.where((c) {
            final query = _searchQuery.toLowerCase();
            return c.name.toLowerCase().contains(query) ||
                c.email.toLowerCase().contains(query) ||
                c.phoneNumber.contains(query);
          }).toList();

          // Sort customers
          if (_sortBy == 'spend') {
            filtered.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
          } else if (_sortBy == 'orders') {
            filtered.sort((a, b) => b.ordersCount.compareTo(a.ordersCount));
          } else if (_sortBy == 'date') {
            filtered.sort((a, b) => b.lastOrderDate.compareTo(a.lastOrderDate));
          }

          // Compute global stats
          final totalCustomers = customers.length;
          final totalSales = customers.fold<double>(0.0, (sum, c) => sum + c.totalSpent);
          final avgSpend = totalCustomers > 0 ? totalSales / totalCustomers : 0.0;
          final topCustomer = customers.isEmpty
              ? null
              : (customers.toList()..sort((a, b) => b.totalSpent.compareTo(a.totalSpent))).first;

          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.supervised_user_circle_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Customers Found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customers will appear here once they complete purchases from your store.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Top Stats Cards
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Customers',
                        value: totalCustomers.toString(),
                        icon: Icons.people_rounded,
                        color: AppColors.primary,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Avg. LTV',
                        value: NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(avgSpend),
                        icon: Icons.wallet_giftcard_rounded,
                        color: Colors.green,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                    if (topCustomer != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Top Customer',
                          value: topCustomer.name,
                          subtitle: NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(topCustomer.totalSpent),
                          icon: Icons.star_rounded,
                          color: Colors.amber,
                          isDark: isDark,
                          theme: theme,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Filter/Sort controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search by name, email, or phone...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.borderLG,
                            borderSide: BorderSide(
                              color: isDark ? Colors.white12 : AppColors.border,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.sort),
                      items: const [
                        DropdownMenuItem(
                          value: 'spend',
                          child: Text('Sort by Spend'),
                        ),
                        DropdownMenuItem(
                          value: 'orders',
                          child: Text('Sort by Orders'),
                        ),
                        DropdownMenuItem(
                          value: 'date',
                          child: Text('Sort by Last Order'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _sortBy = val);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Customer List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No customers match "$_searchQuery"',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final customer = filtered[index];
                          return _buildCustomerCard(customer, isDark, theme);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerCard(SellerCustomer customer, bool isDark, ThemeData theme) {
    final dateStr = DateFormat('MMM d, yyyy').format(customer.lastOrderDate);
    final totalSpentStr = NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(customer.totalSpent);

    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white12 : AppColors.border,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: customer.photoUrl != null ? NetworkImage(customer.photoUrl!) : null,
          child: customer.photoUrl == null
              ? Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          customer.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          '${customer.ordersCount} orders • $totalSpentStr spent',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.email_outlined, 'Email', customer.email.isNotEmpty ? customer.email : 'N/A', theme),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.phone_outlined, 'Phone', customer.phoneNumber.isNotEmpty ? customer.phoneNumber : 'N/A', theme),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.calendar_today_outlined, 'Last Order Date', dateStr, theme),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on_outlined, 'Shipping Address', customer.lastAddress, theme),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.lightTextSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.lightTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 250,
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
