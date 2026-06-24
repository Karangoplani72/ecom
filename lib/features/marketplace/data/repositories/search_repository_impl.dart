import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/marketplace/data/dtos/catalog_item_dto.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/marketplace/domain/repositories/search_repository.dart';
import 'package:fpdart/fpdart.dart';

class SearchRepositoryImpl implements SearchRepository {
  final FirebaseFirestore _firestore;

  SearchRepositoryImpl({required this._firestore});

  @override
  Future<Either<String, List<CatalogItem>>> searchCatalog({
    required String query,
    Set<String> categories = const {},
    String sortMode = 'popular',
    int limit = 50,
    DocumentSnapshot? startAfterDoc,
  }) async {
    try {
      Query q = _firestore
          .collection('catalog')
          .where('isActive', isEqualTo: true);

      // Filtering by category if any are selected
      if (categories.isNotEmpty) {
        if (categories.length == 1) {
          q = q.where('metadata.category', isEqualTo: categories.first);
        } else {
          q = q.where('metadata.category', whereIn: categories.toList());
        }
      }

      // Keyword array search for Firestore
      if (query.isNotEmpty) {
        final keywords = query
            .toLowerCase()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(10)
            .toList();
        if (keywords.isNotEmpty) {
          // Note: Firestore array-contains-any supports up to 10 elements.
          // This assumes `searchKeywords` array is populated by a Cloud Function on write.
          q = q.where('searchKeywords', arrayContainsAny: keywords);
        }
      }

      // Sorting
      switch (sortMode) {
        case 'price_asc':
          q = q.orderBy('basePrice', descending: false);
          break;
        case 'price_desc':
          q = q.orderBy('basePrice', descending: true);
          break;
        case 'newest':
          q = q.orderBy('createdAt', descending: true);
          break;
        case 'popular':
        default:
          // Just use default order (could be based on reviewCount or rating if we had a combined score)
          break;
      }

      if (startAfterDoc != null) {
        q = q.startAfterDocument(startAfterDoc);
      }

      q = q.limit(limit);

      final snapshot = await q.get();
      final items = snapshot.docs
          .map((doc) => CatalogItemDto.fromFirestore(doc).toDomain())
          .toList();

      return Right(items);
    } catch (e) {
      return Left('Search failed: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, List<String>>> getSearchSuggestions(
    String prefix,
  ) async {
    // In a real production app, you might use Algolia or Typesense for prefix search.
    // Here we will just return a static empty list or implement basic local matching.
    return const Right([]);
  }

  @override
  Future<Either<String, Unit>> saveRecentSearch(
    String query,
    String userId,
  ) async {
    try {
      if (query.trim().isEmpty) return const Right(unit);

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('recent_searches')
          .doc(query.trim().toLowerCase());
      await docRef.set({
        'query': query.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left('Failed to save search: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, List<String>>> getRecentSearches(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recent_searches')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final searches = snapshot.docs
          .map((d) => d.data()['query'] as String)
          .toList();
      return Right(searches);
    } catch (e) {
      return Left('Failed to load recent searches: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Unit>> clearRecentSearches(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recent_searches')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return const Right(unit);
    } catch (e) {
      return Left('Failed to clear searches: ${e.toString()}');
    }
  }
}
