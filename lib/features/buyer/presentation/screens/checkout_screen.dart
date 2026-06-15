import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/payment_controller.dart';
import 'package:ecom/core/theme/app_theme.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _selectedPaymentMethod = 0; // 0: UPI, 1: Card, 2: Cash on Delivery

  void _processPayment(double totalAmount) async {
    // 1. Generate a mock order ID
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

    // 2. Trigger the Payment Controller
    final intentToken = await ref.read(paymentControllerProvider.notifier)
        .requestCheckoutIntent(orderId, totalAmount);

    if (intentToken != null && mounted) {
      // 3. Simulate external gateway processing (Stripe/Razorpay)
      _showProcessingDialog();

      await Future.delayed(const Duration(seconds: 2)); // Mock network delay

      if (!mounted) return;
      Navigator.of(context).pop(); // Close dialog

      // 4. Confirm payment success with our backend
      await ref.read(paymentControllerProvider.notifier).confirmPaymentSuccess(intentToken);

      if (mounted) {
        _showSuccessDialog();
      }
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.blushPink),
            SizedBox(height: 16),
            Text('Processing payment securely...', style: TextStyle(color: AppTheme.charcoalText)),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Payment Successful!'),
        content: const Text('Your order has been placed and the salon has been notified.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              context.go('/buyer/home'); // Navigate back to home
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fetch cart total directly from our existing CartController
    final subtotal = ref.watch(cartControllerProvider.notifier).subtotal;
    final taxes = subtotal * 0.18; // 18% GST simulation
    final total = subtotal + taxes;

    // Watch payment state for loading indicators
    final paymentState = ref.watch(paymentControllerProvider);
    final isProcessing = paymentState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Delivery / Service Location
                  Text('Service Location', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.creamBackground,
                        child: Icon(Icons.location_on_outlined, color: AppTheme.roseGold),
                      ),
                      title: const Text('Home Address', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('123 Luxury Lane, Vasant Vihar\nNew Delhi, 110057'),
                      trailing: TextButton(onPressed: () {}, child: const Text('Change')),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Payment Methods
                  Text('Payment Method', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        _buildPaymentOption(0, 'UPI (GPay, PhonePe, Paytm)', Icons.qr_code_scanner),
                        const Divider(height: 1, indent: 50),
                        _buildPaymentOption(1, 'Credit / Debit Card', Icons.credit_card),
                        const Divider(height: 1, indent: 50),
                        _buildPaymentOption(2, 'Pay at Salon / COD', Icons.money),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Final Bill Breakdown
                  Text('Bill Details', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildBillRow('Item Total', subtotal),
                          const SizedBox(height: 8),
                          _buildBillRow('Taxes & Fees (18%)', taxes),
                          const Divider(height: 24),
                          _buildBillRow('To Pay', total, isBold: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          boxShadow: [
            BoxShadow(color: AppTheme.charcoalText.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isProcessing ? null : () => _processPayment(total),
              child: isProcessing
                  ? const CircularProgressIndicator(color: AppTheme.surfaceWhite)
                  : Text('Secure Pay  ₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(int index, String title, IconData icon) {
    return RadioListTile(
      value: index,
      groupValue: _selectedPaymentMethod,
      onChanged: (value) => setState(() => _selectedPaymentMethod = value as int),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      secondary: Icon(icon, color: AppTheme.slateGreyText),
      activeColor: AppTheme.blushPink,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }

  Widget _buildBillRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? AppTheme.charcoalText : AppTheme.slateGreyText,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: AppTheme.charcoalText,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}