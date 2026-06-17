import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/admin_user_repository_impl.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_user_repository.dart';

part 'admin_user_controller.g.dart';

@riverpod
AdminUserRepository adminUserRepository(Ref ref) {
  return AdminUserRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
Stream<List<AdminUser>> adminUsers(Ref ref) {
  return ref.watch(adminUserRepositoryProvider).watchUsers();
}

@riverpod
class AdminUserController extends _$AdminUserController {
  @override
  FutureOr<void> build() {}

  Future<void> updateRoles({
    required String uid,
    required List<String> roles,
  }) async {
    await ref
        .read(adminUserRepositoryProvider)
        .updateRoles(uid: uid, roles: roles);
  }

  Future<void> toggleUserStatus({
    required String uid,
    required bool isActive,
  }) async {
    await ref
        .read(adminUserRepositoryProvider)
        .updateStatus(uid: uid, isActive: isActive);
  }
}
