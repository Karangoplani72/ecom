import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/seller/data/dtos/store_profile_dto.dart';
import 'package:ecom/features/seller/domain/entities/store_profile.dart';
import 'package:ecom/features/seller/domain/repositories/seller_repository.dart';
import 'package:fpdart/fpdart.dart';

class SellerRepositoryImpl implements SellerRepository {
  final FirebaseFirestore firestore;

  SellerRepositoryImpl({required this.firestore});

  @override
  Future<Either<Exception, StoreProfile>> getStoreProfileBySeller(
    String sellerId,
  ) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      final doc = await firestore.collection('stores').doc(sellerId).get();

      if (!doc.exists) {
        // Store doc is missing! Let's recover it.
        final userDoc = await firestore.collection('users').doc(sellerId).get();
        if (!userDoc.exists) {
          return Left(Exception('User profile not found. Recovery failed.'));
        }

        final userData = userDoc.data() ?? {};
        final displayName = userData['displayName'] as String? ?? 'Seller';
        final email = userData['email'] as String? ?? '';
        final phone = userData['phoneNumber'] as String? ?? '';

        final appSnapshot = await firestore
            .collection('sellerApplications')
            .doc(sellerId)
            .get();

        String storeName = '$displayName\'s Store';
        String storeDescription = 'Welcome to our storefront!';
        String businessCategory = 'Other';
        String gstNumber = '';

        if (appSnapshot.exists) {
          final appData = appSnapshot.data() ?? {};
          storeName = appData['storeName'] as String? ?? storeName;
          storeDescription = appData['storeDescription'] as String? ?? appData['description'] as String? ?? storeDescription;
          businessCategory = appData['businessCategory'] as String? ?? businessCategory;
          gstNumber = appData['gstNumber'] as String? ?? gstNumber;
        }

        final storeSlug = storeName
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
            .replaceAll(RegExp(r'\s+'), '-');

        final newStoreProfile = {
          'storeId': sellerId,
          'sellerId': sellerId,
          'storeName': storeName,
          'storeSlug': storeSlug,
          'storeDescription': storeDescription,
          'logoUrl': null,
          'bannerUrl': null,
          'businessCategory': businessCategory,
          'rating': 0.0,
          'totalReviews': 0,
          'totalProducts': 0,
          'totalOrders': 0,
          'isVerified': true,
          'isActive': true,
          'phone': phone,
          'email': email,
          'gstNumber': gstNumber,
          'address': '',
          'status': 'verified',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await firestore.collection('stores').doc(sellerId).set(newStoreProfile);

        final recoveredDoc = await firestore.collection('stores').doc(sellerId).get();
        return Right(StoreProfileDto.fromFirestore(recoveredDoc).toDomain());
      }

      final profile = StoreProfileDto.fromFirestore(doc).toDomain();
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

      final dataWithTimestamp = {
        ...updateDelta,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await firestore
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
