import 'package:fpdart/fpdart.dart';

import '../entities/seller_dashboard_data.dart';

abstract class SellerDashboardRepository {
  Future<Either<Exception, SellerDashboardData>> getDashboardData({
    required String sellerId,
  });

  Future<Either<Exception, Map<String, dynamic>>> getDashboardMetrics({
    required String sellerId,
    required DateTime? startDate,
    required DateTime? endDate,
  });
}
