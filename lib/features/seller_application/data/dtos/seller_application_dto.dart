import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/seller_application.dart';

class SellerApplicationDto {
  static const String collectionPath = 'sellerApplications';

  final String? applicationId;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String storeName;
  final String storeDescription;
  final String businessCategory;
  final String? gstNumber;
  final String? logoUrl;
  final List<String>? documents;
  final String status;
  final DateTime submittedAt;

  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? accountHolderName;

  const SellerApplicationDto({
    this.applicationId,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.storeName,
    required this.storeDescription,
    required this.businessCategory,
    this.gstNumber,
    this.logoUrl,
    this.documents,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.accountHolderName,
  });

  factory SellerApplicationDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return SellerApplicationDto(
      applicationId: doc.id,
      userId: data['userId'] as String? ?? data['sellerId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
      storeDescription: data['storeDescription'] as String? ?? data['description'] as String? ?? '',
      businessCategory: data['businessCategory'] as String? ?? '',
      gstNumber: data['gstNumber'] as String?,
      logoUrl: data['logoUrl'] as String?,
      documents: data['documents'] != null
          ? List<String>.from(data['documents'] as List)
          : null,
      status: data['status'] as String? ?? 'pending',
      submittedAt:
          (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      bankName: data['bankName'] as String?,
      accountNumber: data['accountNumber'] as String?,
      ifscCode: data['ifscCode'] as String?,
      accountHolderName: data['accountHolderName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'applicationId': applicationId ?? userId,
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'storeName': storeName,
      'storeDescription': storeDescription,
      'businessCategory': businessCategory,
      if (gstNumber != null && gstNumber!.isNotEmpty) 'gstNumber': gstNumber,
      if (logoUrl != null && logoUrl!.isNotEmpty) 'logoUrl': logoUrl,
      if (documents != null) 'documents': documents,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (bankName != null && bankName!.isNotEmpty) 'bankName': bankName,
      if (accountNumber != null && accountNumber!.isNotEmpty) 'accountNumber': accountNumber,
      if (ifscCode != null && ifscCode!.isNotEmpty) 'ifscCode': ifscCode,
      if (accountHolderName != null && accountHolderName!.isNotEmpty) 'accountHolderName': accountHolderName,
    };
  }

  factory SellerApplicationDto.fromDomain(SellerApplication application) {
    return SellerApplicationDto(
      applicationId: application.applicationId,
      userId: application.userId,
      fullName: application.fullName,
      phoneNumber: application.phoneNumber,
      storeName: application.storeName,
      storeDescription: application.storeDescription,
      businessCategory: application.businessCategory,
      gstNumber: application.gstNumber,
      logoUrl: application.logoUrl,
      documents: application.documents,
      status: application.status,
      submittedAt: application.submittedAt,
      reviewedAt: application.reviewedAt,
      reviewedBy: application.reviewedBy,
      rejectionReason: application.rejectionReason,
      bankName: application.bankName,
      accountNumber: application.accountNumber,
      ifscCode: application.ifscCode,
      accountHolderName: application.accountHolderName,
    );
  }

  SellerApplication toDomain() {
    return SellerApplication(
      applicationId: applicationId,
      userId: userId,
      fullName: fullName,
      phoneNumber: phoneNumber,
      storeName: storeName,
      storeDescription: storeDescription,
      businessCategory: businessCategory,
      gstNumber: gstNumber,
      logoUrl: logoUrl,
      documents: documents,
      status: status,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
      reviewedBy: reviewedBy,
      rejectionReason: rejectionReason,
      bankName: bankName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      accountHolderName: accountHolderName,
    );
  }
}
