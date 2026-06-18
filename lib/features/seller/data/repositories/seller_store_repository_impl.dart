import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../data/dtos/store_profile_dto.dart';
import '../../domain/entities/store_profile.dart';
import '../../domain/repositories/seller_store_repository.dart';

class SellerStoreRepositoryImpl implements SellerStoreRepository {
  final FirebaseFirestore _firestore;
  static const String _storesCollection = 'stores';

  SellerStoreRepositoryImpl({required this._firestore});

  @override
  Future<Either<Exception, StoreProfile>> getStoreProfile({
    required String storeId,
  }) async {
    try {
      if (storeId.isEmpty) {
        return Left(Exception('Invalid store ID: store ID cannot be empty'));
      }

      final doc = await _firestore
          .collection(_storesCollection)
          .doc(storeId)
          .get();

      if (!doc.exists) {
        return Left(Exception('Store not found: $storeId'));
      }

      final profile = StoreProfileDto.fromFirestore(doc).toDomain();
      return Right(profile);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get store profile: $e'));
    }
  }

  @override
  Future<Either<Exception, Unit>> updateStoreProfile({
    required String storeId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      if (storeId.isEmpty) {
        return Left(Exception('Invalid store ID: store ID cannot be empty'));
      }

      if (updates.isEmpty) {
        return Left(
          Exception('No updates provided: update data cannot be empty'),
        );
      }

      final updateData = {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_storesCollection)
          .doc(storeId)
          .update(updateData);

      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to update store profile: $e'));
    }
  }

  @override
  Future<Either<Exception, Unit>> updateStoreLogo({
    required String storeId,
    required String logoUrl,
  }) async {
    try {
      if (storeId.isEmpty) {
        return Left(Exception('Invalid store ID: store ID cannot be empty'));
      }

      if (logoUrl.isEmpty) {
        return Left(Exception('Invalid logo URL: logo URL cannot be empty'));
      }

      await _firestore.collection(_storesCollection).doc(storeId).update({
        'logoUrl': logoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to update store logo: $e'));
    }
  }

  @override
  Future<Either<Exception, Unit>> updateStoreBanner({
    required String storeId,
    required String bannerUrl,
  }) async {
    try {
      if (storeId.isEmpty) {
        return Left(Exception('Invalid store ID: store ID cannot be empty'));
      }

      if (bannerUrl.isEmpty) {
        return Left(
          Exception('Invalid banner URL: banner URL cannot be empty'),
        );
      }

      await _firestore.collection(_storesCollection).doc(storeId).update({
        'bannerUrl': bannerUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to update store banner: $e'));
    }
  }

  @override
  Future<Either<Exception, Unit>> updateStoreVerification({
    required String storeId,
    required String status,
  }) async {
    try {
      if (storeId.isEmpty) {
        return Left(Exception('Invalid store ID: store ID cannot be empty'));
      }

      if (status.isEmpty) {
        return Left(Exception('Invalid status: status cannot be empty'));
      }

      final validStatuses = {
        'pending',
        'applied',
        'underReview',
        'verified',
        'rejected',
        'suspended',
      };

      if (!validStatuses.contains(status)) {
        return Left(
          Exception(
            'Invalid status: "$status" is not a valid verification status',
          ),
        );
      }

      await _firestore.collection(_storesCollection).doc(storeId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to update store verification: $e'));
    }
  }

  @override
  Future<Either<Exception, List<StoreProfile>>> getStoresByStatus({
    required String status,
  }) async {
    try {
      if (status.isEmpty) {
        return Left(Exception('Invalid status: status cannot be empty'));
      }

      final snapshot = await _firestore
          .collection(_storesCollection)
          .where('status', isEqualTo: status)
          .get();

      final stores = snapshot.docs
          .map((doc) => StoreProfileDto.fromFirestore(doc).toDomain())
          .toList();

      return Right(stores);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get stores by status: $e'));
    }
  }
}
