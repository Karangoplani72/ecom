import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/buyer/domain/repositories/wishlist_repository.dart';
import 'package:ecom/features/marketplace/data/dtos/catalog_item_dto.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:fpdart/fpdart.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final FirebaseFirestore _firestore;

  WishlistRepositoryImpl({required this._firestore});

  @override
  Stream<Either<String, List<CatalogItem>>> watchWishlist({
    required String userId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        final futures = snapshot.docs.map((doc) async {
          final productId = doc.data()['productId'] as String?;
          if (productId == null) return null;
          final productDoc = await _firestore
              .collection('catalog')
              .doc(productId)
              .get();
          if (!productDoc.exists) return null;
          return CatalogItemDto.fromFirestore(productDoc).toDomain();
        });
        final results = await Future.wait(futures);
        final items = results.whereType<CatalogItem>().toList();
        return Right<String, List<CatalogItem>>(items);
      } catch (e) {
        return Left<String, List<CatalogItem>>(e.toString());
      }
    });
  }

  @override
  Future<Either<String, void>> addToWishlist({
    required String userId,
    required CatalogItem item,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(item.id)
          .set({'productId': item.id, 'addedAt': FieldValue.serverTimestamp()});
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> removeFromWishlist({
    required String userId,
    required String productId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(productId)
          .delete();
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<bool> isInWishlist({
    required String userId,
    required String productId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(productId)
          .get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }
}
