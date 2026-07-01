import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/seller/domain/entities/staff_permission.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'staff_permission_provider.g.dart';

/// Provides the current user's [StaffPermissions] as a real-time stream.
///
/// - Sellers (store owners) always get [StaffPermissions.all()].
/// - Store managers get permissions read from Firestore in real-time,
///   so any changes by the seller are reflected instantly.
@riverpod
Stream<StaffPermissions> staffPermissions(Ref ref) {
  final userAsync = ref.watch(currentUserProfileProvider);
  final user = userAsync.value;

  if (user == null) {
    return Stream.value(StaffPermissions.none());
  }

  // Sellers (store owners) get all permissions
  if (user.roles.contains(UserRole.seller)) {
    return Stream.value(StaffPermissions.all());
  }

  // Admins / superAdmins get all permissions
  if (user.roles.contains(UserRole.admin) ||
      user.roles.contains(UserRole.superAdmin)) {
    return Stream.value(StaffPermissions.all());
  }

  // Store managers get permissions from their staff document
  if (user.roles.contains(UserRole.storeManager) && user.storeId != null) {
    final firestore = ref.watch(firebaseFirestoreProvider);
    return firestore
        .collection('stores')
        .doc(user.storeId)
        .collection('staff')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return StaffPermissions.all(); // Fallback for old staff
      final data = doc.data();
      if (data == null || !data.containsKey('permissions')) {
        // Legacy staff without permissions field → give all
        return StaffPermissions.all();
      }
      final permList = data['permissions'] as List<dynamic>? ?? [];
      if (permList.isEmpty) {
        // Empty permissions list → give at least dashboard
        return StaffPermissions.fromList(['dashboard']);
      }
      return StaffPermissions.fromList(permList);
    });
  }

  // Buyers / guests get no permissions
  return Stream.value(StaffPermissions.none());
}
