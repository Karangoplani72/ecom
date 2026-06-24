import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/marketplace/data/repositories/search_repository_impl.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/marketplace/domain/repositories/search_repository.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_controller.g.dart';

@riverpod
SearchRepository searchRepository(Ref ref) {
  return SearchRepositoryImpl(firestore: ref.watch(firebaseFirestoreProvider));
}

@riverpod
Future<List<String>> recentSearches(Ref ref) async {
  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null) return [];

  final result = await ref.watch(searchRepositoryProvider).getRecentSearches(user.uid);
  return result.fold(
    (l) => [],
    (r) => r,
  );
}

@riverpod
class SearchController extends _$SearchController {
  @override
  FutureOr<List<CatalogItem>> build() {
    return [];
  }

  Future<void> search({
    required String query,
    Set<String> categories = const {},
    String sortMode = 'popular',
  }) async {
    state = const AsyncLoading();

    final result = await ref.read(searchRepositoryProvider).searchCatalog(
          query: query,
          categories: categories,
          sortMode: sortMode,
        );

    result.fold(
      (l) => state = AsyncError(l, StackTrace.current),
      (r) {
        state = AsyncData(r);
        
        // Save recent search if we have a user and query is not empty
        if (query.isNotEmpty) {
          final user = ref.read(currentUserProfileProvider).value;
          if (user != null) {
            ref.read(searchRepositoryProvider).saveRecentSearch(query, user.uid);
            ref.invalidate(recentSearchesProvider);
          }
        }
      },
    );
  }

  Future<void> clearRecentSearches() async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user != null) {
      await ref.read(searchRepositoryProvider).clearRecentSearches(user.uid);
      ref.invalidate(recentSearchesProvider);
    }
  }
}
