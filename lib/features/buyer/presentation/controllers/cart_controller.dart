import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/buyer/data/repositories/cart_repository_impl.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/domain/repositories/cart_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cart_controller.g.dart';

@riverpod
CartRepository cartRepository(Ref ref) {
  return CartRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
Stream<List<CartItem>> cartStream(Ref ref) {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    return Stream.value(<CartItem>[]);
  }

  final repo = ref.watch(cartRepositoryProvider);

  return repo
      .watchCart(userId: currentUser.uid)
      .map((either) => either.fold((_) => <CartItem>[], (items) => items));
}

@riverpod
class CartController extends _$CartController {
  @override
  List<CartItem> build() {
    final cartAsync = ref.watch(cartStreamProvider);
    return cartAsync.value ?? <CartItem>[];
  }

  // ==================================================
  // ADD ITEM
  // ==================================================

  Future<void> addItem(CartItem item) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final repo = ref.read(cartRepositoryProvider);

    final result = await repo.addCartItem(userId: currentUser.uid, item: item);

    // FIX: propagate Firestore write errors instead of silently swallowing them.
    // ProductDetailScreen already wraps addItem() in try/catch and shows an error
    // snackbar, so throwing here is the correct and complete fix.
    result.fold((error) => throw Exception(error), (_) {});
  }

  // ==================================================
  // UPDATE QUANTITY
  // ==================================================

  Future<void> updateQuantity(String itemId, int delta) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    CartItem? item;

    for (final cartItem in state) {
      if (cartItem.id == itemId) {
        item = cartItem;
        break;
      }
    }

    if (item == null) return;

    final newQuantity = item.quantity + delta;

    if (newQuantity < 1) {
      await removeItem(itemId);
      return;
    }

    final repo = ref.read(cartRepositoryProvider);

    await repo.updateCartItemQuantity(
      userId: currentUser.uid,
      itemId: itemId,
      quantity: newQuantity,
    );
  }

  // ==================================================
  // SET QUANTITY
  // ==================================================

  Future<void> setQuantity(String itemId, int quantity) async {
    if (quantity < 1) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final repo = ref.read(cartRepositoryProvider);

    await repo.updateCartItemQuantity(
      userId: currentUser.uid,
      itemId: itemId,
      quantity: quantity,
    );
  }

  // ==================================================
  // REMOVE ITEM
  // ==================================================

  Future<void> removeItem(String itemId) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final repo = ref.read(cartRepositoryProvider);

    await repo.removeCartItem(userId: currentUser.uid, itemId: itemId);
  }

  // ==================================================
  // CLEAR CART
  // ==================================================

  Future<void> clearCart() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final repo = ref.read(cartRepositoryProvider);

    await repo.clearCart(userId: currentUser.uid);
  }

  // ==================================================
  // GETTERS
  // ==================================================

  double get subtotal {
    return state.fold(
      0.0,
      (total, item) => total + (item.unitPrice * item.quantity),
    );
  }

  int get totalItems {
    return state.fold(0, (total, item) => total + item.quantity);
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

  Map<String, List<CartItem>> get groupedByStore {
    final grouped = <String, List<CartItem>>{};

    for (final item in state) {
      grouped.putIfAbsent(item.storeId, () => <CartItem>[]);
      grouped[item.storeId]!.add(item);
    }

    return grouped;
  }

  int get totalStores {
    return groupedByStore.length;
  }
}
