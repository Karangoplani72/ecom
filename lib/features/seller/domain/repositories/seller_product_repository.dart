import '../entities/seller_product.dart';

abstract class SellerProductRepository {
  Stream<List<SellerProduct>> watchProducts({required String sellerId});

  Future<SellerProduct?> getProductById({
    required String sellerId,
    required String productId,
  });

  Future<void> createProduct(SellerProduct product);

  Future<void> updateProduct(SellerProduct product);

  Future<void> deleteProduct({
    required String sellerId,
    required String productId,
  });

  Future<void> updateStock({
    required String sellerId,
    required String productId,
    required int stock,
  });

  Future<void> updateStatus({
    required String sellerId,
    required String productId,
    required String status,
  });
}
