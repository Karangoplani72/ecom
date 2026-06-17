import '../entities/seller_analytics.dart';

abstract class SellerAnalyticsRepository {
  Future<SellerAnalytics> getAnalytics({required String sellerId});
}
