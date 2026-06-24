import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/features/orders/domain/entities/order_status.dart';
import 'package:ecom/features/orders/presentation/controllers/order_controller.dart';
import 'package:ecom/features/orders/presentation/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SellerReturnsScreen extends ConsumerWidget {
  const SellerReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/seller/dashboard'),
        ),
        title: const Text('Returns & Cancellations'),
        centerTitle: true,
      ),
      body: ordersAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(sellerOrdersProvider),
        ),
        data: (orders) {
          final returnedOrders = orders.where((o) =>
              o.status == OrderStatus.returnRequested ||
              o.status == OrderStatus.returnApproved ||
              o.status == OrderStatus.returnRejected ||
              o.status == OrderStatus.cancelled).toList();

          if (returnedOrders.isEmpty) {
            return const AppEmptyView(
              title: 'No Returns',
              subtitle: 'You currently have no return requests or cancellations.',
              icon: Icons.assignment_return_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sellerOrdersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: returnedOrders.length,
              itemBuilder: (context, index) {
                final order = returnedOrders[index];
                return OrderCard(
                  order: order,
                  showCustomerInfo: true,
                  onTap: () => context.push('/seller/orders/${order.orderId}'),
                  actionLabel: 'Review Request',
                  onActionPressed: () => context.push('/seller/orders/${order.orderId}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
