class SellerDashboardData {
  final double totalRevenue;
  final int totalOrders;
  final int totalProducts;
  final int pendingOrders;

  final int activeProducts;
  final int lowStockProducts;
  final int outOfStockProducts;

  final List<Map<String, dynamic>> recentOrders;
  final List<Map<String, dynamic>> lowStockItems;

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
}
