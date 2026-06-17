// lib/features/seller/domain/entities/seller_application.dart

class SellerApplication {
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

  const SellerApplication({
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
}
