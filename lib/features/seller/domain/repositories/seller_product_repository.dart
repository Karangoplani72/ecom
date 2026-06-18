import 'package:fpdart/fpdart.dart';

import '../entities/seller_product.dart';

abstract class SellerProductRepository {
  Stream<List<SellerProduct>> watchProducts({required String sellerId});

  Future<Either<Exception, SellerProduct>> getProductById({
    required String sellerId,
    required String productId,
  });

  Future<Either<Exception, Unit>> createProduct(SellerProduct product);

  Future<Either<Exception, Unit>> updateProduct(SellerProduct product);

  Future<Either<Exception, Unit>> deleteProduct({
    required String sellerId,
    required String productId,
  });

  Future<Either<Exception, Unit>> updateStock({
    required String sellerId,
    required String productId,
    required int stock,
  });

  Future<Either<Exception, Unit>> updateStatus({
    required String sellerId,
    required String productId,
    required String status,
  });

  Future<Either<Exception, List<SellerProduct>>> searchProducts({
    required String sellerId,
    required String query,
  });

  Future<Either<Exception, List<SellerProduct>>> getProductsByCategory({
    required String sellerId,
    required String category,
  });
}
