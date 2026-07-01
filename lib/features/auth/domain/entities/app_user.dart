import 'package:fpdart/fpdart.dart';

import '../../../seller/domain/entities/store_profile.dart';

enum UserRole { guest, buyer, seller, storeManager, admin, superAdmin }

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final List<UserRole> roles;
  final VerificationStatus verificationStatus;
  final bool isActive;
  final String? fcmToken;
  final String? storeId;

  /// Becomes true after admin approves seller application
  final bool sellerApproved;

  /// Status of the seller application (none | pending | approved | rejected | changes_requested)
  final String sellerApplicationStatus;

  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phoneNumber,
    required this.roles,
    required this.verificationStatus,
    required this.isActive,
    this.fcmToken,
    this.storeId,
    this.sellerApproved = false,
    this.sellerApplicationStatus = 'none',
    required this.createdAt,
  });

  bool hasPermission(UserRole requiredRole) {
    if (roles.contains(UserRole.superAdmin)) return true;
    return roles.contains(requiredRole);
  }

  bool get isSellerApproved =>
      sellerApproved || roles.contains(UserRole.seller);

  bool get isGuest => roles.isEmpty || roles.contains(UserRole.guest);

  bool get hasPhoneNumber =>
      phoneNumber != null && phoneNumber!.trim().isNotEmpty;

  Either<String, bool> validateVerificationStatus() {
    if (!isActive) {
      return const Left("User account is suspended or unverified.");
    }
    return const Right(true);
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    List<UserRole>? roles,
    VerificationStatus? verificationStatus,
    bool? isActive,
    String? fcmToken,
    String? storeId,
    bool? sellerApproved,
    String? sellerApplicationStatus,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roles: roles ?? this.roles,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
      storeId: storeId ?? this.storeId,
      sellerApproved: sellerApproved ?? this.sellerApproved,
      sellerApplicationStatus:
          sellerApplicationStatus ?? this.sellerApplicationStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
