import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_price_text.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/features/auth/domain/entities/user_address.dart';
import 'package:ecom/features/auth/presentation/controllers/address_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/orders/domain/entities/order.dart';
import 'package:ecom/features/orders/domain/entities/order_item.dart';
import 'package:ecom/features/orders/domain/entities/order_status.dart';
import 'package:ecom/features/orders/presentation/controllers/order_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/navigation/router.dart';
import '../../domain/entities/cart_item.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  UserAddress? _selectedAddress;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Default address will be set in build if not already selected
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartControllerProvider);
    final addressesAsync = ref.watch(userAddressesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Set initial default address if available
    addressesAsync.whenData((addresses) {
      if (_selectedAddress == null && addresses.isNotEmpty) {
        _selectedAddress = addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => addresses.first,
        );
      }
    });

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: AppEmptyView(
          title: 'Cart is empty',
          subtitle: 'Add items to your cart before checking out.',
          icon: Icons.shopping_cart_outlined,
          action: FilledButton(
            onPressed: () => context.go('/buyer/home'),
            child: const Text('Go Shopping'),
          ),
        ),
      );
    }

    final groupedItems = <String, List<CartItem>>{};
    for (final item in cartItems) {
      groupedItems.putIfAbsent(item.storeId, () => <CartItem>[]);
      groupedItems[item.storeId]!.add(item);
    }

    final subtotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
    final platformFee = subtotal * 0.02;
    double deliveryFee = 0;
    groupedItems.forEach((storeId, items) {
      final storeSubtotal = items.fold<double>(
        0,
        (sum, item) => sum + (item.unitPrice * item.quantity),
      );
      if (storeSubtotal < 1000) deliveryFee += 99.0;
    });

    final total = subtotal + platformFee + deliveryFee;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Checkout'), centerTitle: true),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveLayout(
              maxWidth: 800,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAddressSection(addressesAsync, colorScheme, theme),
                    const SizedBox(height: 32),
                    _buildOrderSummary(groupedItems, theme, colorScheme),
                    const SizedBox(height: 32),
                    _buildPaymentMethod(colorScheme, theme),
                    const SizedBox(height: 32),
                    _buildBillCard(
                      subtotal,
                      platformFee,
                      deliveryFee,
                      total,
                      theme,
                      colorScheme,
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
      bottomSheet: _isProcessing
          ? null
          : _buildBottomBar(total, cartItems, colorScheme),
    );
  }

  Widget _buildAddressSection(
    AsyncValue<List<UserAddress>> addressesAsync,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionHeader(title: 'Delivery Address'),
            TextButton(
              onPressed: () => context.push(AppRoutes.buyerAddresses),
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        addressesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (addresses) {
            if (addresses.isEmpty) {
              return _buildAddressPlaceholder(colorScheme, theme);
            }
            return _buildAddressCard(colorScheme, theme);
          },
        ),
      ],
    );
  }

  Widget _buildAddressPlaceholder(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined, color: colorScheme.error),
          const SizedBox(height: 8),
          const Text(
            'No address selected',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.buyerAddresses),
            child: const Text('Add Shipping Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, color: colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedAddress?.fullName ?? 'No Name',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _selectedAddress?.fullAddress ?? 'No Address',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Phone: ${_selectedAddress?.phone ?? "N/A"}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => _showAddressPicker(),
          ),
        ],
      ),
    );
  }

  void _showAddressPicker() {
    final addresses = ref.read(userAddressesProvider).value ?? [];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Address',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...addresses.map(
              (a) => ListTile(
                title: Text(a.fullName),
                subtitle: Text(a.fullAddress),
                trailing: a.id == _selectedAddress?.id
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() => _selectedAddress = a);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    Map<String, List<dynamic>> groupedItems,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Order Summary'),
        const SizedBox(height: 12),
        ...groupedItems.entries.map((entry) {
          final storeName = entry.value.first.storeName;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  storeName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              ...entry.value.map(
                (item) => _buildOrderItem(item, theme, colorScheme),
              ),
              const Divider(),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildOrderItem(
    dynamic item,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Qty: ${item.quantity}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          AppPriceText(amount: item.unitPrice * item.quantity),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined),
          const SizedBox(width: 16),
          const Expanded(child: Text('Cash on Delivery (COD)')),
          Icon(Icons.radio_button_checked, color: colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildBillCard(
    double subtotal,
    double platformFee,
    double deliveryFee,
    double total,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _billRow('Subtotal', subtotal, theme),
          const SizedBox(height: 12),
          _billRow('Platform Fee', platformFee, theme),
          const SizedBox(height: 12),
          _billRow('Delivery Fee', deliveryFee, theme),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payable',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    double total,
    List<dynamic> cartItems,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: FilledButton(
            onPressed: _selectedAddress == null
                ? null
                : () => _handlePlaceOrder(cartItems),
            child: Text(
              'Confirm Order - ₹${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder(List<dynamic> cartItems) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _selectedAddress == null) return;

    setState(() => _isProcessing = true);

    try {
      final groupedBySeller = <String, List<dynamic>>{};
      for (final item in cartItems) {
        groupedBySeller.putIfAbsent(item.storeId, () => []);
        groupedBySeller[item.storeId]!.add(item);
      }

      final ordersToCreate = <AppOrder>[];
      final now = DateTime.now();

      for (final entry in groupedBySeller.entries) {
        final items = entry.value;
        final sub = items.fold<double>(
          0,
          (sum, item) => sum + (item.unitPrice * item.quantity),
        );
        final delFee = sub < 1000 ? 99.0 : 0.0;
        final platFee = sub * 0.02;

        ordersToCreate.add(
          AppOrder(
            orderId: '',
            buyerId: currentUser.uid,
            buyerName: _selectedAddress!.fullName,
            storeId: entry.key,
            storeName: items.first.storeName,
            status: OrderStatus.pending,
            items: items
                .map(
                  (i) => OrderItem(
                    productId: i.productId,
                    title: i.title,
                    imageUrl: i.imageUrl,
                    quantity: i.quantity,
                    unitPrice: i.unitPrice,
                  ),
                )
                .toList(),
            subtotal: sub,
            deliveryFee: delFee,
            platformFee: platFee,
            totalAmount: sub + delFee + platFee,
            paymentMethod: 'COD',
            paymentStatus: 'pending',
            deliveryAddress: _selectedAddress!.fullAddress,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      await ref
          .read(orderControllerProvider.notifier)
          .checkout(
            orders: ordersToCreate,
            onFailure: (error) {
              if (!mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error)));
              setState(() => _isProcessing = false);
            },
            onSuccess: () async {
              await ref.read(cartControllerProvider.notifier).clearCart();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order placed successfully!')),
              );
              context.go('/buyer/orders');
            },
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isProcessing = false);
    }
  }

  Widget _billRow(String label, double amount, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyLarge),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
