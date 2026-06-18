import 'package:fpdart/fpdart.dart';

import '../entities/store_profile.dart';

abstract class SellerStoreRepository {
  Future<Either<Exception, StoreProfile>> getStoreProfile({
    required String storeId,
  });

  Future<Either<Exception, Unit>> updateStoreProfile({
    required String storeId,
    required Map<String, dynamic> updates,
  });

  Future<Either<Exception, Unit>> updateStoreLogo({
    required String storeId,
    required String logoUrl,
  });

  Future<Either<Exception, Unit>> updateStoreBanner({
    required String storeId,
    required String bannerUrl,
  });

  Future<Either<Exception, Unit>> updateStoreVerification({
    required String storeId,
    required String status,
  });

  Future<Either<Exception, List<StoreProfile>>> getStoresByStatus({
    required String status,
  });
}
