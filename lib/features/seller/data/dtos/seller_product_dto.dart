import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/seller_product.dart';

class SellerProductDto {
  final String id;
  final String storeId;
  final String title;
  final String description;
  final String type;
  final String status;
  final double basePrice;
  final String currency;
  final List<String> imageUrls;
  final Map<String, dynamic> metadata;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const SellerProductDto({
    required this.id,
    required this.storeId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.basePrice,
    required this.currency,
    required this.imageUrls,
    required this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerProductDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return SellerProductDto(
      id: data['id'] ?? '',
      storeId: data['storeId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'product',
      status: data['status'] ?? 'active',
      basePrice: (data['basePrice'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'INR',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  SellerProduct toDomain() {
    return SellerProduct(
      id: id,
      storeId: storeId,
      title: title,
      description: description,
      type: type,
      status: status,
      basePrice: basePrice,
      currency: currency,
      imageUrls: imageUrls,
      category: metadata['category'] ?? '',
      stock: metadata['stock'] ?? 0,
      createdAt: createdAt?.toDate(),
      updatedAt: updatedAt?.toDate(),
    );
  }
}
