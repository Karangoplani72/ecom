import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/store_profile.dart';

class StoreProfileDto {
  final String id;
  final String sellerId;
  final String storeName;
  final String description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final String? category;
  final String status;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const StoreProfileDto({
    required this.id,
    required this.sellerId,
    required this.storeName,
    required this.description,
    this.logoUrl,
    this.bannerUrl,
    this.phone,
    this.email,
    this.address,
    this.gstNumber,
    this.category,
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
      sellerId: data['sellerId'] ?? '',
      storeName: data['storeName'] ?? '',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'],
      bannerUrl: data['bannerUrl'],
      phone: data['phone'],
      email: data['email'],
      address: data['address'],
      gstNumber: data['gstNumber'],
      category: data['category'],
      status: data['status'] ?? 'applied',
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  StoreProfile toDomain() {
    return StoreProfile(
      id: id,
      sellerId: sellerId,
      storeName: storeName,
      description: description,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      phone: phone,
      email: email,
      address: address,
      gstNumber: gstNumber,
      category: category,
      status: VerificationStatus.values.byName(status),
      createdAt: createdAt?.toDate() ?? DateTime.now(),
      updatedAt: updatedAt?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'storeName': storeName,
      'description': description,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'phone': phone,
      'email': email,
      'address': address,
      'gstNumber': gstNumber,
      'category': category,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
