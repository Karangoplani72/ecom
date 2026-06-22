import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/core/widgets/scaffolds/premium_25d_scaffold.dart';
import 'package:ecom/features/orders/domain/entities/order.dart';
import 'package:ecom/features/orders/domain/entities/order_status.dart';
import 'package:ecom/features/orders/presentation/controllers/order_controller.dart';
import 'package:ecom/features/orders/presentation/widgets/order_card.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_side_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BuyerOrdersScreen extends ConsumerWidget {
  const BuyerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(buyerOrdersProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Premium25DScaffold(
        isDark: theme.brightness == Brightness.dark,
        drawer: const BuyerSideDrawer(),
        appBar: AppBar(
          title: const Text('My Orders'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            indicatorWeight: 3,
            labelColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            unselectedLabelColor: theme.brightness == Brightness.dark ? Colors.white54 : Colors.black54,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: ordersAsync.when(
          loading: () => const AppLoadingView(),
          error: (error, _) => AppErrorView(message: error.toString()),
          data: (orders) {
            final activeOrders = orders
                .where(
                  (o) => !o.isCompleted && o.status != OrderStatus.cancelled,
                )
                .toList();
            final pastOrders = orders
                .where(
                  (o) => o.isCompleted || o.status == OrderStatus.cancelled,
                )
                .toList();

            return TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: () => ref.refresh(buyerOrdersProvider.future),
                  child: _OrdersList(
                    orders: activeOrders,
                    emptyTitle: 'No Active Orders',
                  ),
                ),
                RefreshIndicator(
                  onRefresh: () => ref.refresh(buyerOrdersProvider.future),
                  child: _OrdersList(
                    orders: pastOrders,
                    emptyTitle: 'No Order History',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<AppOrder> orders;
  final String emptyTitle;

  const _OrdersList({required this.orders, required this.emptyTitle});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return AppEmptyView(
        title: emptyTitle,
        subtitle: 'Your orders will appear here once you place them.',
        icon: Icons.shopping_bag_outlined,
      );
    }

    return ResponsiveLayout(
      maxWidth: 800,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) => OrderCard(
          order: orders[index],
          onTap: () => context.push('/buyer/orders/${orders[index].orderId}'),
        ),
      ),
    );
  }
}
