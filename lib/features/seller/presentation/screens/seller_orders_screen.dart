import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/features/orders/domain/entities/order_status.dart';
import 'package:ecom/features/orders/presentation/controllers/order_controller.dart';
import 'package:ecom/features/orders/presentation/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> {
  String _selectedFilter = 'all';

  Future<void> _showStatusPicker(
    BuildContext context,
    String orderId,
    OrderStatus currentStatus,
  ) async {
    final selectedStatus = await showModalBottomSheet<OrderStatus>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Update Order Status',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              ...OrderStatus.values.map((status) {
                return ListTile(
                  title: Text(status.name.toUpperCase()),
                  trailing: status == currentStatus
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, status),
                );
              }),
            ],
          ),
        );
      },
    );

    if (selectedStatus == null || selectedStatus == currentStatus) return;
    if (!mounted) return;

    await ref
        .read(orderControllerProvider.notifier)
        .updateStatus(orderId: orderId, status: selectedStatus);
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(sellerOrdersProvider);

    ref.listen(orderControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/seller/dashboard'),
        ),
        title: const Text('Store Orders'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedFilter == 'all',
                  onSelected: (val) => setState(() => _selectedFilter = 'all'),
                ),
                ...OrderStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _FilterChip(
                      label: status.name.toUpperCase(),
                      isSelected: _selectedFilter == status.name,
                      onSelected: (val) =>
                          setState(() => _selectedFilter = status.name),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const AppLoadingView(),
              error: (error, _) => AppErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(sellerOrdersProvider),
              ),
              data: (orders) {
                final filteredOrders = _selectedFilter == 'all'
                    ? orders
                    : orders
                          .where((o) => o.status.name == _selectedFilter)
                          .toList();

                if (filteredOrders.isEmpty) {
                  return AppEmptyView(
                    title: _selectedFilter == 'all'
                        ? 'No Orders Yet'
                        : 'No ${_selectedFilter[0].toUpperCase() + _selectedFilter.substring(1)} Orders',
                    subtitle: 'Orders from your customers will show up here.',
                    icon: Icons.receipt_long_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(sellerOrdersProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return OrderCard(
                        order: order,
                        showCustomerInfo: true,
                        onTap: () =>
                            context.push('/seller/orders/${order.orderId}'),
                        actionLabel: 'Update Status',
                        onActionPressed: () => _showStatusPicker(
                          context,
                          order.orderId,
                          order.status,
                        ),
                      );
                    },
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      showCheckmark: false,
    );
  }
}
