import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/orders/domain/entities/order.dart';
import 'package:ecom/features/orders/domain/entities/order_item.dart';
import 'package:ecom/features/orders/domain/entities/order_status.dart';

class OrderItemDto {
  final String productId;
  final String title;
  final String imageUrl;
  final int quantity;
  final double unitPrice;

  const OrderItemDto({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItemDto.fromMap(Map<String, dynamic> map) {
    return OrderItemDto(
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  OrderItem toDomain() {
    return OrderItem(
      productId: productId,
      title: title,
      imageUrl: imageUrl,
      quantity: quantity,
      unitPrice: unitPrice,
    );
  }
}

class OrderDto {
  final String orderId;
  final String buyerId;
  final String buyerName;
  final String storeId;
  final String storeName;
  final String status;
  final List<OrderItemDto> items;
  final double subtotal;
  final double deliveryFee;
  final double platformFee;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveryAddress;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const OrderDto({
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.storeId,
    required this.storeName,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.platformFee,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return OrderDto(
      orderId: doc.id,
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      status: data['status'] ?? 'pending',
      items: List<Map<String, dynamic>>.from(
        data['items'] ?? [],
      ).map((item) => OrderItemDto.fromMap(item)).toList(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      platformFee: (data['platformFee'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'COD',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      deliveryAddress: data['deliveryAddress'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'storeId': storeId,
      'storeName': storeName,
      'status': status,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'platformFee': platformFee,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'deliveryAddress': deliveryAddress,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AppOrder toDomain() {
    return AppOrder(
      orderId: orderId,
      buyerId: buyerId,
      buyerName: buyerName,
      storeId: storeId,
      storeName: storeName,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => OrderStatus.pending,
      ),
      items: items.map((item) => item.toDomain()).toList(),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      platformFee: platformFee,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      deliveryAddress: deliveryAddress,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
    );
  }
}
