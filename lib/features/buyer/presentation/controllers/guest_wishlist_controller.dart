import 'dart:convert';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/marketplace/data/dtos/catalog_item_dto.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guest_wishlist_controller.g.dart';

@riverpod
class GuestWishlistController extends _$GuestWishlistController {
  static const _guestWishlistKey = 'guest_wishlist';

  @override
  List<CatalogItem> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final wishlistString = prefs.getString(_guestWishlistKey);
    if (wishlistString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(wishlistString);
        return decoded
            .map((item) => CatalogItemDto.fromJson(item as Map<String, dynamic>).toDomain())
            .toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  void _save(List<CatalogItem> newList) {
    state = newList;
    final prefs = ref.read(sharedPreferencesProvider);
    final encoded = jsonEncode(newList.map((e) {
      return CatalogItemDto(
        id: e.id,
        storeId: e.storeId,
        title: e.title,
        description: e.description,
        type: e.type.name,
        status: e.status.name,
        basePrice: e.basePrice,
        currency: e.currency,
        imageUrls: e.imageUrls,
        metadata: e.metadata,
      ).toJson();
    }).toList());
    prefs.setString(_guestWishlistKey, encoded);
  }

  void addItem(CatalogItem item) {
    final current = List<CatalogItem>.from(state);
    if (!current.any((element) => element.id == item.id)) {
      current.add(item);
      _save(current);
    }
  }

  void removeItem(String productId) {
    final current = List<CatalogItem>.from(state);
    current.removeWhere((element) => element.id == productId);
    _save(current);
  }

  bool isInWishlist(String productId) {
    return state.any((element) => element.id == productId);
  }

  void clearWishlist() {
    _save([]);
  }
}
