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
  final String? skuId;
  final Map<String, String>? selectedCombination;

  const OrderItemDto({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    this.skuId,
    this.selectedCombination,
  });

  factory OrderItemDto.fromMap(Map<String, dynamic> map) {
    return OrderItemDto(
      productId: map['productId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      skuId: map['skuId'] as String?,
      selectedCombination: (map['selectedCombination'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'unitPrice': unitPrice,
      if (skuId != null) 'skuId': skuId,
      if (selectedCombination != null)
        'selectedCombination': selectedCombination,
    };
  }

  OrderItem toDomain() {
    return OrderItem(
      productId: productId,
      title: title,
      imageUrl: imageUrl,
      quantity: quantity,
      unitPrice: unitPrice,
      skuId: skuId,
      selectedCombination: selectedCombination,
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
  final String? paymentId;
  final String? razorpayOrderId;
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
    this.paymentId,
    this.razorpayOrderId,
    required this.deliveryAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return OrderDto(
      orderId: doc.id,
      buyerId: data['buyerId'] as String? ?? '',
      buyerName: data['buyerName'] as String? ?? '',
      storeId: data['storeId'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      items: List<Map<String, dynamic>>.from(
        data['items'] as List? ?? [],
      ).map((item) => OrderItemDto.fromMap(item)).toList(),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      platformFee: (data['platformFee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] as String? ?? 'COD',
      paymentStatus: data['paymentStatus'] as String? ?? 'pending',
      paymentId: data['paymentId'] as String?,
      razorpayOrderId: data['razorpayOrderId'] as String?,
      deliveryAddress: data['deliveryAddress'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
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
      if (paymentId != null) 'paymentId': paymentId,
      if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
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
      paymentId: paymentId,
      razorpayOrderId: razorpayOrderId,
      deliveryAddress: deliveryAddress,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
    );
  }
}
