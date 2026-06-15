import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ecom/features/buyer/domain/entities/payment_transaction.dart';

part 'payment_transaction_dto.g.dart';

@JsonSerializable()
class PaymentTransactionDto {
  final String id;
  final String orderId;
  final String buyerId;
  final String storeId;
  final double grossAmount;
  final double platformCommission;
  final double netVendorPayout;
  final String currency;
  final String status;
  final String gateway;
  final String externalTransactionId;

  @JsonKey(fromJson: _timestampToDateTime, toJson: _dateTimeToTimestamp)
  final DateTime createdAt;

  PaymentTransactionDto({
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

  factory PaymentTransactionDto.fromJson(Map<String, dynamic> json) => _$PaymentTransactionDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentTransactionDtoToJson(this);

  factory PaymentTransactionDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return PaymentTransactionDto.fromJson(data);
  }

  PaymentTransaction toDomain() {
    return PaymentTransaction(
      id: id,
      orderId: orderId,
      buyerId: buyerId,
      storeId: storeId,
      grossAmount: grossAmount,
      platformCommission: platformCommission,
      netVendorPayout: netVendorPayout,
      currency: currency,
      status: PaymentStatus.values.byName(status),
      gateway: GatewayProvider.values.byName(gateway),
      externalTransactionId: externalTransactionId,
      createdAt: createdAt,
    );
  }

  static DateTime _timestampToDateTime(dynamic val) => (val is Timestamp) ? val.toDate() : DateTime.now();
  static dynamic _dateTimeToTimestamp(DateTime date) => Timestamp.fromDate(date);
}