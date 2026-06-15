import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecom/features/marketplace/data/repositories/marketplace_repository_impl.dart';
import 'package:ecom/features/marketplace/domain/repositories/marketplace_repository.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'dart:async';
part 'marketplace_controller.g.dart';

@riverpod
MarketplaceRepository marketplaceRepository(Ref ref) {
  return MarketplaceRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
class MarketplaceController extends _$MarketplaceController {
  @override
  FutureOr<List<CatalogItem>> build() async {
    final repo = ref.read(marketplaceRepositoryProvider);
    final result = await repo.fetchGlobalCatalog(limit: 20);
    return result.fold(
          (error) => throw Exception(error),
          (items) => items,
    );
  }

  Future<void> loadNextCatalogPage(DocumentSnapshot lastDoc) async {
    final repo = ref.read(marketplaceRepositoryProvider);
    final result = await repo.fetchGlobalCatalog(limit: 20, startAfterDoc: lastDoc);

    result.fold(
          (error) => state = AsyncValue.error(error, StackTrace.current),
          (newItems) {
        final currentItems = state.value ?? [];
        state = AsyncValue.data([...currentItems, ...newItems]);
      },
    );
  }
}