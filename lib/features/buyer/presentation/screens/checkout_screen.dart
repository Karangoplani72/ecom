import 'dart:ui';

import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/services/razorpay_service.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/theme/app_shadows.dart';
import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_price_text.dart';
import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/core/widgets/cards/glass_card.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/core/widgets/scaffolds/premium_25d_scaffold.dart';
import 'package:ecom/features/admin/domain/entities/platform_config.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/features/auth/domain/entities/user_address.dart';
import 'package:ecom/features/auth/presentation/controllers/address_controller.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
// order_status and order_controller not needed here:
// all order writes now go via the verifyAndFinalizePayment Cloud Function.
import 'package:ecom/shared/presentation/navigation/router.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  /// Snapshot of cart captured before opening Razorpay — used in
  /// _finalizePaymentAsync even if the provider rebuilds during the flow.
  List<CartItem> _capturedCartItems = const [];
  String? _capturedRazorpayOrderId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Payment finalization (called after successful Razorpay payment) ─────────

  Future<void> _finalizePayment({
    required String paymentId,
    required String rzpOrderId,
    required String signature,
  }) async {
    debugPrint(
      '[PAYMENT] _finalizePayment: paymentId=$paymentId rzpOrderId=$rzpOrderId signaturePresent=${signature.isNotEmpty}',
    );

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null || _selectedAddress == null) {
        throw Exception('Session expired. Please log in again and retry.');
      }

      debugPrint('[AUTH] Requesting ID token for server verification...');
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('Unable to authenticate. Please log in again.');
      }

      debugPrint(
        '[PAYMENT] Building order payloads for ${_capturedCartItems.length} captured cart items...',
      );
      final groupedBySeller = <String, List<CartItem>>{};
      for (final item in _capturedCartItems) {
        groupedBySeller.putIfAbsent(item.storeId, () => []).add(item);
      }

      final platformConfig =
          ref.read(platformConfigProvider).value ??
          const PlatformConfig(
            defaultCommissionRate: 0.085,
            categoryCommissionOverrides: {},
            maintenanceModeActive: false,
            globalRateLimitPerMinute: 600,
            razorpayKey: 'managed_via_functions',
          );

      final ordersPayload = <Map<String, dynamic>>[];
      for (final entry in groupedBySeller.entries) {
        final items = entry.value;
        final sub = items.fold<double>(
          0,
          (s, i) => s + (i.unitPrice * i.quantity),
        );
        final delFee = sub < 1000 ? 99.0 : 0.0;
        final platFee = sub * platformConfig.defaultCommissionRate;

        String storeName = items.first.storeName;
        try {
          storeName = await ref
              .read(storeNameProvider(entry.key).future)
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          debugPrint(
            '[CHECKOUT] Warning: store name resolution timed out for ${entry.key}. Using cached name.',
          );
        }

        ordersPayload.add({
          'storeId': entry.key,
          'storeName': storeName,
          'items': items
              .map(
                (i) => {
                  'productId': i.productId,
                  'title': i.title,
                  'imageUrl': i.imageUrl,
                  'quantity': i.quantity,
                  'unitPrice': i.unitPrice,
                },
              )
              .toList(),
          'subtotal': sub,
          'deliveryFee': delFee,
          'platformFee': platFee,
          'totalAmount': sub + delFee + platFee,
          'paymentMethod': 'Online (Razorpay)',
        });
      }

      debugPrint(
        '[PAYMENT] Calling verifyAndFinalizePayment CF: paymentId=$paymentId rzpOrderId=$rzpOrderId orders=${ordersPayload.length}',
      );

      await verifyAndFinalizePayment(
        razorpayPaymentId: paymentId,
        razorpayOrderId: rzpOrderId,
        razorpaySignature: signature,
        buyerId: userId,
        buyerName: _selectedAddress!.fullName,
        deliveryAddress: _selectedAddress!.fullAddress,
        orders: ordersPayload,
        idToken: idToken,
      );

      debugPrint('[SUCCESS] Orders finalized. Clearing cart and navigating...');

      if (!mounted) return;
      // Cart cleared server-side by CF; also clear client-side for instant UI update
      await ref.read(cartControllerProvider.notifier).clearCart();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 Order placed successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      context.go('/buyer/orders');
    } catch (e) {
      debugPrint('[PAYMENT][ERROR] _finalizePayment failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('signature')
                ? '⚠️ Payment verification failed. Please contact support.'
                : 'Payment received but order setup failed: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
      return Premium25DScaffold(
        isDark: isDark,
        appBar: AppBar(
          title: const Text(
            'Checkout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
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

    final configAsync = ref.watch(platformConfigProvider);
    final platformConfig =
        configAsync.value ??
        const PlatformConfig(
          defaultCommissionRate: 0.085,
          categoryCommissionOverrides: {},
          maintenanceModeActive: false,
          globalRateLimitPerMinute: 600,
          razorpayKey: 'managed_via_functions',
        );
    final commissionRate = platformConfig.defaultCommissionRate;
    final platformFee = subtotal * commissionRate;
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

    return Premium25DScaffold(
      isDark: isDark,
      particles: [
        FloatingParticle(
          imagePath: 'assets/images/25d_bag.svg',
          width: 50,
          height: 50,
          dx: -100,
          dy: 150,
          delay: 0.2,
          depth: 1.2,
        ),
        FloatingParticle(
          imagePath: 'assets/images/25d_sphere.svg',
          width: 30,
          height: 30,
          dx: 300,
          dy: 400,
          delay: 0.7,
          depth: 0.6,
        ),
      ],
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
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
                    'Processing payment...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please do not close this screen',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
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
                        _buildPaymentMethodSection(isDark),
                        const SizedBox(height: 32),
                        _buildBillCard(
                          subtotal,
                          platformFee,
                          deliveryFee,
                          total,
                          isDark,
                          commissionRate,
                        ),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                  _buildBottomBar(total, cartItems, isDark),
                ],
              ),
            ),
    );
  }

  // ── Address Section ────────────────────────────────────────────────────────

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
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.buyerAddresses),
              child: const Text(
                'Manage',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        addressesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error loading addresses: $e'),
          data: (addresses) {
            if (addresses.isEmpty) return _buildAddressPlaceholder(isDark);
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
          const Icon(
            Icons.location_off_outlined,
            color: AppColors.error,
            size: 36,
          ),
          const SizedBox(height: 12),
          const Text(
            'No address selected',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.push(AppRoutes.buyerAddresses),
            child: const Text(
              'Add Shipping Address',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(bool isDark) {
    return GlassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryLight : AppColors.primary)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              size: 24,
            ),
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
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedAddress?.fullAddress ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phone: ${_selectedAddress?.phone ?? ''}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
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
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),
            ...addresses.map((a) {
              final isSelected = a.id == _selectedAddress?.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: isSelected
                      ? (isDark ? AppColors.primaryLight : AppColors.primary)
                            .withValues(alpha: 0.05)
                      : Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? (isDark
                                ? AppColors.primaryLight
                                : AppColors.primary)
                          : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      a.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      a.fullAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                          )
                        : null,
                    onTap: () {
                      setState(() => _selectedAddress = a);
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.buyerAddresses);
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add New Address',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Order Summary ──────────────────────────────────────────────────────────

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
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 16),
        ...groupedItems.entries.map((entry) {
          final storeId = entry.key;
          return Consumer(
            builder: (context, ref, child) {
              final storeNameAsync = ref.watch(storeNameProvider(storeId));
              final resolvedStoreName =
                  storeNameAsync.value ?? entry.value.first.storeName;
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
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
                            color:
                                (isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primary)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.storefront,
                            size: 20,
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          resolvedStoreName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...entry.value.map((item) => _buildOrderItem(item, isDark)),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildOrderItem(CartItem item, bool isDark) {
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
                  child: Icon(
                    Icons.image_outlined,
                    size: 24,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
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
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Text(
                    'Qty: ${item.quantity}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
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

  // ── Payment Method Section ─────────────────────────────────────────────────

  Widget _buildPaymentMethodSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 16),
        _PaymentOptionTile(
          icon: Icons.credit_card,
          title: 'Razorpay (Online)',
          subtitle: 'Pay via Card, UPI, Netbanking, Wallets',
          isSelected: true,
          isDark: isDark,
        ),
      ],
    );
  }

  // ── Bill Card ──────────────────────────────────────────────────────────────

  Widget _buildBillCard(
    double subtotal,
    double platformFee,
    double deliveryFee,
    double total,
    bool isDark,
    double commissionRate,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark ? AppShadows.darkSm : AppShadows.lightSm,
      ),
      child: Column(
        children: [
          _billRow('Subtotal', subtotal, isDark),
          const SizedBox(height: 12),
          _billRow(
            'Platform Fee (${(commissionRate * 100).toStringAsFixed(1)}%)',
            platformFee,
            isDark,
          ),
          const SizedBox(height: 12),
          _billRow(
            deliveryFee == 0 ? 'Delivery (Free)' : 'Delivery Fee',
            deliveryFee,
            isDark,
            valueColor: deliveryFee == 0 ? AppColors.success : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payable',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
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

  // ── Bottom Bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar(double total, List<CartItem> cartItems, bool isDark) {
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
              color: isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.8),
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

  // ── Place Order ────────────────────────────────────────────────────────────

  Future<void> _handlePlaceOrder(List<CartItem> cartItems) async {
    final userId = ref.read(currentUserIdProvider);
    debugPrint(
      '[CHECKOUT] _handlePlaceOrder: userId=$userId'
      ' cartItems=${cartItems.length}'
      ' address=${_selectedAddress?.fullName}',
    );

    if (userId == null || _selectedAddress == null) {
      debugPrint('[CHECKOUT][ERROR] userId or address is null. Aborting.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in and select an address to continue.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (cartItems.isEmpty) {
      debugPrint('[CHECKOUT][ERROR] Cart is empty. Aborting.');
      return;
    }

    // Snapshot cart items BEFORE opening Razorpay.
    _capturedCartItems = List.unmodifiable(cartItems);
    _capturedRazorpayOrderId = null;

    setState(() => _isProcessing = true);

    try {
      // ── 1. Compute totals ─────────────────────────────────────────────────
      final subtotal = _capturedCartItems.fold<double>(
        0,
        (s, i) => s + (i.unitPrice * i.quantity),
      );
      final platformConfig =
          ref.read(platformConfigProvider).value ??
          const PlatformConfig(
            defaultCommissionRate: 0.085,
            categoryCommissionOverrides: {},
            maintenanceModeActive: false,
            globalRateLimitPerMinute: 600,
            razorpayKey: 'managed_via_functions',
          );
      final platformFee = subtotal * platformConfig.defaultCommissionRate;

      final groupedItems = <String, List<CartItem>>{};
      for (final item in _capturedCartItems) {
        groupedItems.putIfAbsent(item.storeId, () => []).add(item);
      }
      double deliveryFee = 0;
      groupedItems.forEach((_, items) {
        final s = items.fold<double>(
          0,
          (sum, i) => sum + (i.unitPrice * i.quantity),
        );
        if (s < 1000) deliveryFee += 99.0;
      });
      final total = subtotal + platformFee + deliveryFee;
      final amountInPaise = (total * 100).round();

      debugPrint(
        '[CHECKOUT] Totals — subtotal=$subtotal'
        ' platformFee=$platformFee'
        ' deliveryFee=$deliveryFee'
        ' total=$total'
        ' paise=$amountInPaise',
      );

      // ── 2. Fetch public Razorpay key from Cloud Function ──────────────────
      debugPrint('[RAZORPAY] Fetching public key from Cloud Function...');
      final razorpayKey = await ref.read(razorpayKeyProvider.future);
      debugPrint(
        '[RAZORPAY] Key received (prefix): ${razorpayKey.substring(0, 12)}...',
      );

      // ── 3. Get Firebase ID token ──────────────────────────────────────────
      debugPrint('[AUTH] Fetching Firebase ID token...');
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('Authentication expired. Please sign in again.');
      }

      // ── 4. Create server-side Razorpay order ─────────────────────────────
      debugPrint(
        '[RAZORPAY] Creating server-side order: amount=$amountInPaise paise...',
      );
      final rzpOrderData = await createRazorpayOrder(
        amountInPaise: amountInPaise,
        idToken: idToken,
        receipt:
            'rcpt_${userId.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}',
      );

      _capturedRazorpayOrderId = rzpOrderData['id'] as String?;
      if (_capturedRazorpayOrderId == null ||
          _capturedRazorpayOrderId!.isEmpty) {
        throw Exception('Failed to create payment order. Please try again.');
      }
      debugPrint('[RAZORPAY] Server order created: $_capturedRazorpayOrderId');

      // ── 5. Build options and launch Razorpay (platform-aware) ────────────
      final options = <String, dynamic>{
        'key': razorpayKey,
        'amount': amountInPaise,
        'order_id': _capturedRazorpayOrderId!,
        'name': 'E-Commerce App',
        'description': 'Order for ${_capturedCartItems.length} item(s)',
        'timeout': 300,
        'prefill': {
          'contact': _selectedAddress!.phone,
          'email':
              FirebaseAuth.instance.currentUser?.email ?? 'customer@ecom.app',
          'name': _selectedAddress!.fullName,
        },
        'notes': {
          'buyer_id': userId,
          'item_count': _capturedCartItems.length.toString(),
        },
      };

      debugPrint(
        '[RAZORPAY] Launching checkout. options.keys=${options.keys.toList()}',
      );

      // ── THE FIX: Use RazorpayService which uses JS interop on Web,
      // ──          native SDK on Android/iOS. Awaits the result as a Future.
      final result = await RazorpayService.launch(options);

      debugPrint('[RAZORPAY] Checkout result: ${result.runtimeType}');

      // ── 6. Handle result ──────────────────────────────────────────────────
      if (result is RazorpaySuccess) {
        debugPrint(
          '[PAYMENT][SUCCESS] paymentId=${result.paymentId} orderId=${result.orderId}',
        );
        // _isProcessing stays true during finalization
        await _finalizePayment(
          paymentId: result.paymentId,
          rzpOrderId: result.orderId.isNotEmpty
              ? result.orderId
              : _capturedRazorpayOrderId!,
          signature: result.signature,
        );
        // _isProcessing is reset inside _finalizePayment finally block
        return; // don't reset _isProcessing twice
      } else if (result is RazorpayCancelled) {
        debugPrint('[PAYMENT] User cancelled Razorpay checkout.');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment cancelled. Your cart is safe.'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else if (result is RazorpayFailure) {
        debugPrint(
          '[PAYMENT][ERROR] code=${result.code} message=${result.message}',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${result.message}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[CHECKOUT][ERROR] _handlePlaceOrder threw: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      // Always reset loading state — covers error, cancel, and failure paths.
      // Success path resets inside _finalizePayment.
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _billRow(
    String label,
    double amount,
    bool isDark, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          amount == 0 ? 'Free' : '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color:
                valueColor ??
                (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }
}

// ── Payment Option Tile ────────────────────────────────────────────────────

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isDark;

  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? AppShadows.darkSm : AppShadows.lightSm,
      ),
      child: Material(
        color: isSelected
            ? (isDark ? AppColors.primaryLight : AppColors.primary).withValues(
                alpha: 0.05,
              )
            : (isDark ? AppColors.surfaceDark : Colors.white),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? (isDark ? AppColors.primaryLight : AppColors.primary)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryLight : AppColors.primary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                )
              : null,
        ),
      ),
    );
  }
}
