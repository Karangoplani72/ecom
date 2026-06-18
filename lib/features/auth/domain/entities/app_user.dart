import 'package:fpdart/fpdart.dart';

import '../../../seller/domain/entities/store_profile.dart';

enum UserRole { guest, buyer, seller, storeManager, admin, superAdmin }

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<UserRole> roles;
  final VerificationStatus verificationStatus;
  final bool isActive;

  /// Becomes true after admin approves seller application
  final bool sellerApproved;

  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.roles,
    required this.verificationStatus,
    required this.isActive,
    this.sellerApproved = false,
    required this.createdAt,
  });

  bool hasPermission(UserRole requiredRole) {
    if (roles.contains(UserRole.superAdmin)) return true;
    return roles.contains(requiredRole);
  }

  bool get isSellerApproved =>
      sellerApproved || roles.contains(UserRole.seller);

  Either<String, bool> validateVerificationStatus() {
    if (!isActive) {
      return const Left("User account is suspended or unverified.");
    }

    return const Right(true);
  }
}
