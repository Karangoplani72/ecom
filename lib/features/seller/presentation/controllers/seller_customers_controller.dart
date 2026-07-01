import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/orders/domain/entities/order.dart';
import 'package:ecom/features/orders/presentation/controllers/order_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'seller_customers_controller.g.dart';

class SellerCustomer {
  final String buyerId;
  final String name;
  final String email;
  final String phoneNumber;
  final int ordersCount;
  final double totalSpent;
  final DateTime lastOrderDate;
  final String lastAddress;
  final String? photoUrl;

  const SellerCustomer({
    required this.buyerId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.ordersCount,
    required this.totalSpent,
    required this.lastOrderDate,
    required this.lastAddress,
    this.photoUrl,
  });
}

@riverpod
Stream<List<SellerCustomer>> sellerCustomers(Ref ref) {
  final ordersAsync = ref.watch(sellerOrdersProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);

  return ordersAsync.when(
    loading: () => Stream.value(<SellerCustomer>[]),
    error: (err, stack) => Stream.error(err, stack),
    data: (orders) {
      if (orders.isEmpty) {
        return Stream.value(<SellerCustomer>[]);
      }

      // Group orders by buyerId
      final groupedOrders = <String, List<AppOrder>>{};
      for (final order in orders) {
        groupedOrders.putIfAbsent(order.buyerId, () => []).add(order);
      }

      final buyerIds = groupedOrders.keys.toList();

      // We use a stream from a Future that fetches user details
      final fetchFuture = Future.wait(buyerIds.map((buyerId) async {
        final buyerOrders = groupedOrders[buyerId]!;
        final latestOrder = buyerOrders.first; // orders are descending by createdAt

        String email = '';
        String phoneNumber = '';
        String? photoUrl;

        try {
          final userDoc = await firestore.collection('users').doc(buyerId).get();
          if (userDoc.exists) {
            final data = userDoc.data();
            if (data != null) {
              email = data['email'] as String? ?? '';
              phoneNumber = data['phoneNumber'] as String? ?? '';
              photoUrl = data['photoUrl'] as String?;
            }
          }
        } catch (_) {
          // Fallback if user profile lookup fails
        }

        // Calculate stats
        final totalSpent = buyerOrders.fold<double>(0.0, (acc, o) => acc + o.totalAmount);

        return SellerCustomer(
          buyerId: buyerId,
          name: latestOrder.buyerName.isNotEmpty ? latestOrder.buyerName : 'Customer',
          email: email,
          phoneNumber: phoneNumber,
          ordersCount: buyerOrders.length,
          totalSpent: totalSpent,
          lastOrderDate: latestOrder.createdAt,
          lastAddress: latestOrder.deliveryAddress,
          photoUrl: photoUrl,
        );
      }));

      return Stream.fromFuture(fetchFuture);
    },
  );
}
