import 'package:flutter/foundation.dart';

@immutable
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

  /// Total available balance (current + pending escrow)
  double get totalBalance => balance + pendingEscrowBalance;

  /// Available balance for withdrawal
  double get availableBalance => balance;

  /// Amount locked in escrow
  double get lockedBalance => pendingEscrowBalance;

  /// Check if wallet has sufficient funds
  bool get hasSufficientBalance => availableBalance > 0;

  /// Check if there are pending funds
  bool get hasPendingFunds => pendingEscrowBalance > 0;

  /// Factory constructor for empty wallet
  factory MerchantWallet.empty({required String storeId}) {
    return MerchantWallet(
      id: '',
      storeId: storeId,
      balance: 0,
      pendingEscrowBalance: 0,
      currency: 'INR',
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MerchantWallet &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          storeId == other.storeId &&
          balance == other.balance &&
          pendingEscrowBalance == other.pendingEscrowBalance &&
          currency == other.currency &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      storeId.hashCode ^
      balance.hashCode ^
      pendingEscrowBalance.hashCode ^
      currency.hashCode ^
      updatedAt.hashCode;

  MerchantWallet copyWith({
    String? id,
    String? storeId,
    double? balance,
    double? pendingEscrowBalance,
    String? currency,
    DateTime? updatedAt,
  }) {
    return MerchantWallet(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      balance: balance ?? this.balance,
      pendingEscrowBalance: pendingEscrowBalance ?? this.pendingEscrowBalance,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'MerchantWallet(id: $id, storeId: $storeId, '
        'balance: $balance, currency: $currency)';
  }
}
