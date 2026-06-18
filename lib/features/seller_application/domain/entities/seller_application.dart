class SellerApplication {
  final String? id;

  final String sellerId;
  final String fullName;
  final String phoneNumber;

  final String storeName;
  final String businessCategory;
  final String? gstNumber;

  final String description;

  /// pending | approved | rejected
  final String status;

  final DateTime submittedAt;

  /// Admin review metadata
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

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
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  bool get isPending => status == 'pending';

  bool get isApproved => status == 'approved';

  bool get isRejected => status == 'rejected';

  SellerApplication copyWith({
    String? id,
    String? sellerId,
    String? fullName,
    String? phoneNumber,
    String? storeName,
    String? businessCategory,
    String? gstNumber,
    String? description,
    String? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return SellerApplication(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      storeName: storeName ?? this.storeName,
      businessCategory: businessCategory ?? this.businessCategory,
      gstNumber: gstNumber ?? this.gstNumber,
      description: description ?? this.description,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
