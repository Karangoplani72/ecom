import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/admin_user.dart';

class AdminUserDto {
  final String uid;
  final String email;
  final String phoneNumber;
  final List<String> roles;
  final bool isActive;

  const AdminUserDto({
    required this.uid,
    required this.email,
    required this.phoneNumber,
    required this.roles,
    required this.isActive,
  });

  factory AdminUserDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return AdminUserDto(
      uid: doc.id,
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      roles: List<String>.from(data['roles'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }

  AdminUser toDomain() {
    return AdminUser(
      uid: uid,
      email: email,
      phoneNumber: phoneNumber,
      roles: roles
          .map(
            (e) => UserRole.values.firstWhere(
              (r) => r.name == e,
              orElse: () => UserRole.buyer,
            ),
          )
          .toList(),
      isActive: isActive,
    );
  }
}
