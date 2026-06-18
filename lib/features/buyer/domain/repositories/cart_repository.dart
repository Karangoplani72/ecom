import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:fpdart/fpdart.dart';

abstract class CartRepository {
  Stream<Either<String, List<CartItem>>> watchCart({required String userId});

  Future<Either<String, void>> addCartItem({
    required String userId,
    required CartItem item,
  });

  Future<Either<String, void>> updateCartItemQuantity({
    required String userId,
    required String itemId,
    required int quantity,
  });

  Future<Either<String, void>> removeCartItem({
    required String userId,
    required String itemId,
  });

  Future<Either<String, void>> clearCart({required String userId});
}
