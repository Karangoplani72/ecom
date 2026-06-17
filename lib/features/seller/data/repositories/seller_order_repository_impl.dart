import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/seller_order.dart';
import '../../domain/repositories/seller_order_repository.dart';
import '../dtos/seller_order_dto.dart';

class SellerOrderRepositoryImpl implements SellerOrderRepository {
  final FirebaseFirestore firestore;

  SellerOrderRepositoryImpl({required this.firestore});

  @override
  Stream<List<SellerOrder>> watchOrders({required String sellerId}) {
    return firestore
        .collection('orders')
        .where('storeId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SellerOrderDto.fromFirestore(doc).toDomain())
              .toList(),
        );
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
