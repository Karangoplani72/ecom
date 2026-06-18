import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/seller_transaction.dart';

class SellerTransactionDto {
  final String id;
  final String storeId;
  final String type;
  final String status;
  final double amount;
  final String currency;
  final String? referenceId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final Timestamp? createdAt;
  final Timestamp? completedAt;

  const SellerTransactionDto({
    required this.id,
    required this.storeId,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    this.referenceId,
    this.description,
    this.metadata,
    this.createdAt,
    this.completedAt,
  });

  factory SellerTransactionDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return SellerTransactionDto(
      id: doc.id,
      storeId: data['storeId'] as String? ?? '',
      type: data['type'] as String? ?? 'adjustment',
      status: data['status'] as String? ?? 'pending',
      amount: (data['amount'] as num? ?? 0).toDouble(),
      currency: data['currency'] as String? ?? 'INR',
      referenceId: data['referenceId'] as String?,
      description: data['description'] as String?,
      metadata: Map<String, dynamic>.from(
        (data['metadata'] as Map<dynamic, dynamic>? ?? {})
            .cast<String, dynamic>(),
      ),
      createdAt: data['createdAt'] as Timestamp?,
      completedAt: data['completedAt'] as Timestamp?,
    );
  }

  SellerTransaction toDomain() {
    return SellerTransaction(
      id: id,
      storeId: storeId,
      type: TransactionType.fromString(type),
      status: TransactionStatus.fromString(status),
      amount: amount,
      currency: currency,
      referenceId: referenceId,
      description: description,
      metadata: metadata,
      createdAt: createdAt?.toDate() ?? DateTime.now(),
      completedAt: completedAt?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId,
      'type': type,
      'status': status,
      'amount': amount,
      'currency': currency,
      'referenceId': referenceId,
      'description': description,
      'metadata': metadata,
      'createdAt': createdAt,
      'completedAt': completedAt,
    };
  }

  SellerTransactionDto copyWith({
    String? id,
    String? storeId,
    String? type,
    String? status,
    double? amount,
    String? currency,
    String? referenceId,
    String? description,
    Map<String, dynamic>? metadata,
    Timestamp? createdAt,
    Timestamp? completedAt,
  }) {
    return SellerTransactionDto(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SellerTransactionDto &&
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

  @override
  String toString() {
    return 'SellerTransactionDto(id: $id, storeId: $storeId, '
        'type: $type, status: $status, amount: $amount)';
  }
}
