import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';

part 'cart_controller.g.dart';

@riverpod
class CartController extends _$CartController {
  @override
  List<CartItem> build() {
    return [
      const CartItem(
        id: 'c1',
        productId: 'p1',
        title: 'Rose Gold Gel Extensions',
        storeId: 's1',
        storeName: "Anjali's Elite Studio",
        unitPrice: 1200,
        imageUrl:
        'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=400',
        quantity: 1,
      ),
      const CartItem(
        id: 'c2',
        productId: 'p2',
        title: 'Matte Top Coat 15ml',
        storeId: 's1',
        storeName: "Anjali's Elite Studio",
        unitPrice: 450,
        imageUrl: '',
        quantity: 2,
      ),
      const CartItem(
        id: 'c3',
        productId: 'p3',
        title: 'Luxury Spa Pedicure Kit',
        storeId: 's2',
        storeName: 'Nail Aesthetics Co.',
        unitPrice: 899,
        imageUrl: '',
        quantity: 1,
      ),
    ];
  }

  // -------------------------
  // Add Item
  // -------------------------

  void addItem(CartItem item) {
    final existing = state.cast<CartItem?>().firstWhere(
          (e) => e?.productId == item.productId,
      orElse: () => null,
    );

    if (existing != null) {
      state = state.map((e) {
        if (e.productId == item.productId) {
          return e.copyWith(
            quantity: e.quantity + item.quantity,
          );
        }
        return e;
      }).toList();

      return;
    }

    state = [...state, item];
  }

  // -------------------------
  // Increment / Decrement
  // -------------------------

  void updateQuantity(
      String itemId,
      int delta,
      ) {
    final updated = <CartItem>[];

    for (final item in state) {
      if (item.id == itemId) {
        final newQty = item.quantity + delta;

        if (newQty > 0) {
          updated.add(
            item.copyWith(
              quantity: newQty,
            ),
          );
        }
      } else {
        updated.add(item);
      }
    }

    state = updated;
  }

  // -------------------------
  // Set Exact Quantity
  // -------------------------

  void setQuantity(
      String itemId,
      int quantity,
      ) {
    if (quantity < 1) return;

    state = state.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          quantity: quantity,
        );
      }

      return item;
    }).toList();
  }

  // -------------------------
  // Remove
  // -------------------------

  void removeItem(String itemId) {
    state = state
        .where(
          (item) => item.id != itemId,
    )
        .toList();
  }

  // -------------------------
  // Clear Cart
  // -------------------------

  void clearCart() {
    state = [];
  }

  // -------------------------
  // Getters
  // -------------------------

  double get subtotal {
    return state.fold(
      0,
          (sum, item) =>
      sum +
          (item.unitPrice * item.quantity),
    );
  }

  int get totalItems {
    return state.fold(
      0,
          (sum, item) =>
      sum + item.quantity,
    );
  }

  int get totalUniqueProducts {
    return state.length;
  }

  bool get isEmpty {
    return state.isEmpty;
  }

  bool get isNotEmpty {
    return state.isNotEmpty;
  }

  Map<String, List<CartItem>>
  get groupedByStore {
    final grouped =
    <String, List<CartItem>>{};

    for (final item in state) {
      grouped.putIfAbsent(
        item.storeName,
            () => [],
      );

      grouped[item.storeName]!
          .add(item);
    }

    return grouped;
  }

  int get totalStores {
    return groupedByStore.length;
  }
}