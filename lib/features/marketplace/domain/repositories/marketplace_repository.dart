import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:fpdart/fpdart.dart';

abstract class MarketplaceRepository {
  Future<Either<String, List<CatalogItem>>> fetchGlobalCatalog({
    required int limit,
    DocumentSnapshot? startAfterDoc,
  });

  Future<Either<String, List<CatalogItem>>> fetchItemsByStore({
    required String storeId,
    CatalogType? filterType,
  });

  Future<Either<String, List<CatalogItem>>> searchLocalServices({
    required String geohashPrefix,
  });

  Future<Either<String, CatalogItem>> fetchProductById({
    required String productId,
  });
}
