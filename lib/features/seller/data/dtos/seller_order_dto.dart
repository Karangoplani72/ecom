import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/seller_order.dart';

class SellerOrderItemDto {
  final String productId;
  final String title;
  final int quantity;
  final double unitPrice;

  const SellerOrderItemDto({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
  });

  factory SellerOrderItemDto.fromMap(Map<String, dynamic> data) {
    return SellerOrderItemDto(
      productId: data['productId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      quantity: data['quantity'] as int? ?? 0,
      unitPrice: (data['unitPrice'] as num? ?? 0).toDouble(),
    );
  }

  SellerOrderItem toDomain() {
    return SellerOrderItem(
      productId: productId,
      title: title,
      quantity: quantity,
      unitPrice: unitPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

class SellerOrderDto {
  final String id;
  final String buyerId;
  final String buyerName;
  final String storeId;
  final String status;
  final List<SellerOrderItemDto> items;
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

    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map(
          (item) => SellerOrderItemDto.fromMap(
            item is Map<String, dynamic> ? item : <String, dynamic>{},
          ),
        )
        .toList();

    return SellerOrderDto(
      id: doc.id,
      buyerId: data['buyerId'] as String? ?? '',
      buyerName: data['buyerName'] as String? ?? '',
      storeId: data['storeId'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      items: itemsList,
      totalAmount: (data['totalAmount'] as num? ?? 0).toDouble(),
      deliveryAddress: data['deliveryAddress'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  SellerOrder toDomain() {
    return SellerOrder(
      id: id,
      buyerId: buyerId,
      buyerName: buyerName,
      storeId: storeId,
      status: status,
      items: items.map((item) => item.toDomain()).toList(),
      totalAmount: totalAmount,
      deliveryAddress: deliveryAddress,
      createdAt: createdAt?.toDate(),
      updatedAt: updatedAt?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'storeId': storeId,
      'status': status,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
