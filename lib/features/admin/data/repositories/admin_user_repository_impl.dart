import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_user_repository.dart';
import '../dtos/admin_user_dto.dart';

class AdminUserRepositoryImpl implements AdminUserRepository {
  final FirebaseFirestore firestore;

  AdminUserRepositoryImpl({required this.firestore});

  @override
  Stream<List<AdminUser>> watchUsers() {
    return firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((e) => AdminUserDto.fromFirestore(e).toDomain())
              .toList(),
        );
  }

  @override
  Future<void> updateRoles({
    required String uid,
    required List<String> roles,
  }) async {
    await firestore.collection('users').doc(uid).update({'roles': roles});
  }

  @override
  Future<void> updateStatus({
    required String uid,
    required bool isActive,
  }) async {
    await firestore.collection('users').doc(uid).update({'isActive': isActive});
  }
}
