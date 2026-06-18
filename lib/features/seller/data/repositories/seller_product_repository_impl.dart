import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/seller_product.dart';
import '../../domain/repositories/seller_product_repository.dart';
import '../dtos/seller_product_dto.dart';

class SellerProductRepositoryImpl implements SellerProductRepository {
  final FirebaseFirestore _firestore;
  static const String _catalogCollection = 'catalog';
  static const String _storesCollection = 'stores';
  static const String _productsSubcollection = 'products';

  SellerProductRepositoryImpl({required this._firestore});

  @override
  Future<Either<Exception, List<SellerProduct>>> getProductsByCategory({
    required String sellerId,
    required String category,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      if (category.isEmpty) {
        return Left(Exception('Invalid category: category cannot be empty'));
      }

      final snapshot = await _firestore
          .collection(_storesCollection)
          .doc(sellerId)
          .collection(_productsSubcollection)
          .where('metadata.category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      final products = snapshot.docs
          .map((doc) => SellerProductDto.fromFirestore(doc).toDomain())
          .toList();

      return Right(products);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get products by category: $e'));
    }
  }

  @override
  Future<Either<Exception, List<SellerProduct>>> searchProducts({
    required String sellerId,
    required String query,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      if (query.trim().isEmpty) {
        return const Right([]);
      }

      final snapshot = await _firestore
          .collection(_storesCollection)
          .doc(sellerId)
          .collection(_productsSubcollection)
          .get();

      final lowerQuery = query.toLowerCase();

      final products = snapshot.docs
          .map((doc) => SellerProductDto.fromFirestore(doc).toDomain())
          .where(
            (product) =>
                product.title.toLowerCase().contains(lowerQuery) ||
                product.description.toLowerCase().contains(lowerQuery),
          )
          .toList();

      return Right(products);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to search products: $e'));
    }
  }

  @override
  Stream<List<SellerProduct>> watchProducts({required String sellerId}) {
    try {
      if (sellerId.isEmpty) {
        return Stream.error(
          Exception('Invalid seller ID: seller ID cannot be empty'),
        );
      }

      return _firestore
          .collection(_storesCollection)
          .doc(sellerId)
          .collection(_productsSubcollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => SellerProductDto.fromFirestore(doc).toDomain())
                .toList(),
          )
          .handleError(
            (error) => throw Exception('Failed to watch products: $error'),
          );
    } catch (e) {
      return Stream.error(Exception('Watch products error: $e'));
    }
  }

  @override
  Future<Either<Exception, SellerProduct>> getProductById({
    required String sellerId,
    required String productId,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      if (productId.isEmpty) {
        return Left(
          Exception('Invalid product ID: product ID cannot be empty'),
        );
      }

      final doc = await _firestore
          .collection(_storesCollection)
          .doc(sellerId)
          .collection(_productsSubcollection)
          .doc(productId)
          .get();

      if (!doc.exists) {
        return Left(Exception('Product not found: $productId'));
      }

      final product = SellerProductDto.fromFirestore(doc).toDomain();
      return Right(product);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get product: $e'));
    }
  }

  @override
  Future<Either<Exception, Unit>> createProduct(SellerProduct product) async {
    try {
      _validateProduct(product);

      final data = _productToFirestore(product);

      final batch = _firestore.batch();

      batch.set(
        _firestore.collection(_catalogCollection).doc(product.id),
        data,
      );

      batch.set(
        _firestore
            .collection(_storesCollection)
            .doc(product.storeId)
            .collection(_productsSubcollection)
            .doc(product.id),
        data,
      );

      await batch.commit();
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error during create: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to create product: $e'));
    }
  }

  @override
  Future<Either<Exception, Unit>> updateProduct(SellerProduct product) async {
    try {
      _validateProduct(product);

      final data = _productToFirestore(product);

      final batch = _firestore.batch();

      batch.update(
        _firestore.collection(_catalogCollection).doc(product.id),
        data,
      );

      batch.update(
        _firestore
            .collection(_storesCollection)
            .doc(product.storeId)
            .collection(_productsSubcollection)
            .doc(product.id),
        data,
      );

      await batch.commit();
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error during update: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to update product: $e'));
    }
  }

  @override
  Future<Either<Exception, Unit>> deleteProduct({
    required String sellerId,
    required String productId,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      if (productId.isEmpty) {
        return Left(
          Exception('Invalid product ID: product ID cannot be empty'),
        );
      }

      final batch = _firestore.batch();

      batch.delete(_firestore.collection(_catalogCollection).doc(productId));

      batch.delete(
        _firestore
            .collection(_storesCollection)
            .doc(sellerId)
            .collection(_productsSubcollection)
            .doc(productId),
      );

      await batch.commit();
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error during delete: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to delete product: $e'));
    }
  }

  @override
  Future<Either<Exception, Unit>> updateStock({
    required String sellerId,
    required String productId,
    required int stock,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      if (productId.isEmpty) {
        return Left(
          Exception('Invalid product ID: product ID cannot be empty'),
        );
      }

      if (stock < 0) {
        return Left(Exception('Invalid stock: stock cannot be negative'));
      }

      final update = {
        'metadata.stock': stock,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final batch = _firestore.batch();

      batch.update(
        _firestore.collection(_catalogCollection).doc(productId),
        update,
      );

      batch.update(
        _firestore
            .collection(_storesCollection)
            .doc(sellerId)
            .collection(_productsSubcollection)
            .doc(productId),
        update,
      );

      await batch.commit();
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(
        Exception('Firestore error during stock update: ${e.message}'),
      );
    } catch (e) {
      return Left(Exception('Failed to update stock: $e'));
    }
  }

  @override
  Future<Either<Exception, Unit>> updateStatus({
    required String sellerId,
    required String productId,
    required String status,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      if (productId.isEmpty) {
        return Left(
          Exception('Invalid product ID: product ID cannot be empty'),
        );
      }

      if (status.isEmpty) {
        return Left(Exception('Invalid status: status cannot be empty'));
      }

      final validStatuses = {'active', 'inactive', 'archived', 'deleted'};
      if (!validStatuses.contains(status)) {
        return Left(
          Exception('Invalid status: $status is not a valid product status'),
        );
      }

      final update = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final batch = _firestore.batch();

      batch.update(
        _firestore.collection(_catalogCollection).doc(productId),
        update,
      );

      batch.update(
        _firestore
            .collection(_storesCollection)
            .doc(sellerId)
            .collection(_productsSubcollection)
            .doc(productId),
        update,
      );

      await batch.commit();
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(
        Exception('Firestore error during status update: ${e.message}'),
      );
    } catch (e) {
      return Left(Exception('Failed to update status: $e'));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Private helper methods
  // ─────────────────────────────────────────────────────────────

  void _validateProduct(SellerProduct product) {
    if (product.id.isEmpty) {
      throw ArgumentError('Product ID cannot be empty');
    }
    if (product.storeId.isEmpty) {
      throw ArgumentError('Store ID cannot be empty');
    }
    if (product.title.isEmpty) {
      throw ArgumentError('Product title cannot be empty');
    }
    if (product.basePrice < 0) {
      throw ArgumentError('Product price cannot be negative');
    }
    if (product.stock < 0) {
      throw ArgumentError('Product stock cannot be negative');
    }
  }

  Map<String, dynamic> _productToFirestore(SellerProduct product) {
    return {
      'id': product.id,
      'storeId': product.storeId,
      'title': product.title,
      'description': product.description,
      'type': product.type,
      'status': product.status,
      'basePrice': product.basePrice,
      'currency': product.currency,
      'imageUrls': product.imageUrls,
      'metadata': {'category': product.category, 'stock': product.stock},
      'createdAt': product.createdAt != null
          ? Timestamp.fromDate(product.createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
