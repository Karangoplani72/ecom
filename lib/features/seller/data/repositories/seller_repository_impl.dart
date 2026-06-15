import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/seller/domain/repositories/seller_repository.dart';
import 'package:ecom/features/seller/data/dtos/store_profile_dto.dart';
import 'package:ecom/features/seller/domain/entities/store_profile.dart';

class SellerRepositoryImpl implements SellerRepository {
  final FirebaseFirestore _firestore;

  SellerRepositoryImpl({required this._firestore}) {
    // TODO: implement SellerRepositoryImpl
    throw UnimplementedError();
  }

  @override
  Future<Either<String, StoreProfile>> getStoreProfileBySeller(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('stores')
          .where('sellerId', isEqualTo: sellerId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Left("No active storefront registered under this merchant identifier.");
      }

      return Right(StoreProfileDto.fromFirestore(snapshot.docs.first).toDomain());
    } catch (e) {
      return Left("Storefront Fetch Error: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, Unit>> updateStorefrontMetadata(String storeId, Map<String, dynamic> updateDelta) async {
    try {
      await _firestore.collection('stores').doc(storeId).update(updateDelta);
      return const Right(unit);
    } catch (e) {
      return Left("Metadata Write Matrix Fault: ${e.toString()}");
    }
  }
}