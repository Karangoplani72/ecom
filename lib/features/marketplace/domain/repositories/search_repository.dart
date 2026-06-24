import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

abstract class SearchRepository {
  Future<Either<String, List<CatalogItem>>> searchCatalog({
    required String query,
    Set<String> categories = const {},
    String sortMode = 'popular',
    int limit = 50,
    DocumentSnapshot? startAfterDoc,
  });

  Future<Either<String, List<String>>> getSearchSuggestions(String prefix);

  Future<Either<String, Unit>> saveRecentSearch(String query, String userId);

  Future<Either<String, List<String>>> getRecentSearches(String userId);

  Future<Either<String, Unit>> clearRecentSearches(String userId);
}
