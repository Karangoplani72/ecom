import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/seller_product.dart';
import '../../domain/repositories/seller_product_repository.dart';
import '../dtos/seller_product_dto.dart';

class SellerProductRepositoryImpl implements SellerProductRepository {
  final FirebaseFirestore firestore;

  SellerProductRepositoryImpl({required this.firestore});

  @override
  Stream<List<SellerProduct>> watchProducts({required String sellerId}) {
    return firestore
        .collection('stores')
        .doc(sellerId)
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SellerProductDto.fromFirestore(doc).toDomain())
              .toList(),
        );
  }

  @override
  Future<SellerProduct?> getProductById({
    required String sellerId,
    required String productId,
  }) async {
    final doc = await firestore
        .collection('stores')
        .doc(sellerId)
        .collection('products')
        .doc(productId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return SellerProductDto.fromFirestore(doc).toDomain();
  }

  @override
  Future<void> createProduct(SellerProduct product) async {
    final data = {
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
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = firestore.batch();

    batch.set(firestore.collection('catalog').doc(product.id), data);

    batch.set(
      firestore
          .collection('stores')
          .doc(product.storeId)
          .collection('products')
          .doc(product.id),
      data,
    );

    await batch.commit();
  }

  @override
  Future<void> updateProduct(SellerProduct product) async {
    final data = {
      'title': product.title,
      'description': product.description,
      'status': product.status,
      'basePrice': product.basePrice,
      'currency': product.currency,
      'imageUrls': product.imageUrls,
      'metadata': {'category': product.category, 'stock': product.stock},
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = firestore.batch();

    batch.update(firestore.collection('catalog').doc(product.id), data);

    batch.update(
      firestore
          .collection('stores')
          .doc(product.storeId)
          .collection('products')
          .doc(product.id),
      data,
    );

    await batch.commit();
  }

  @override
  Future<void> deleteProduct({
    required String sellerId,
    required String productId,
  }) async {
    final batch = firestore.batch();

    batch.delete(firestore.collection('catalog').doc(productId));

    batch.delete(
      firestore
          .collection('stores')
          .doc(sellerId)
          .collection('products')
          .doc(productId),
    );

    await batch.commit();
  }

  @override
  Future<void> updateStock({
    required String sellerId,
    required String productId,
    required int stock,
  }) async {
    final update = {
      'metadata.stock': stock,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = firestore.batch();

    batch.update(firestore.collection('catalog').doc(productId), update);

    batch.update(
      firestore
          .collection('stores')
          .doc(sellerId)
          .collection('products')
          .doc(productId),
      update,
    );

    await batch.commit();
  }

  @override
  Future<void> updateStatus({
    required String sellerId,
    required String productId,
    required String status,
  }) async {
    final update = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = firestore.batch();

    batch.update(firestore.collection('catalog').doc(productId), update);

    batch.update(
      firestore
          .collection('stores')
          .doc(sellerId)
          .collection('products')
          .doc(productId),
      update,
    );

    await batch.commit();
  }
}
