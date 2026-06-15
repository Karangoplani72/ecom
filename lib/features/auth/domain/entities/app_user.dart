import 'package:fpdart/fpdart.dart';

enum UserRole { guest, buyer, seller, storeManager, admin, superAdmin }

class AppUser {
  final String uid;
  final String email;
  final String phoneNumber;
  final List<UserRole> roles;
  final String? activeStoreId;
  final bool isActive;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.phoneNumber,
    required this.roles,
    this.activeStoreId,
    required this.isActive,
    required this.createdAt,
  });

  bool hasPermission(UserRole requiredRole) {
    if (roles.contains(UserRole.superAdmin)) return true;
    return roles.contains(requiredRole);
  }

  Either<String, bool> validateVerificationStatus() {
    if (!isActive) return const Left("User account is suspended or unverified.");
    return const Right(true);
  }
}