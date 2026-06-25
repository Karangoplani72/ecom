import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/domain/repositories/cart_repository.dart';
import 'package:fpdart/fpdart.dart';

class CartRepositoryImpl implements CartRepository {
  final FirebaseFirestore _firestore;

  CartRepositoryImpl({required this._firestore});

  @override
  Stream<Either<String, List<CartItem>>> watchCart({required String userId}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
          try {
            final items = snapshot.docs.map((doc) {
              final data = doc.data();
              return CartItem(
                id: doc.id,
                productId: data['productId'] ?? '',
                title: data['title'] ?? '',
                storeId: data['storeId'] ?? '',
                storeName: data['storeName'] ?? '',
                unitPrice: (data['unitPrice'] ?? 0).toDouble(),
                imageUrl: data['imageUrl'] ?? '',
                quantity: data['quantity'] ?? 1,
                skuId: data['skuId'] as String?,
                selectedCombination: (data['selectedCombination'] as Map?)?.map(
                  (k, v) => MapEntry(k.toString(), v.toString()),
                ),
              );
            }).toList();
            return Right(items);
          } catch (e) {
            return Left(e.toString());
          }
        });
  }

  @override
  Future<Either<String, void>> addCartItem({
    required String userId,
    required CartItem item,
  }) async {
    try {
      // Check if this exact item (same product + same variant) already
      // exists. `item.id` is variant-specific (a fresh doc id per SKU from
      // product_detail_screen, or the bare productId from quick-add flows
      // that don't support variants), so this correctly keeps different
      // SKUs of the same product as separate cart lines.
      final existing = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(item.id)
          .get();

      if (existing.exists) {
        // Item exists, increment quantity
        final currentQty = existing.data()?['quantity'] ?? 1;
        await existing.reference.update({
          'quantity': currentQty + item.quantity,
        });
      } else {
        // New item
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(item.id)
            .set({
              'productId': item.productId,
              'title': item.title,
              'storeId': item.storeId,
              'storeName': item.storeName,
              'unitPrice': item.unitPrice,
              'imageUrl': item.imageUrl,
              'quantity': item.quantity,
              if (item.skuId != null) 'skuId': item.skuId,
              if (item.selectedCombination != null)
                'selectedCombination': item.selectedCombination,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateCartItemQuantity({
    required String userId,
    required String itemId,
    required int quantity,
  }) async {
    try {
      if (quantity < 1) {
        return await removeCartItem(userId: userId, itemId: itemId);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(itemId)
          .update({'quantity': quantity});

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> removeCartItem({
    required String userId,
    required String itemId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(itemId)
          .delete();

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> clearCart({required String userId}) async {
    try {
      final batch = _firestore.batch();
      final docs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
