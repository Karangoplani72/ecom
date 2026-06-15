import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';

part 'cart_controller.g.dart';

@riverpod
class CartController extends _$CartController {
  @override
  List<CartItem> build() {
    // Injecting dummy data for UI visualization.
    // In production, this would fetch from a local Hive/SQLite database or Firestore.
    return [
      const CartItem(
        id: 'c1',
        productId: 'p1',
        title: 'Rose Gold Gel Extensions',
        storeId: 's1',
        storeName: "Anjali's Elite Studio",
        unitPrice: 1200.0,
        imageUrl: 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=400',
        quantity: 1,
      ),
      const CartItem(
        id: 'c2',
        productId: 'p2',
        title: 'Matte Top Coat 15ml',
        storeId: 's1',
        storeName: "Anjali's Elite Studio",
        unitPrice: 450.0,
        imageUrl: '',
        quantity: 2,
      ),
      const CartItem(
        id: 'c3',
        productId: 'p3',
        title: 'Luxury Spa Pedicure Kit',
        storeId: 's2',
        storeName: 'Nail Aesthetics Co.',
        unitPrice: 899.0,
        imageUrl: '',
        quantity: 1,
      ),
    ];
  }

  void updateQuantity(String itemId, int delta) {
    state = state.map((item) {
      if (item.id == itemId) {
        final newQty = item.quantity + delta;
        return newQty > 0 ? item.copyWith(quantity: newQty) : item;
      }
      return item;
    }).toList();
  }

  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  double get subtotal => state.fold(0, (sum, item) => sum + (item.unitPrice * item.quantity));

  // Helper to group items by store for the UI
  Map<String, List<CartItem>> get groupedByStore {
    final Map<String, List<CartItem>> grouped = {};
    for (var item in state) {
      if (!grouped.containsKey(item.storeName)) {
        grouped[item.storeName] = [];
      }
      grouped[item.storeName]!.add(item);
    }
    return grouped;
  }
}