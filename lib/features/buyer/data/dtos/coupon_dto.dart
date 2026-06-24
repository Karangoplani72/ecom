import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/coupon.dart';

class CouponDto {
  final String id;
  final String code;
  final String discountType;
  final double value;
  final double minOrderValue;
  final Timestamp expiryDate;
  final int usageLimitPerUser;
  final bool isActive;

  const CouponDto({
    required this.id,
    required this.code,
    required this.discountType,
    required this.value,
    required this.minOrderValue,
    required this.expiryDate,
    required this.usageLimitPerUser,
    required this.isActive,
  });

  factory CouponDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return CouponDto(
      id: doc.id,
      code: data['code'] as String? ?? '',
      discountType: data['discountType'] as String? ?? 'flat',
      value: (data['value'] as num? ?? 0).toDouble(),
      minOrderValue: (data['minOrderValue'] as num? ?? 0).toDouble(),
      expiryDate: data['expiryDate'] as Timestamp? ?? Timestamp.now(),
      usageLimitPerUser: data['usageLimitPerUser'] as int? ?? 1,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Coupon toDomain() {
    return Coupon(
      id: id,
      code: code,
      discountType: discountType,
      value: value,
      minOrderValue: minOrderValue,
      expiryDate: expiryDate.toDate(),
      usageLimitPerUser: usageLimitPerUser,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'discountType': discountType,
      'value': value,
      'minOrderValue': minOrderValue,
      'expiryDate': expiryDate,
      'usageLimitPerUser': usageLimitPerUser,
      'isActive': isActive,
    };
  }
}
