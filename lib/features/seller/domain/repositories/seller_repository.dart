import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/seller/domain/entities/store_profile.dart';

abstract class SellerRepository {
  Future<Either<String, StoreProfile>> getStoreProfileBySeller(String sellerId);
  Future<Either<String, Unit>> updateStorefrontMetadata(String storeId, Map<String, dynamic> updateDelta);
}