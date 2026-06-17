class SellerAnalytics {
  final int totalProducts;
  final int activeProducts;
  final int totalOrders;
  final int pendingOrders;
  final double totalRevenue;

  const SellerAnalytics({
    required this.totalProducts,
    required this.activeProducts,
    required this.totalOrders,
    required this.pendingOrders,
    required this.totalRevenue,
  });

  factory SellerAnalytics.empty() {
    return const SellerAnalytics(
      totalProducts: 0,
      activeProducts: 0,
      totalOrders: 0,
      pendingOrders: 0,
      totalRevenue: 0,
    );
  }
}
