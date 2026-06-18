import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/seller/data/dtos/store_profile_dto.dart';
import 'package:ecom/features/seller/domain/entities/store_profile.dart';
import 'package:ecom/features/seller/domain/repositories/seller_repository.dart';
import 'package:fpdart/fpdart.dart';

class SellerRepositoryImpl implements SellerRepository {
  final FirebaseFirestore _firestore;

  SellerRepositoryImpl({required this._firestore});

  @override
  Future<Either<Exception, StoreProfile>> getStoreProfileBySeller(
    String sellerId,
  ) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      final snapshot = await _firestore
          .collection('stores')
          .where('sellerId', isEqualTo: sellerId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return Left(
          Exception('No active storefront registered for this seller'),
        );
      }

      final profile = StoreProfileDto.fromFirestore(
        snapshot.docs.first,
      ).toDomain();

      return Right(profile);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to fetch store profile: $e'));
    }
  }

  @override
  Future<Either<Exception, Unit>> updateStorefrontMetadata(
    String storeId,
    Map<String, dynamic> updateDelta,
  ) async {
    try {
      if (storeId.isEmpty) {
        return Left(Exception('Invalid store ID: store ID cannot be empty'));
      }

      if (updateDelta.isEmpty) {
        return Left(
          Exception('No updates provided: update data cannot be empty'),
        );
      }

      // Add server timestamp to track updates
      final dataWithTimestamp = {
        ...updateDelta,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('stores')
          .doc(storeId)
          .update(dataWithTimestamp);

      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to update store metadata: $e'));
    }
  }
}
