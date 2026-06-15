class MerchantWallet {
  final String id;
  final String storeId;
  final double balance;
  final double pendingEscrowBalance;
  final String currency;
  final DateTime updatedAt;

  const MerchantWallet({
    required this.id,
    required this.storeId,
    required this.balance,
    required this.pendingEscrowBalance,
    required this.currency,
    required this.updatedAt,
  });
}