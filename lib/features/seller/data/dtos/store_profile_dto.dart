import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/store_profile.dart';

class StoreProfileDto {
  final String id;
  final String sellerId;
  final String storeName;
  final String storeSlug;
  final String description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final String? category;
  final double rating;
  final int totalReviews;
  final int totalProducts;
  final int totalOrders;
  final bool isVerified;
  final bool isActive;
  final String status;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const StoreProfileDto({
    required this.id,
    required this.sellerId,
    required this.storeName,
    required this.storeSlug,
    required this.description,
    this.logoUrl,
    this.bannerUrl,
    this.phone,
    this.email,
    this.address,
    this.gstNumber,
    this.category,
    required this.rating,
    required this.totalReviews,
    required this.totalProducts,
    required this.totalOrders,
    required this.isVerified,
    required this.isActive,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory StoreProfileDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return StoreProfileDto(
      id: doc.id,
      sellerId: data['sellerId'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
      storeSlug: data['storeSlug'] as String? ?? '',
      description: data['storeDescription'] as String? ?? data['description'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      bannerUrl: data['bannerUrl'] as String?,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      address: data['address'] as String?,
      gstNumber: data['gstNumber'] as String?,
      category: data['businessCategory'] as String? ?? data['category'] as String?,
      rating: (data['rating'] as num? ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] as int? ?? 0,
      totalProducts: data['totalProducts'] as int? ?? 0,
      totalOrders: data['totalOrders'] as int? ?? 0,
      isVerified: data['isVerified'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      status: data['status'] as String? ?? 'pending',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  StoreProfile toDomain() {
    return StoreProfile(
      id: id,
      sellerId: sellerId,
      storeName: storeName,
      storeSlug: storeSlug,
      description: description,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      phone: phone,
      email: email,
      address: address,
      gstNumber: gstNumber,
      category: category,
      rating: rating,
      totalReviews: totalReviews,
      totalProducts: totalProducts,
      totalOrders: totalOrders,
      isVerified: isVerified,
      isActive: isActive,
      status: VerificationStatus.fromString(status),
      createdAt: createdAt?.toDate() ?? DateTime.now(),
      updatedAt: updatedAt?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': id,
      'sellerId': sellerId,
      'storeName': storeName,
      'storeSlug': storeSlug,
      'storeDescription': description,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'phone': phone,
      'email': email,
      'address': address,
      'gstNumber': gstNumber,
      'businessCategory': category,
      'category': category,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalProducts': totalProducts,
      'totalOrders': totalOrders,
      'isVerified': isVerified,
      'isActive': isActive,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  StoreProfileDto copyWith({
    String? id,
    String? sellerId,
    String? storeName,
    String? storeSlug,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    String? category,
    double? rating,
    int? totalReviews,
    int? totalProducts,
    int? totalOrders,
    bool? isVerified,
    bool? isActive,
    String? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return StoreProfileDto(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      storeName: storeName ?? this.storeName,
      storeSlug: storeSlug ?? this.storeSlug,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalProducts: totalProducts ?? this.totalProducts,
      totalOrders: totalOrders ?? this.totalOrders,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'StoreProfileDto(id: $id, storeName: $storeName, status: $status)';
  }
}
