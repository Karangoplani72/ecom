import 'package:flutter/foundation.dart';

enum TransactionType {
  orderRevenue('order_revenue'),
  refund('refund'),
  payoutRequest('payout_request'),
  payoutCompleted('payout_completed'),
  platformFee('platform_fee'),
  adjustment('adjustment'),
  sale('sale'),
  unknown('unknown');

  final String value;

  const TransactionType(this.value);

  static TransactionType fromString(String? value) {
    if (value == 'payout') {
      return TransactionType.payoutCompleted;
    }
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => TransactionType.unknown,
    );
  }
}

enum TransactionStatus {
  pending('pending'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled');

  final String value;

  const TransactionStatus(this.value);

  static TransactionStatus fromString(String? value) {
    return values.firstWhere(
      (status) => status.value == value,
      orElse: () => TransactionStatus.pending,
    );
  }
}

@immutable
class SellerTransaction {
  final String id;
  final String storeId;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String currency;
  final String? referenceId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? completedAt;

  const SellerTransaction({
    required this.id,
    required this.storeId,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    this.referenceId,
    this.description,
    this.metadata,
    required this.createdAt,
    this.completedAt,
  });

  /// Check if transaction is completed
  bool get isCompleted => status == TransactionStatus.completed;

  /// Check if transaction failed
  bool get isFailed => status == TransactionStatus.failed;

  /// Check if transaction is still pending
  bool get isPending => status == TransactionStatus.pending;

  /// Check if transaction is revenue (positive impact)
  bool get isRevenue => type == TransactionType.orderRevenue && amount > 0;

  /// Check if transaction is debit (negative impact)
  bool get isDebit =>
      (type == TransactionType.refund ||
          type == TransactionType.platformFee ||
          type == TransactionType.payoutRequest) &&
      amount > 0;

  /// Get time taken to complete in seconds (if completed)
  int? get completionTimeSeconds {
    if (!isCompleted || completedAt == null) return null;
    return completedAt!.difference(createdAt).inSeconds;
  }

  factory SellerTransaction.empty() {
    return SellerTransaction(
      id: '',
      storeId: '',
      type: TransactionType.adjustment,
      status: TransactionStatus.pending,
      amount: 0,
      currency: 'INR',
      createdAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SellerTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          storeId == other.storeId &&
          type == other.type &&
          status == other.status &&
          amount == other.amount &&
          currency == other.currency &&
          referenceId == other.referenceId &&
          description == other.description &&
          createdAt == other.createdAt &&
          completedAt == other.completedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      storeId.hashCode ^
      type.hashCode ^
      status.hashCode ^
      amount.hashCode ^
      currency.hashCode ^
      referenceId.hashCode ^
      description.hashCode ^
      createdAt.hashCode ^
      completedAt.hashCode;

  SellerTransaction copyWith({
    String? id,
    String? storeId,
    TransactionType? type,
    TransactionStatus? status,
    double? amount,
    String? currency,
    String? referenceId,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return SellerTransaction(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      referenceId: referenceId ?? this.referenceId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'SellerTransaction(id: $id, storeId: $storeId, '
        'type: ${type.value}, status: ${status.value}, amount: $amount)';
  }
}
