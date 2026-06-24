import 'package:flutter/foundation.dart';

@immutable
class Coupon {
  final String id;
  final String code;
  final String discountType; // 'percentage' or 'flat'
  final double value;
  final double minOrderValue;
  final DateTime expiryDate;
  final int usageLimitPerUser;
  final bool isActive;

  const Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.value,
    this.minOrderValue = 0.0,
    required this.expiryDate,
    this.usageLimitPerUser = 1,
    this.isActive = true,
  });

  bool get isValid {
    return isActive && expiryDate.isAfter(DateTime.now());
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
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      code.hashCode ^
      discountType.hashCode ^
      value.hashCode ^
      minOrderValue.hashCode ^
      expiryDate.hashCode ^
      usageLimitPerUser.hashCode ^
      isActive.hashCode;

  Coupon copyWith({
    String? id,
    String? code,
    String? discountType,
    double? value,
    double? minOrderValue,
    DateTime? expiryDate,
    int? usageLimitPerUser,
    bool? isActive,
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
    );
  }
}
