import 'package:flutter/foundation.dart';

enum VerificationStatus {
  pending('pending'),
  applied('applied'),
  underReview('underReview'),
  verified('verified'),
  rejected('rejected'),
  suspended('suspended');

  final String value;

  const VerificationStatus(this.value);

  static VerificationStatus fromString(String? value) {
    return values.firstWhere(
      (status) => status.value == value,
      orElse: () => VerificationStatus.pending,
    );
  }
}

@immutable
class StoreProfile {
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
  final VerificationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StoreProfile({
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
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if store is pending approval
  bool get isPending =>
      status == VerificationStatus.applied ||
      status == VerificationStatus.underReview;

  /// Check if store verification was rejected
  bool get isRejected => status == VerificationStatus.rejected;

  /// Check if store is suspended
  bool get isSuspended => status == VerificationStatus.suspended;

  /// Check if store profile is complete for verification
  bool get isProfileComplete =>
      storeName.isNotEmpty &&
      description.isNotEmpty &&
      phone != null &&
      phone!.isNotEmpty &&
      email != null &&
      email!.isNotEmpty &&
      address != null &&
      address!.isNotEmpty &&
      category != null &&
      category!.isNotEmpty &&
      logoUrl != null &&
      logoUrl!.isNotEmpty;

  /// Check if store can be verified (complete and not rejected/suspended)
  bool get canBeVerified => isProfileComplete && !isRejected && !isSuspended;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sellerId == other.sellerId &&
          storeName == other.storeName &&
          storeSlug == other.storeSlug &&
          description == other.description &&
          logoUrl == other.logoUrl &&
          bannerUrl == other.bannerUrl &&
          phone == other.phone &&
          email == other.email &&
          address == other.address &&
          gstNumber == other.gstNumber &&
          category == other.category &&
          rating == other.rating &&
          totalReviews == other.totalReviews &&
          totalProducts == other.totalProducts &&
          totalOrders == other.totalOrders &&
          isVerified == other.isVerified &&
          isActive == other.isActive &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      sellerId.hashCode ^
      storeName.hashCode ^
      storeSlug.hashCode ^
      description.hashCode ^
      logoUrl.hashCode ^
      bannerUrl.hashCode ^
      phone.hashCode ^
      email.hashCode ^
      address.hashCode ^
      gstNumber.hashCode ^
      category.hashCode ^
      rating.hashCode ^
      totalReviews.hashCode ^
      totalProducts.hashCode ^
      totalOrders.hashCode ^
      isVerified.hashCode ^
      isActive.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  StoreProfile copyWith({
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
    VerificationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoreProfile(
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
    return 'StoreProfile(id: $id, storeName: $storeName, '
        'status: ${status.value}, isVerified: $isVerified)';
  }
}
