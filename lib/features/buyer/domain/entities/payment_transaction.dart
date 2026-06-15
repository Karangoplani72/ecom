enum PaymentStatus { pending, authorized, escrowHeld, released, refunded, failed }
enum GatewayProvider { stripe, razorpay, upi, wallet }

class PaymentTransaction {
  final String id;
  final String orderId;
  final String buyerId;
  final String storeId;
  final double grossAmount;
  final double platformCommission;
  final double netVendorPayout;
  final String currency;
  final PaymentStatus status;
  final GatewayProvider gateway;
  final String externalTransactionId;
  final DateTime createdAt;

  const PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.storeId,
    required this.grossAmount,
    required this.platformCommission,
    required this.netVendorPayout,
    required this.currency,
    required this.status,
    required this.gateway,
    required this.externalTransactionId,
    required this.createdAt,
  });
}