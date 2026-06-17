import '../entities/admin_user.dart';

abstract class AdminUserRepository {
  Stream<List<AdminUser>> watchUsers();

  Future<void> updateRoles({required String uid, required List<String> roles});

  Future<void> updateStatus({required String uid, required bool isActive});
}
