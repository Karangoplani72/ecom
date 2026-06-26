import 'dart:ui';

import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/services/razorpay_service.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/domain/entities/platform_config.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/features/auth/domain/entities/user_address.dart';
import 'package:ecom/features/auth/presentation/controllers/address_controller.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/domain/entities/coupon.dart';
import 'package:ecom/features/buyer/data/repositories/coupon_repository_impl.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';
import 'package:ecom/shared/presentation/navigation/router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  UserAddress? _selectedAddress;
  bool _isProcessing = false;
  int _currentStep = 0; // 0: Address, 1: Review, 2: Payment

  List<CartItem> _capturedCartItems = const [];
  String? _capturedRazorpayOrderId;

  // Pre-warmed on screen open so the provider is alive when the user taps Pay.
  // razorpayKeyProvider is NOT autoDispose — safe to ref.read inside async gap.
  String? _cachedRazorpayKey;

  @override
  void initState() {
    super.initState();
    // Trigger key fetch eagerly; cache it so _handlePlaceOrder never
    // races against provider disposal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(razorpayKeyProvider.future)
          .then((key) {
            if (mounted) setState(() => _cachedRazorpayKey = key);
          })
          .catchError((_) {
            /* error surfaced at pay-tap time */
          });
    });
  }

  Future<void> _finalizePayment({
    required String paymentId,
    required String rzpOrderId,
    required String signature,
  }) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null || _selectedAddress == null) {
        throw Exception('Session expired. Please log in again and retry.');
      }

      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('Unable to authenticate. Please log in again.');
      }

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
            announcementText: '',
            featuredCategory: '',
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
        } catch (_) {}

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
                  if (i.skuId != null) 'skuId': i.skuId,
                  if (i.selectedCombination != null)
                    'selectedCombination': i.selectedCombination,
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

      final appliedCoupon = ref.read(appliedCouponProvider);

      await verifyAndFinalizePayment(
        razorpayPaymentId: paymentId,
        razorpayOrderId: rzpOrderId,
        razorpaySignature: signature,
        buyerId: userId,
        buyerName: _selectedAddress!.fullName,
        deliveryAddress: _selectedAddress!.fullAddress,
        orders: ordersPayload,
        idToken: idToken,
        couponCode: appliedCoupon?.code,
      );

      await ref.read(cartControllerProvider.notifier).clearCart();

      // Redeem the coupon atomically — fire and forget, do not block UX
      if (appliedCoupon != null) {
        // Find coupon id from the validated coupon
        ref.read(couponRepositoryProvider).redeemCoupon(
          appliedCoupon.id,
          userId,
        ).then((result) {
          result.fold(
            (err) => debugPrint('Coupon redemption failed (non-blocking): $err'),
            (_) => debugPrint('Coupon redeemed successfully'),
          );
        });
      }

      ref.read(appliedCouponProvider.notifier).removeCoupon();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Order placed successfully!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.push('/buyer/orders');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('signature')
                ? '⚠️ Payment verification failed. Please contact support.'
                : 'Payment received but order setup failed: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handlePlaceOrder(List<CartItem> cartItems, double total) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in and select an address to continue.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (cartItems.isEmpty) return;

    _capturedCartItems = List.unmodifiable(cartItems);
    _capturedRazorpayOrderId = null;

    setState(() => _isProcessing = true);

    try {
      final amountInPaise = (total * 100).round();
      // Use pre-warmed cached key; fall back to a fresh fetch only if
      // initState's eager fetch hasn't resolved yet.
      final razorpayKey =
          _cachedRazorpayKey ?? await ref.read(razorpayKeyProvider.future);
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('Authentication expired. Please sign in again.');
      }

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

      final result = await RazorpayService.launch(options);

      if (result is RazorpaySuccess) {
        await _finalizePayment(
          paymentId: result.paymentId,
          rzpOrderId: result.orderId.isNotEmpty
              ? result.orderId
              : _capturedRazorpayOrderId!,
          signature: result.signature,
        );
      } else if (result is RazorpayCancelled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled. Your cart is safe.'),
              backgroundColor: Color(0xFFF59E0B),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (result is RazorpayFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${result.message}'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final cleanMsg = e.toString().replaceFirst(
          RegExp(r'^\w*(Exception|Error): '),
          '',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanMsg),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartControllerProvider);
    final addressesAsync = ref.watch(userAddressesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        backgroundColor: isDark
            ? AppColors.darkBgPrimary
            : AppColors.lightBgPrimary,
        appBar: AppBar(
          title: Text(
            'Checkout',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Your cart is empty.',
            style: GoogleFonts.inter(color: Colors.grey),
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
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );

    final platformConfig =
        ref.watch(platformConfigProvider).value ??
        const PlatformConfig(
          defaultCommissionRate: 0.085,
          categoryCommissionOverrides: {},
          maintenanceModeActive: false,
          globalRateLimitPerMinute: 600,
          razorpayKey: 'managed_via_functions',
          announcementText: '',
          featuredCategory: '',
        );

    final platformFee = subtotal * platformConfig.defaultCommissionRate;
    double deliveryFee = 0.0;
    groupedItems.forEach((storeId, items) {
      final storeSub = items.fold<double>(
        0.0,
        (sum, item) => sum + (item.unitPrice * item.quantity),
      );
      if (storeSub < 1000) {
        deliveryFee += 99.0;
      }
    });

    final appliedCoupon = ref.watch(appliedCouponProvider);
    final discount = appliedCoupon?.calculateDiscount(subtotal) ?? 0.0;
    final total = (subtotal + platformFee + deliveryFee - discount).clamp(0.0, double.infinity);

    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBgPrimary
          : AppColors.lightBgPrimary,
      body: Stack(
        children: [
          const IgnorePointer(child: OrbBackgroundWidget()),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // sliver app bar
              SliverAppBar(
                floating: true,
                pinned: true,
                snap: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leadingWidth: 70,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Center(
                    child: _buildFrostedCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () => context.pop(),
                      isDark: isDark,
                    ),
                  ),
                ),
                title: Text(
                  'Checkout',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                centerTitle: true,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  AppColors.darkBgPrimary.withValues(
                                    alpha: 0.95,
                                  ),
                                  AppColors.darkBgPrimary.withValues(
                                    alpha: 0.6,
                                  ),
                                ]
                              : [
                                  AppColors.lightBgPrimary.withValues(
                                    alpha: 0.95,
                                  ),
                                  AppColors.lightBgPrimary.withValues(
                                    alpha: 0.6,
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Step Indicator Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: GlassCardWidget(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    borderRadius: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStepIndicator(
                          step: 0,
                          label: 'Address',
                          currentStep: _currentStep,
                        ),
                        _buildStepDivider(),
                        _buildStepIndicator(
                          step: 1,
                          label: 'Review',
                          currentStep: _currentStep,
                        ),
                        _buildStepDivider(),
                        _buildStepIndicator(
                          step: 2,
                          label: 'Payment',
                          currentStep: _currentStep,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Step content
              if (_isProcessing)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF7C3AED)),
                        SizedBox(height: 20),
                        Text('Processing payment... please do not close'),
                      ],
                    ),
                  ),
                )
              else ...[
                if (_currentStep == 0)
                  _buildAddressStep(addressesAsync, isDark, textColor),
                if (_currentStep == 1)
                  _buildReviewStep(groupedItems, isDark, textColor),
                if (_currentStep == 2)
                  _buildPaymentStep(
                    subtotal,
                    platformFee,
                    deliveryFee,
                    total,
                    isDark,
                    textColor,
                    platformConfig.defaultCommissionRate,
                    appliedCoupon,
                    discount,
                  ),
              ],
            ],
          ),

          // Bottom navigation actions (Back / Continue)
          if (!_isProcessing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? AppColors.darkBgSurface
                                  : AppColors.lightBgSurface)
                              .withValues(alpha: 0.85),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(
                            alpha: isDark ? 0.08 : 0.3,
                          ),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_currentStep > 0) ...[
                          Expanded(
                            child: GradientButton(
                              label: 'Back',
                              onTap: () {
                                setState(() {
                                  _currentStep--;
                                });
                              },
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.12),
                                  Colors.white.withValues(alpha: 0.04),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          flex: 2,
                          child: GradientButton(
                            label: _currentStep == 2
                                ? 'Pay ₹${total.toStringAsFixed(0)}'
                                : 'Continue',
                            onTap: () {
                              if (_currentStep == 0) {
                                if (_selectedAddress == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select a shipping address',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setState(() {
                                  _currentStep = 1;
                                });
                              } else if (_currentStep == 1) {
                                setState(() {
                                  _currentStep = 2;
                                });
                              } else {
                                _handlePlaceOrder(cartItems, total);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int step,
    required String label,
    required int currentStep,
  }) {
    final isActive = currentStep == step;
    final isDone = currentStep > step;

    return Row(
      children: [
        if (isActive)
          const PulsingDot(size: 8, color: Color(0xFF7C3AED))
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? const Color(0xFF7C3AED) : Colors.grey.shade600,
            ),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
            color: isActive || isDone ? const Color(0xFF7C3AED) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: Colors.grey.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildFrostedCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.2),
        ),
      ),
      child: Center(
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            icon,
            size: 16,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  SliverList _buildAddressStep(
    AsyncValue<List<UserAddress>> addressesAsync,
    bool isDark,
    Color textColor,
  ) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Delivery Address',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 14),
              addressesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
                data: (addresses) {
                  if (addresses.isEmpty) {
                    return _buildAddAddressDashedCard();
                  }

                  return Column(
                    children: [
                      ...addresses.map((addr) {
                        final isSelected = _selectedAddress?.id == addr.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedAddress = addr),
                            child: GlassCardWidget(
                              padding: const EdgeInsets.all(16),
                              borderRadius: 18,
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF7C3AED)
                                            : Colors.grey,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF7C3AED),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          addr.fullName,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          addr.fullAddress,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.darkTextSecond
                                                : AppColors.lightTextSecond,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      _buildAddAddressDashedCard(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildAddAddressDashedCard() {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.buyerAddresses),
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, color: Color(0xFF7C3AED)),
            const SizedBox(width: 8),
            Text(
              'Add New Address',
              style: GoogleFonts.inter(
                color: const Color(0xFF7C3AED),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverList _buildReviewStep(
    Map<String, List<CartItem>> groupedItems,
    bool isDark,
    Color textColor,
  ) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review Order Items',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 14),
              ...groupedItems.entries.map((entry) {
                final storeId = entry.key;

                return Consumer(
                  builder: (context, ref, child) {
                    final storeNameAsync = ref.watch(
                      storeNameProvider(storeId),
                    );
                    final resolvedStoreName =
                        storeNameAsync.value ?? entry.value.first.storeName;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GlassCardWidget(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resolvedStoreName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF7C3AED),
                                fontSize: 13,
                              ),
                            ),
                            const Divider(height: 16),
                            ...entry.value.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: item.imageUrl.startsWith('http')
                                          ? Image.network(
                                              item.imageUrl,
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.asset(
                                              item.imageUrl,
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.contain,
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: textColor,
                                            ),
                                          ),
                                          if (item.selectedCombination !=
                                                  null &&
                                              item
                                                  .selectedCombination!
                                                  .isNotEmpty)
                                            Text(
                                              item.selectedCombination!.entries
                                                  .map(
                                                    (e) =>
                                                        '${e.key}: ${e.value}',
                                                  )
                                                  .join(' · '),
                                              style: GoogleFonts.inter(
                                                color: Colors.purple,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          Text(
                                            'Qty: ${item.quantity}',
                                            style: GoogleFonts.inter(
                                              color: Colors.grey,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${(item.unitPrice * item.quantity).toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ]),
    );
  }

  SliverList _buildPaymentStep(
    double subtotal,
    double platformFee,
    double deliveryFee,
    double total,
    bool isDark,
    Color textColor,
    double commissionRate,
    Coupon? appliedCoupon,
    double discount,
  ) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review & Complete Payment',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 14),
              // Secured by Razorpay trust badge
              GlassCardWidget(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      color: Color(0xFF10B981),
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secured by Razorpay',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'UPI, cards, net banking payments supported.',
                            style: GoogleFonts.inter(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Breakdown bill card
              GlassCardWidget(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildBillBreakdownRow('Subtotal', subtotal, isDark),
                    const SizedBox(height: 8),
                    _buildBillBreakdownRow(
                      'Platform Commission (${(commissionRate * 100).toStringAsFixed(1)}%)',
                      platformFee,
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildBillBreakdownRow('Delivery Fee', deliveryFee, isDark),
                    if (appliedCoupon != null && discount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Coupon (${appliedCoupon.code})',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            '-₹${discount.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Payable',
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        GradientText(
                          '₹${total.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 140),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildBillBreakdownRow(String label, double val, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextSecond
                : AppColors.lightTextSecond,
          ),
        ),
        Text(
          '₹${val.toStringAsFixed(0)}',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}
