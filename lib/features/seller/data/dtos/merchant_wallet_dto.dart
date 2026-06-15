import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ecom/features/seller/domain/entities/merchant_wallet.dart';

part 'merchant_wallet_dto.g.dart';

@JsonSerializable()
class MerchantWalletDto {
  final String id;
  final String storeId;
  final double balance;
  final double pendingEscrowBalance;
  final String currency;

  @JsonKey(fromJson: _timestampToDateTime, toJson: _dateTimeToTimestamp)
  final DateTime updatedAt;

  MerchantWalletDto({
    required this.id,
    required this.storeId,
    required this.balance,
    required this.pendingEscrowBalance,
    required this.currency,
    required this.updatedAt,
  });

  factory MerchantWalletDto.fromJson(Map<String, dynamic> json) => _$MerchantWalletDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantWalletDtoToJson(this);

  factory MerchantWalletDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return MerchantWalletDto.fromJson(data);
  }

  MerchantWallet toDomain() {
    return MerchantWallet(
      id: id,
      storeId: storeId,
      balance: balance,
      pendingEscrowBalance: pendingEscrowBalance,
      currency: currency,
      updatedAt: updatedAt,
    );
  }

  static DateTime _timestampToDateTime(dynamic val) => (val is Timestamp) ? val.toDate() : DateTime.now();
  static dynamic _dateTimeToTimestamp(DateTime date) => Timestamp.fromDate(date);
}