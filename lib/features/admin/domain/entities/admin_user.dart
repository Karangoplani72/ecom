import '../../../auth/domain/entities/app_user.dart';

class AdminUser {
  final String uid;
  final String email;
  final String phoneNumber;
  final List<UserRole> roles;
  final bool isActive;

  const AdminUser({
    required this.uid,
    required this.email,
    required this.phoneNumber,
    required this.roles,
    required this.isActive,
  });

  bool get isSeller => roles.contains(UserRole.seller);

  bool get isAdmin => roles.contains(UserRole.admin);

  bool get isStoreManager => roles.contains(UserRole.storeManager);
}
