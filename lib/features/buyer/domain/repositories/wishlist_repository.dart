import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:fpdart/fpdart.dart';

abstract class WishlistRepository {
  Stream<Either<String, List<CatalogItem>>> watchWishlist({
    required String userId,
  });

  Future<Either<String, void>> addToWishlist({
    required String userId,
    required CatalogItem item,
  });

  Future<Either<String, void>> removeFromWishlist({
    required String userId,
    required String productId,
  });

  Future<bool> isInWishlist({
    required String userId,
    required String productId,
  });
}
