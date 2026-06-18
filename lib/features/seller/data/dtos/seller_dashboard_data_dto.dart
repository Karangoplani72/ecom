import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/seller_dashboard_data.dart';

class DashboardOrderSummaryDto {
  final String orderId;
  final double amount;
  final String status;
  final Timestamp? createdAt;

  const DashboardOrderSummaryDto({
    required this.orderId,
    required this.amount,
    required this.status,
    this.createdAt,
  });

  factory DashboardOrderSummaryDto.fromJson(Map<String, dynamic> json) {
    return DashboardOrderSummaryDto(
      orderId: json['orderId'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0).toDouble(),
      status: json['status'] as String? ?? '',
      createdAt: json['createdAt'] as Timestamp?,
    );
  }

  DashboardOrderSummary toDomain() {
    return DashboardOrderSummary(
      orderId: orderId,
      amount: amount,
      status: status,
      createdAt: createdAt?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'amount': amount,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

class DashboardProductSummaryDto {
  final String productId;
  final String title;
  final int stock;
  final double price;

  const DashboardProductSummaryDto({
    required this.productId,
    required this.title,
    required this.stock,
    required this.price,
  });

  factory DashboardProductSummaryDto.fromJson(Map<String, dynamic> json) {
    return DashboardProductSummaryDto(
      productId: json['productId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      stock: json['stock'] as int? ?? 0,
      price: (json['price'] as num? ?? 0).toDouble(),
    );
  }

  DashboardProductSummary toDomain() {
    return DashboardProductSummary(
      productId: productId,
      title: title,
      stock: stock,
      price: price,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'stock': stock,
      'price': price,
    };
  }
}

class SellerDashboardDataDto {
  final double totalRevenue;
  final int totalOrders;
  final int totalProducts;
  final int pendingOrders;
  final int activeProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final List<DashboardOrderSummaryDto> recentOrders;
  final List<DashboardProductSummaryDto> lowStockItems;

  const SellerDashboardDataDto({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalProducts,
    required this.pendingOrders,
    required this.activeProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.recentOrders,
    required this.lowStockItems,
  });

  factory SellerDashboardDataDto.fromJson(Map<String, dynamic> json) {
    return SellerDashboardDataDto(
      totalRevenue: (json['totalRevenue'] as num? ?? 0).toDouble(),
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalProducts: json['totalProducts'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      activeProducts: json['activeProducts'] as int? ?? 0,
      lowStockProducts: json['lowStockProducts'] as int? ?? 0,
      outOfStockProducts: json['outOfStockProducts'] as int? ?? 0,
      recentOrders: (json['recentOrders'] as List<dynamic>? ?? [])
          .map(
            (e) => DashboardOrderSummaryDto.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      lowStockItems: (json['lowStockItems'] as List<dynamic>? ?? [])
          .map(
            (e) => DashboardProductSummaryDto.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  SellerDashboardData toDomain() {
    return SellerDashboardData(
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      totalProducts: totalProducts,
      pendingOrders: pendingOrders,
      activeProducts: activeProducts,
      lowStockProducts: lowStockProducts,
      outOfStockProducts: outOfStockProducts,
      recentOrders: recentOrders.map((e) => e.toDomain()).toList(),
      lowStockItems: lowStockItems.map((e) => e.toDomain()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'totalProducts': totalProducts,
      'pendingOrders': pendingOrders,
      'activeProducts': activeProducts,
      'lowStockProducts': lowStockProducts,
      'outOfStockProducts': outOfStockProducts,
      'recentOrders': recentOrders.map((e) => e.toJson()).toList(),
      'lowStockItems': lowStockItems.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SellerDashboardDataDto &&
          runtimeType == other.runtimeType &&
          totalRevenue == other.totalRevenue &&
          totalOrders == other.totalOrders &&
          totalProducts == other.totalProducts &&
          pendingOrders == other.pendingOrders &&
          activeProducts == other.activeProducts &&
          lowStockProducts == other.lowStockProducts &&
          outOfStockProducts == other.outOfStockProducts &&
          recentOrders == other.recentOrders &&
          lowStockItems == other.lowStockItems;

  @override
  int get hashCode =>
      totalRevenue.hashCode ^
      totalOrders.hashCode ^
      totalProducts.hashCode ^
      pendingOrders.hashCode ^
      activeProducts.hashCode ^
      lowStockProducts.hashCode ^
      outOfStockProducts.hashCode ^
      recentOrders.hashCode ^
      lowStockItems.hashCode;

  @override
  String toString() {
    return 'SellerDashboardDataDto(totalRevenue: $totalRevenue, '
        'totalOrders: $totalOrders, pendingOrders: $pendingOrders)';
  }
}
