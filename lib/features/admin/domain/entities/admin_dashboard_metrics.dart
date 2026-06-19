class AdminDashboardMetrics {
  final int totalUsers;
  final int totalBuyers;
  final int totalSellers;
  final int pendingApplications;
  final int approvedSellers;
  final int rejectedSellers;
  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int outOfStockProducts;
  final int totalOrders;
  final int pendingOrders;
  final int processingOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final double platformRevenue;
  final int totalChats;
  final int totalDisputes;
  final int openDisputes;

  const AdminDashboardMetrics({
    this.totalUsers = 0,
    this.totalBuyers = 0,
    this.totalSellers = 0,
    this.pendingApplications = 0,
    this.approvedSellers = 0,
    this.rejectedSellers = 0,
    this.totalProducts = 0,
    this.activeProducts = 0,
    this.inactiveProducts = 0,
    this.outOfStockProducts = 0,
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.processingOrders = 0,
    this.shippedOrders = 0,
    this.deliveredOrders = 0,
    this.cancelledOrders = 0,
    this.totalRevenue = 0,
    this.platformRevenue = 0,
    this.totalChats = 0,
    this.totalDisputes = 0,
    this.openDisputes = 0,
  });
}
