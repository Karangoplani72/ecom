import '../entities/seller_dashboard_data.dart';

abstract class SellerDashboardRepository {
  Future<SellerDashboardData> getDashboardData({required String sellerId});
}
