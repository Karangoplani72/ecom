// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_transaction_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentTransactionDto _$PaymentTransactionDtoFromJson(
  Map<String, dynamic> json,
) => PaymentTransactionDto(
  id: json['id'] as String,
  orderId: json['orderId'] as String,
  buyerId: json['buyerId'] as String,
  storeId: json['storeId'] as String,
  grossAmount: (json['grossAmount'] as num).toDouble(),
  platformCommission: (json['platformCommission'] as num).toDouble(),
  netVendorPayout: (json['netVendorPayout'] as num).toDouble(),
  currency: json['currency'] as String,
  status: json['status'] as String,
  gateway: json['gateway'] as String,
  externalTransactionId: json['externalTransactionId'] as String,
  createdAt: PaymentTransactionDto._timestampToDateTime(json['createdAt']),
);

Map<String, dynamic> _$PaymentTransactionDtoToJson(
  PaymentTransactionDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'buyerId': instance.buyerId,
  'storeId': instance.storeId,
  'grossAmount': instance.grossAmount,
  'platformCommission': instance.platformCommission,
  'netVendorPayout': instance.netVendorPayout,
  'currency': instance.currency,
  'status': instance.status,
  'gateway': instance.gateway,
  'externalTransactionId': instance.externalTransactionId,
  'createdAt': PaymentTransactionDto._dateTimeToTimestamp(instance.createdAt),
};
