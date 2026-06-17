import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/seller_order.dart';

class SellerOrderDto {
  final String id;
  final String buyerId;
  final String buyerName;
  final String storeId;
  final String status;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String deliveryAddress;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const SellerOrderDto({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.storeId,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerOrderDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return SellerOrderDto(
      id: doc.id,
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      storeId: data['storeId'] ?? '',
      status: data['status'] ?? 'pending',
      items: List<Map<String, dynamic>>.from(
        (data['items'] ?? []).map((e) => Map<String, dynamic>.from(e)),
      ),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      deliveryAddress: data['deliveryAddress'] ?? '',
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  SellerOrder toDomain() {
    return SellerOrder(
      id: id,
      buyerId: buyerId,
      buyerName: buyerName,
      storeId: storeId,
      status: status,
      totalAmount: totalAmount,
      deliveryAddress: deliveryAddress,
      createdAt: createdAt?.toDate(),
      updatedAt: updatedAt?.toDate(),
      items: items.map((item) {
        return SellerOrderItem(
          productId: item['productId'] ?? '',
          title: item['title'] ?? '',
          quantity: item['quantity'] ?? 0,
          unitPrice: (item['unitPrice'] ?? 0).toDouble(),
        );
      }).toList(),
    );
  }
}
