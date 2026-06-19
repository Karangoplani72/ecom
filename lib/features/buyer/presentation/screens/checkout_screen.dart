import 'dart:ui';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_price_text.dart';
import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/features/auth/domain/entities/user_address.dart';
import 'package:ecom/features/auth/presentation/controllers/address_controller.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/orders/domain/entities/order.dart';
import 'package:ecom/features/orders/domain/entities/order_item.dart';
import 'package:ecom/features/orders/domain/entities/order_status.dart';
import 'package:ecom/features/orders/presentation/controllers/order_controller.dart';
import 'package:ecom/shared/presentation/navigation/router.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  UserAddress? _selectedAddress;
  bool _isProcessing = false;
  String _paymentMethod = 'COD';

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartControllerProvider);
    final addressesAsync = ref.watch(userAddressesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    addressesAsync.whenData((addresses) {
      if (_selectedAddress == null && addresses.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedAddress = addresses.firstWhere(
                (a) => a.isDefault,
                orElse: () => addresses.first,
              );
            });
          }
        });
      }
    });

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold))),
        body: AppEmptyView(
          title: 'Cart is empty',
          subtitle: 'Add items to your cart before checking out.',
          icon: Icons.shopping_cart_outlined,
          action: AppPrimaryButton(
            onPressed: () => context.go('/buyer/home'),
            text: 'Go Shopping',
            icon: Icons.storefront,
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
      if (storeSubtotal < 1000) {
        deliveryFee += 99.0;
      }
    });

    final total = subtotal + platformFee + deliveryFee;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Placing your order...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            )
          : ResponsiveLayout(
              maxWidth: 800,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAddressSection(addressesAsync, isDark, theme),
                        const SizedBox(height: 32),
                        _buildOrderSummary(groupedItems, isDark),
                        const SizedBox(height: 32),
                        _buildPaymentMethodSection(isDark, theme),
                        const SizedBox(height: 32),
                        _buildBillCard(
                          subtotal,
                          platformFee,
                          deliveryFee,
                          total,
                          isDark,
                        ),
                        const SizedBox(height: 140), // Space for sticky bottom bar
                      ],
                    ),
                  ),
                  _buildBottomBar(total, cartItems, isDark, theme),
                ],
              ),
            ),
    );
  }

  Widget _buildAddressSection(
    AsyncValue<List<UserAddress>> addressesAsync,
    bool isDark,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.buyerAddresses),
              child: const Text('Manage', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        addressesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error loading addresses: $e'),
          data: (addresses) {
            if (addresses.isEmpty) {
              return _buildAddressPlaceholder(isDark);
            }
            if (_selectedAddress == null) {
              return _buildAddressPlaceholder(isDark);
            }
            return _buildAddressCard(isDark);
          },
        ),
      ],
    );
  }

  Widget _buildAddressPlaceholder(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_off_outlined, color: AppColors.error, size: 36),
          const SizedBox(height: 12),
          const Text(
            'No address selected',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.push(AppRoutes.buyerAddresses),
            child: const Text('Add Shipping Address', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.primaryLight : AppColors.primary, width: 2),
        boxShadow: isDark ? AppShadows.darkSm : AppShadows.lightSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on_outlined, color: isDark ? AppColors.primaryLight : AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedAddress?.fullName ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedAddress?.fullAddress ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phone: ${_selectedAddress?.phone ?? ''}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: _showAddressPicker,
            tooltip: 'Change Address',
          ),
        ],
      ),
    );
  }

  void _showAddressPicker() {
    final addresses = ref.read(userAddressesProvider).value ?? [];
    if (addresses.isEmpty) {
      context.push(AppRoutes.buyerAddresses);
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Delivery Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),
            ...addresses.map(
              (a) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: a.id == _selectedAddress?.id ? (isDark ? AppColors.primaryLight : AppColors.primary) : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                  borderRadius: BorderRadius.circular(16),
                  color: a.id == _selectedAddress?.id ? (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.05) : Colors.transparent,
                ),
                child: ListTile(
                  title: Text(a.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(a.fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: a.id == _selectedAddress?.id
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : null,
                  onTap: () {
                    setState(() => _selectedAddress = a);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.buyerAddresses);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    Map<String, List<CartItem>> groupedItems,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 16),
        ...groupedItems.entries.map((entry) {
          final storeName = entry.value.first.storeName;
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: isDark ? AppShadows.darkSm : AppShadows.lightSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.storefront,
                        size: 20,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      storeName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...entry.value.map(
                  (item) => _buildOrderItem(item, isDark),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOrderItem(
    CartItem item,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDark ? AppShadows.darkSm : AppShadows.lightSm,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                  child: Icon(Icons.image_outlined, size: 24, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Text(
                    'Qty: ${item.quantity}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppPriceText(amount: item.unitPrice * item.quantity),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 16),
        RadioGroup<String>(
          groupValue: _paymentMethod,
          onChanged: (val) => setState(() => _paymentMethod = val!),
          child: Column(
            children: [
              _PaymentOptionTile(
                icon: Icons.money,
                title: 'Cash on Delivery',
                subtitle: 'Pay when your order arrives',
                value: 'COD',
                isSelected: _paymentMethod == 'COD',
                isDark: isDark,
              ),
              _PaymentOptionTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'UPI Payment',
                subtitle: 'Pay via Google Pay, PhonePe, Paytm',
                value: 'UPI',
                isSelected: _paymentMethod == 'UPI',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillCard(
    double subtotal,
    double platformFee,
    double deliveryFee,
    double total,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: isDark ? AppShadows.darkSm : AppShadows.lightSm,
      ),
      child: Column(
        children: [
          _billRow('Subtotal', subtotal, isDark, isBold: false),
          const SizedBox(height: 12),
          _billRow('Platform Fee (2%)', platformFee, isDark, isBold: false),
          const SizedBox(height: 12),
          _billRow(
            deliveryFee == 0 ? 'Delivery (Free)' : 'Delivery Fee',
            deliveryFee,
            isDark,
            isBold: false,
            valueColor: deliveryFee == 0 ? AppColors.success : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payable',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
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
    List<CartItem> cartItems,
    bool isDark,
    ThemeData theme,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: SafeArea(
              child: AppPrimaryButton(
                text: _selectedAddress == null
                    ? 'Select Address to Continue'
                    : 'Confirm Order — ₹${total.toStringAsFixed(2)}',
                onPressed: _selectedAddress == null
                    ? null
                    : () => _handlePlaceOrder(cartItems),
                icon: Icons.check_circle_outline,
                isLoading: _isProcessing,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder(List<CartItem> cartItems) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _selectedAddress == null) return;

    setState(() => _isProcessing = true);

    try {
      final groupedBySeller = <String, List<CartItem>>{};
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
            buyerId: userId,
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
            paymentMethod: _paymentMethod,
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order failed: $error'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              setState(() => _isProcessing = false);
            },
            onSuccess: () async {
              await ref.read(cartControllerProvider.notifier).clearCart();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Order placed successfully!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              context.go('/buyer/orders');
            },
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
      );
      setState(() => _isProcessing = false);
    }
  }

  Widget _billRow(String label, double amount, bool isDark, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          amount == 0 ? 'Free' : '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final bool isSelected;
  final bool isDark;

  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected ? (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.05) : (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? (isDark ? AppColors.primaryLight : AppColors.primary) : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isDark ? AppShadows.darkSm : AppShadows.lightSm,
      ),
      child: RadioListTile<String>(
        value: value,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: isDark ? AppColors.primaryLight : AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 44, top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
        activeColor: isDark ? AppColors.primaryLight : AppColors.primary,
        contentPadding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
