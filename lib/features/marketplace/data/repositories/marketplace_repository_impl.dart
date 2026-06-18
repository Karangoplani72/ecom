import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/marketplace/data/dtos/catalog_item_dto.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/marketplace/domain/repositories/marketplace_repository.dart';
import 'package:fpdart/fpdart.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final FirebaseFirestore _firestore;

  MarketplaceRepositoryImpl({required this._firestore});

  @override
  Future<Either<String, List<CatalogItem>>> fetchGlobalCatalog({
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) async {
    try {
      Query query = _firestore
          .collection('catalog')
          .where('status', isEqualTo: 'active')
          .where(
            'type',
            isEqualTo: 'product',
          ) // FIX: only return products, not services
          .limit(limit);

      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      final snapshot = await query.get();

      final items = snapshot.docs
          .map((doc) => CatalogItemDto.fromFirestore(doc).toDomain())
          .toList();

      return Right(items);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<CatalogItem>>> fetchItemsByStore({
    required String storeId,
    CatalogType? filterType,
  }) async {
    try {
      Query query = _firestore
          .collection('catalog')
          .where('storeId', isEqualTo: storeId);

      if (filterType != null) {
        query = query.where('type', isEqualTo: filterType.name);
      }

      final snapshot = await query.get();

      final items = snapshot.docs
          .map((doc) => CatalogItemDto.fromFirestore(doc).toDomain())
          .toList();

      return Right(items);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<CatalogItem>>> searchLocalServices({
    required String geohashPrefix,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('catalog')
          .where('type', isEqualTo: 'service')
          .get();

      final items = snapshot.docs
          .map((doc) => CatalogItemDto.fromFirestore(doc).toDomain())
          .toList();

      return Right(items);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, CatalogItem>> fetchProductById({
    required String productId,
  }) async {
    try {
      final doc = await _firestore.collection('catalog').doc(productId).get();

      if (!doc.exists) {
        return Left('Product not found');
      }

      return Right(CatalogItemDto.fromFirestore(doc).toDomain());
    } catch (e) {
      return Left(e.toString());
    }
  }
}
