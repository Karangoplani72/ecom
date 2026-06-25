import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/seller_product.dart';
import '../../domain/repositories/seller_product_repository.dart';
import '../dtos/seller_product_dto.dart';

class SellerProductRepositoryImpl implements SellerProductRepository {
  final FirebaseFirestore _firestore;
  static const _catalog = 'catalog';
  static const _stores = 'stores';
  static const _products = 'products';

  SellerProductRepositoryImpl(this._firestore);

  // ─── watch ────────────────────────────────────────────────────────────────

  @override
  Stream<List<SellerProduct>> watchProducts({required String sellerId}) {
    if (sellerId.isEmpty) {
      return Stream.error(Exception('sellerId cannot be empty'));
    }
    return _firestore
        .collection(_stores)
        .doc(sellerId)
        .collection(_products)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => SellerProductDto.fromFirestore(d).toDomain())
              .toList(),
        )
        .handleError((e) => throw Exception('Watch products failed: $e'));
  }

  // ─── get by id ────────────────────────────────────────────────────────────

  @override
  Future<Either<Exception, SellerProduct>> getProductById({
    required String sellerId,
    required String productId,
  }) async {
    try {
      final doc = await _firestore
          .collection(_stores)
          .doc(sellerId)
          .collection(_products)
          .doc(productId)
          .get();
      if (!doc.exists) return Left(Exception('Product not found: $productId'));
      return Right(SellerProductDto.fromFirestore(doc).toDomain());
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore: ${e.message}'));
    } catch (e) {
      return Left(Exception('getProductById: $e'));
    }
  }

  // ─── create ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Exception, Unit>> createProduct(SellerProduct product) async {
    try {
      _validate(product);
      final data = SellerProductDto.domainToFirestore(product)
        ..['createdAt'] = FieldValue.serverTimestamp();
      final batch = _firestore.batch();
      batch.set(_firestore.collection(_catalog).doc(product.id), data);
      batch.set(
        _firestore
            .collection(_stores)
            .doc(product.storeId)
            .collection(_products)
            .doc(product.id),
        data,
      );
      await batch.commit();
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore create: ${e.message}'));
    } catch (e) {
      return Left(Exception('createProduct: $e'));
    }
  }

  // ─── update ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Exception, Unit>> updateProduct(SellerProduct product) async {
    try {
      _validate(product);
      final data = SellerProductDto.domainToFirestore(product);
      final batch = _firestore.batch();
      batch.update(_firestore.collection(_catalog).doc(product.id), data);
      batch.set(
        _firestore
            .collection(_stores)
            .doc(product.storeId)
            .collection(_products)
            .doc(product.id),
        data,
        SetOptions(merge: true),
      );
      await batch.commit();
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore update: ${e.message}'));
    } catch (e) {
      return Left(Exception('updateProduct: $e'));
    }
  }

  // ─── delete ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Exception, Unit>> deleteProduct({
    required String sellerId,
    required String productId,
  }) async {
    try {
      final batch = _firestore.batch();
      batch.delete(_firestore.collection(_catalog).doc(productId));
      batch.delete(
        _firestore
            .collection(_stores)
            .doc(sellerId)
            .collection(_products)
            .doc(productId),
      );
      await batch.commit();
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore delete: ${e.message}'));
    } catch (e) {
      return Left(Exception('deleteProduct: $e'));
    }
  }

  // ─── update stock ─────────────────────────────────────────────────────────

  @override
  Future<Either<Exception, Unit>> updateStock({
    required String sellerId,
    required String productId,
    required int stock,
  }) async {
    try {
      if (stock < 0) return Left(Exception('Stock cannot be negative'));
      final upd = {
        'metadata.stock': stock,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final batch = _firestore.batch();
      batch.update(_firestore.collection(_catalog).doc(productId), upd);
      batch.update(
        _firestore
            .collection(_stores)
            .doc(sellerId)
            .collection(_products)
            .doc(productId),
        upd,
      );
      await batch.commit();
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore updateStock: ${e.message}'));
    } catch (e) {
      return Left(Exception('updateStock: $e'));
    }
  }

  // ─── update status ────────────────────────────────────────────────────────

  @override
  Future<Either<Exception, Unit>> updateStatus({
    required String sellerId,
    required String productId,
    required String status,
  }) async {
    try {
      const validStatuses = {'active', 'inactive', 'archived', 'draft'};
      if (!validStatuses.contains(status)) {
        return Left(Exception('Invalid status: $status'));
      }
      final upd = {
        'status': status,
        'isActive': status == 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final batch = _firestore.batch();
      batch.update(_firestore.collection(_catalog).doc(productId), upd);
      batch.update(
        _firestore
            .collection(_stores)
            .doc(sellerId)
            .collection(_products)
            .doc(productId),
        upd,
      );
      await batch.commit();
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore updateStatus: ${e.message}'));
    } catch (e) {
      return Left(Exception('updateStatus: $e'));
    }
  }

  // ─── search ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Exception, List<SellerProduct>>> searchProducts({
    required String sellerId,
    required String query,
  }) async {
    try {
      if (query.trim().isEmpty) return const Right([]);
      final snap = await _firestore
          .collection(_stores)
          .doc(sellerId)
          .collection(_products)
          .get();
      final lower = query.toLowerCase();
      final results = snap.docs
          .map((d) => SellerProductDto.fromFirestore(d).toDomain())
          .where(
            (p) =>
                p.title.toLowerCase().contains(lower) ||
                p.description.toLowerCase().contains(lower) ||
                p.category.toLowerCase().contains(lower),
          )
          .toList();
      return Right(results);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore search: ${e.message}'));
    } catch (e) {
      return Left(Exception('searchProducts: $e'));
    }
  }

  // ─── get by category ──────────────────────────────────────────────────────

  @override
  Future<Either<Exception, List<SellerProduct>>> getProductsByCategory({
    required String sellerId,
    required String category,
  }) async {
    try {
      final snap = await _firestore
          .collection(_stores)
          .doc(sellerId)
          .collection(_products)
          .where('metadata.category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();
      return Right(
        snap.docs
            .map((d) => SellerProductDto.fromFirestore(d).toDomain())
            .toList(),
      );
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore getByCategory: ${e.message}'));
    } catch (e) {
      return Left(Exception('getProductsByCategory: $e'));
    }
  }

  // ─── helpers ──────────────────────────────────────────────────────────────

  void _validate(SellerProduct p) {
    if (p.id.isEmpty) throw ArgumentError('Product ID cannot be empty');
    if (p.storeId.isEmpty) throw ArgumentError('Store ID cannot be empty');
    if (p.title.isEmpty) throw ArgumentError('Title cannot be empty');
    if (p.basePrice < 0) throw ArgumentError('Price cannot be negative');
  }
}
