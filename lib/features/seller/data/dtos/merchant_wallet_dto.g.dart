// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_wallet_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MerchantWalletDto _$MerchantWalletDtoFromJson(Map<String, dynamic> json) =>
    MerchantWalletDto(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      balance: (json['balance'] as num).toDouble(),
      pendingEscrowBalance: (json['pendingEscrowBalance'] as num).toDouble(),
      currency: json['currency'] as String,
      updatedAt: MerchantWalletDto._timestampToDateTime(json['updatedAt']),
    );

Map<String, dynamic> _$MerchantWalletDtoToJson(MerchantWalletDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeId': instance.storeId,
      'balance': instance.balance,
      'pendingEscrowBalance': instance.pendingEscrowBalance,
      'currency': instance.currency,
      'updatedAt': MerchantWalletDto._dateTimeToTimestamp(instance.updatedAt),
    };
