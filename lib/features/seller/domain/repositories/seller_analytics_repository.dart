import 'package:fpdart/fpdart.dart';

import '../entities/seller_analytics.dart';

abstract class SellerAnalyticsRepository {
  Future<Either<Exception, SellerAnalytics>> getAnalytics({
    required String sellerId,
  });

  Future<Either<Exception, Map<String, dynamic>>> getRevenueByDate({
    required String sellerId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Exception, Map<String, dynamic>>> getProductAnalytics({
    required String sellerId,
  });

  Future<Either<Exception, Map<String, dynamic>>> getCustomerAnalytics({
    required String sellerId,
  });
}
