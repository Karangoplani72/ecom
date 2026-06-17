enum VerificationStatus { applied, underReview, verified, rejected, suspended }

class StoreProfile {
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
  final VerificationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StoreProfile({
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
    required this.createdAt,
    this.updatedAt,
  });

  bool get isVerified => status == VerificationStatus.verified;

  bool get isPending =>
      status == VerificationStatus.applied ||
      status == VerificationStatus.underReview;

  bool get isRejected => status == VerificationStatus.rejected;

  bool get isSuspended => status == VerificationStatus.suspended;

  StoreProfile copyWith({
    String? id,
    String? sellerId,
    String? storeName,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    String? category,
    VerificationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoreProfile(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      storeName: storeName ?? this.storeName,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
