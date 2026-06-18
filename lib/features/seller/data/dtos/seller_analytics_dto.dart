import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/seller_analytics.dart';

class SellerAnalyticsDto {
  final int totalProducts;
  final int activeProducts;
  final int totalOrders;
  final int pendingOrders;
  final double totalRevenue;

  const SellerAnalyticsDto({
    required this.totalProducts,
    required this.activeProducts,
    required this.totalOrders,
    required this.pendingOrders,
    required this.totalRevenue,
  });

  factory SellerAnalyticsDto.fromJson(Map<String, dynamic> json) {
    return SellerAnalyticsDto(
      totalProducts: json['totalProducts'] as int? ?? 0,
      activeProducts: json['activeProducts'] as int? ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num? ?? 0).toDouble(),
    );
  }

  factory SellerAnalyticsDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return SellerAnalyticsDto.fromJson(data);
  }

  SellerAnalytics toDomain() {
    return SellerAnalytics(
      totalProducts: totalProducts,
      activeProducts: activeProducts,
      totalOrders: totalOrders,
      pendingOrders: pendingOrders,
      totalRevenue: totalRevenue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalProducts': totalProducts,
      'activeProducts': activeProducts,
      'totalOrders': totalOrders,
      'pendingOrders': pendingOrders,
      'totalRevenue': totalRevenue,
    };
  }

  SellerAnalyticsDto copyWith({
    int? totalProducts,
    int? activeProducts,
    int? totalOrders,
    int? pendingOrders,
    double? totalRevenue,
  }) {
    return SellerAnalyticsDto(
      totalProducts: totalProducts ?? this.totalProducts,
      activeProducts: activeProducts ?? this.activeProducts,
      totalOrders: totalOrders ?? this.totalOrders,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SellerAnalyticsDto &&
          runtimeType == other.runtimeType &&
          totalProducts == other.totalProducts &&
          activeProducts == other.activeProducts &&
          totalOrders == other.totalOrders &&
          pendingOrders == other.pendingOrders &&
          totalRevenue == other.totalRevenue;

  @override
  int get hashCode =>
      totalProducts.hashCode ^
      activeProducts.hashCode ^
      totalOrders.hashCode ^
      pendingOrders.hashCode ^
      totalRevenue.hashCode;

  @override
  String toString() {
    return 'SellerAnalyticsDto(totalProducts: $totalProducts, '
        'activeProducts: $activeProducts, totalOrders: $totalOrders, '
        'totalRevenue: $totalRevenue)';
  }
}
