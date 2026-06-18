import 'package:fpdart/fpdart.dart';

import '../entities/store_profile.dart';

abstract class SellerRepository {
  Future<Either<Exception, StoreProfile>> getStoreProfileBySeller(
    String sellerId,
  );

  Future<Either<Exception, Unit>> updateStorefrontMetadata(
    String storeId,
    Map<String, dynamic> updateData,
  );
}
