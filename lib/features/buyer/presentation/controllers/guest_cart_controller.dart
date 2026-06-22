import 'dart:convert';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guest_cart_controller.g.dart';

@riverpod
class GuestCartController extends _$GuestCartController {
  static const _guestCartKey = 'guest_cart';

  @override
  List<CartItem> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final cartString = prefs.getString(_guestCartKey);
    if (cartString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cartString);
        return decoded.map((item) => CartItem.fromMap(item as Map<String, dynamic>)).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  void _save(List<CartItem> newCart) {
    state = newCart;
    final prefs = ref.read(sharedPreferencesProvider);
    final encoded = jsonEncode(newCart.map((e) => e.toMap()).toList());
    prefs.setString(_guestCartKey, encoded);
  }

  void addItem(CartItem item) {
    final current = List<CartItem>.from(state);
    final index = current.indexWhere((element) => element.id == item.id);
    if (index >= 0) {
      final existing = current[index];
      current[index] = existing.copyWith(quantity: existing.quantity + item.quantity);
    } else {
      current.add(item);
    }
    _save(current);
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity < 1) {
      removeItem(itemId);
      return;
    }
    final current = List<CartItem>.from(state);
    final index = current.indexWhere((element) => element.id == itemId);
    if (index >= 0) {
      current[index] = current[index].copyWith(quantity: quantity);
      _save(current);
    }
  }

  void removeItem(String itemId) {
    final current = List<CartItem>.from(state);
    current.removeWhere((element) => element.id == itemId);
    _save(current);
  }

  void clearCart() {
    _save([]);
  }
}
