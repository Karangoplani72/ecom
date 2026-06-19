class SellerApplication {
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

  /// pending | approved | rejected | changes_requested
  final String status;

  final DateTime submittedAt;

  /// Admin review metadata
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  const SellerApplication({
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
  });

  bool get isPending => status == 'pending';

  bool get isApproved => status == 'approved';

  bool get isRejected => status == 'rejected';

  bool get isChangesRequested => status == 'changes_requested';

  SellerApplication copyWith({
    String? applicationId,
    String? userId,
    String? fullName,
    String? phoneNumber,
    String? storeName,
    String? storeDescription,
    String? businessCategory,
    String? gstNumber,
    String? logoUrl,
    List<String>? documents,
    String? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return SellerApplication(
      applicationId: applicationId ?? this.applicationId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      storeName: storeName ?? this.storeName,
      storeDescription: storeDescription ?? this.storeDescription,
      businessCategory: businessCategory ?? this.businessCategory,
      gstNumber: gstNumber ?? this.gstNumber,
      logoUrl: logoUrl ?? this.logoUrl,
      documents: documents ?? this.documents,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
