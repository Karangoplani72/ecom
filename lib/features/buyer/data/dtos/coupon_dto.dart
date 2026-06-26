import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/coupon.dart';

class CouponDto {
  final String id;
  final String code;
  final String discountType;
  final double value;
  final double minOrderValue;
  final Timestamp? expiryDate;
  final int usageLimitPerUser;
  final bool isActive;
  final int totalUsageLimit;
  final int usageCount;
  final List<String> usedBy;
  final bool isFirstOrderOnly;

  const CouponDto({
    required this.id,
    required this.code,
    required this.discountType,
    required this.value,
    required this.minOrderValue,
    this.expiryDate,
    required this.usageLimitPerUser,
    required this.isActive,
    required this.totalUsageLimit,
    required this.usageCount,
    required this.usedBy,
    required this.isFirstOrderOnly,
  });

  factory CouponDto.fromFirestore(DocumentSnapshot<Object?> doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    return CouponDto(
      id: doc.id,
      code: data['code'] as String? ?? '',
      discountType: data['discountType'] as String? ?? 'flat',
      value: (data['value'] as num? ?? 0).toDouble(),
      minOrderValue: (data['minOrderValue'] as num? ?? 0).toDouble(),
      expiryDate: data['expiryDate'] as Timestamp?,
      usageLimitPerUser: data['usageLimitPerUser'] as int? ?? 1,
      isActive: data['isActive'] as bool? ?? true,
      totalUsageLimit: data['totalUsageLimit'] as int? ?? 0,
      usageCount: data['usageCount'] as int? ?? 0,
      usedBy: List<String>.from(data['usedBy'] as List? ?? []),
      isFirstOrderOnly: data['isFirstOrderOnly'] as bool? ?? false,
    );
  }

  Coupon toDomain() {
    return Coupon(
      id: id,
      code: code,
      discountType: discountType,
      value: value,
      minOrderValue: minOrderValue,
      expiryDate: expiryDate?.toDate(),
      usageLimitPerUser: usageLimitPerUser,
      isActive: isActive,
      totalUsageLimit: totalUsageLimit,
      usageCount: usageCount,
      usedBy: usedBy,
      isFirstOrderOnly: isFirstOrderOnly,
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
      'totalUsageLimit': totalUsageLimit,
      'usageCount': usageCount,
      'usedBy': usedBy,
      'isFirstOrderOnly': isFirstOrderOnly,
    };
  }
}
