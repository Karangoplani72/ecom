import 'package:flutter/foundation.dart';

@immutable
class DashboardOrderSummary {
  final String orderId;
  final double amount;
  final String status;
  final DateTime? createdAt;

  const DashboardOrderSummary({
    required this.orderId,
    required this.amount,
    required this.status,
    this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardOrderSummary &&
          runtimeType == other.runtimeType &&
          orderId == other.orderId &&
          amount == other.amount &&
          status == other.status &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      orderId.hashCode ^ amount.hashCode ^ status.hashCode ^ createdAt.hashCode;
}

@immutable
class DashboardProductSummary {
  final String productId;
  final String title;
  final int stock;
  final double price;

  const DashboardProductSummary({
    required this.productId,
    required this.title,
    required this.stock,
    required this.price,
  });

  bool get isLowStock => stock > 0 && stock <= 5;

  bool get isOutOfStock => stock <= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardProductSummary &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          title == other.title &&
          stock == other.stock &&
          price == other.price;

  @override
  int get hashCode =>
      productId.hashCode ^ title.hashCode ^ stock.hashCode ^ price.hashCode;
}

@immutable
class SellerDashboardData {
  final double totalRevenue;
  final int totalOrders;
  final int totalProducts;
  final int pendingOrders;
  final int activeProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final List<DashboardOrderSummary> recentOrders;
  final List<DashboardProductSummary> lowStockItems;

  const SellerDashboardData({
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

  /// Get average order value
  double get averageOrderValue =>
      totalOrders > 0 ? totalRevenue / totalOrders : 0;

  /// Get completion rate
  double get completionRate =>
      totalOrders > 0 ? ((totalOrders - pendingOrders) / totalOrders) * 100 : 0;

  /// Get product health (percentage of active products)
  double get productHealthPercentage =>
      totalProducts > 0 ? (activeProducts / totalProducts) * 100 : 0;

  /// Check if dashboard has critical alerts
  bool get hasCriticalAlerts =>
      pendingOrders > 10 || outOfStockProducts > 5 || lowStockProducts > 20;

  /// Check if there are any pending orders
  bool get hasPendingOrders => pendingOrders > 0;

  /// Check if there are any out of stock products
  bool get hasOutOfStockProducts => outOfStockProducts > 0;

  /// Check if there are low stock products
  bool get hasLowStockProducts => lowStockProducts > 0;

  factory SellerDashboardData.empty() {
    return const SellerDashboardData(
      totalRevenue: 0,
      totalOrders: 0,
      totalProducts: 0,
      pendingOrders: 0,
      activeProducts: 0,
      lowStockProducts: 0,
      outOfStockProducts: 0,
      recentOrders: [],
      lowStockItems: [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SellerDashboardData &&
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
    return 'SellerDashboardData(totalRevenue: $totalRevenue, '
        'totalOrders: $totalOrders, pendingOrders: $pendingOrders, '
        'activeProducts: $activeProducts)';
  }
}
