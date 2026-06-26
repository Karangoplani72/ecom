import 'package:flutter/foundation.dart';

@immutable
class Coupon {
  final String id;
  final String code;
  final String discountType; // 'percentage' or 'flat'
  final double value;
  final double minOrderValue;
  final DateTime? expiryDate;
  final int usageLimitPerUser;
  final bool isActive;
  final int totalUsageLimit;   // 0 = unlimited
  final int usageCount;        // current total redemptions
  final List<String> usedBy;   // list of uids who used it
  final bool isFirstOrderOnly;

  const Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.value,
    this.minOrderValue = 0.0,
    this.expiryDate,
    this.usageLimitPerUser = 1,
    this.isActive = true,
    this.totalUsageLimit = 0,
    this.usageCount = 0,
    this.usedBy = const [],
    this.isFirstOrderOnly = false,
  });

  bool get isValid {
    return isActive && (expiryDate == null || expiryDate!.isAfter(DateTime.now())) && (totalUsageLimit == 0 || usageCount < totalUsageLimit);
  }

  double calculateDiscount(double subtotal) {
    if (subtotal < minOrderValue) return 0.0;
    if (discountType == 'percentage') {
      return subtotal * (value / 100);
    } else {
      return value > subtotal ? subtotal : value;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coupon &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          discountType == other.discountType &&
          value == other.value &&
          minOrderValue == other.minOrderValue &&
          expiryDate == other.expiryDate &&
          usageLimitPerUser == other.usageLimitPerUser &&
          isActive == other.isActive &&
          totalUsageLimit == other.totalUsageLimit &&
          usageCount == other.usageCount &&
          listEquals(usedBy, other.usedBy) &&
          isFirstOrderOnly == other.isFirstOrderOnly;

  @override
  int get hashCode =>
      id.hashCode ^
      code.hashCode ^
      discountType.hashCode ^
      value.hashCode ^
      minOrderValue.hashCode ^
      expiryDate.hashCode ^
      usageLimitPerUser.hashCode ^
      isActive.hashCode ^
      totalUsageLimit.hashCode ^
      usageCount.hashCode ^
      usedBy.hashCode ^
      isFirstOrderOnly.hashCode;

  Coupon copyWith({
    String? id,
    String? code,
    String? discountType,
    double? value,
    double? minOrderValue,
    DateTime? expiryDate,
    int? usageLimitPerUser,
    bool? isActive,
    int? totalUsageLimit,
    int? usageCount,
    List<String>? usedBy,
    bool? isFirstOrderOnly,
  }) {
    return Coupon(
      id: id ?? this.id,
      code: code ?? this.code,
      discountType: discountType ?? this.discountType,
      value: value ?? this.value,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      expiryDate: expiryDate ?? this.expiryDate,
      usageLimitPerUser: usageLimitPerUser ?? this.usageLimitPerUser,
      isActive: isActive ?? this.isActive,
      totalUsageLimit: totalUsageLimit ?? this.totalUsageLimit,
      usageCount: usageCount ?? this.usageCount,
      usedBy: usedBy ?? this.usedBy,
      isFirstOrderOnly: isFirstOrderOnly ?? this.isFirstOrderOnly,
    );
  }
}
