// lib/features/seller/data/dtos/seller_application_dto.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/seller_application.dart';

class SellerApplicationDto {
  final String? id;
  final String sellerId;
  final String fullName;
  final String phoneNumber;
  final String storeName;
  final String businessCategory;
  final String? gstNumber;
  final String description;
  final String status;
  final DateTime submittedAt;

  const SellerApplicationDto({
    this.id,
    required this.sellerId,
    required this.fullName,
    required this.phoneNumber,
    required this.storeName,
    required this.businessCategory,
    this.gstNumber,
    required this.description,
    required this.status,
    required this.submittedAt,
  });

  factory SellerApplicationDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return SellerApplicationDto(
      id: doc.id,
      sellerId: data['sellerId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
      businessCategory: data['businessCategory'] as String? ?? '',
      gstNumber: data['gstNumber'] as String?,
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      submittedAt:
          (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'storeName': storeName,
      'businessCategory': businessCategory,
      if (gstNumber != null && gstNumber!.isNotEmpty) 'gstNumber': gstNumber,
      'description': description,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }

  factory SellerApplicationDto.fromDomain(SellerApplication application) {
    return SellerApplicationDto(
      id: application.id,
      sellerId: application.sellerId,
      fullName: application.fullName,
      phoneNumber: application.phoneNumber,
      storeName: application.storeName,
      businessCategory: application.businessCategory,
      gstNumber: application.gstNumber,
      description: application.description,
      status: application.status,
      submittedAt: application.submittedAt,
    );
  }

  SellerApplication toDomain() {
    return SellerApplication(
      id: id,
      sellerId: sellerId,
      fullName: fullName,
      phoneNumber: phoneNumber,
      storeName: storeName,
      businessCategory: businessCategory,
      gstNumber: gstNumber,
      description: description,
      status: status,
      submittedAt: submittedAt,
    );
  }
}
