import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/auth/data/dtos/user_dto.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';
import 'package:ecom/features/seller/domain/entities/staff_permission.dart';
import 'package:ecom/features/seller/presentation/controllers/seller_controller.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'seller_staff_controller.g.dart';

class StaffInvitation {
  final String id;
  final String email;
  final String role;
  final String storeName;
  final String storeId;
  final String invitedBy;
  final String status;
  final DateTime createdAt;

  const StaffInvitation({
    required this.id,
    required this.email,
    required this.role,
    required this.storeName,
    required this.storeId,
    required this.invitedBy,
    required this.status,
    required this.createdAt,
  });

  factory StaffInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['createdAt'];
    final date = ts is Timestamp ? ts.toDate() : DateTime.now();
    return StaffInvitation(
      id: doc.id,
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'storeManager',
      storeName: data['storeName'] as String? ?? '',
      storeId: data['storeId'] as String? ?? '',
      invitedBy: data['invitedBy'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: date,
    );
  }
}

class SellerStaffState {
  final List<AppUser> activeStaff;
  final List<StaffInvitation> pendingInvitations;

  const SellerStaffState({
    required this.activeStaff,
    required this.pendingInvitations,
  });
}

@riverpod
class SellerStaffController extends _$SellerStaffController {
  @override
  Stream<SellerStaffState> build() {
    final store = ref.watch(sellerControllerProvider).value;
    if (store == null) {
      return Stream.value(const SellerStaffState(activeStaff: [], pendingInvitations: []));
    }

    final firestore = ref.watch(firebaseFirestoreProvider);

    // Watch active staff members in users collection where storeId == store.id
    final staffStream = firestore
        .collection('users')
        .where('storeId', isEqualTo: store.id)
        .snapshots()
        .map((s) => s.docs.map((d) => UserDto.fromFirestore(d).toDomain()).toList());

    // Watch pending invitations for this store
    final invitesStream = firestore
        .collection('store_invitations')
        .where('storeId', isEqualTo: store.id)
        .snapshots()
        .map((s) => s.docs.map((d) => StaffInvitation.fromFirestore(d)).toList());

    // Combine streams
    return staffStream.asyncMap((staff) async {
      final invites = await invitesStream.first;
      return SellerStaffState(activeStaff: staff, pendingInvitations: invites);
    });
  }

  /// Invite a staff member by email
  Future<Either<String, Unit>> inviteStaff(String email, String role, [StaffPermissions? customPermissions]) async {
    final store = ref.read(sellerControllerProvider).value;
    if (store == null) return const Left('Store not loaded');

    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return const Left('Email cannot be empty');

    final firestore = ref.read(firebaseFirestoreProvider);

    try {
      // 1. Check if user already exists
      final userQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final doc = userQuery.docs.first;
        final rolesList = List<String>.from(doc.data()['roles'] ?? []);

        // Update existing user with storeId and role
        if (!rolesList.contains('storeManager')) {
          rolesList.add('storeManager');
        }

        await firestore.collection('users').doc(doc.id).update({
          'storeId': store.id,
          'roles': rolesList,
        });

        final finalPerms = customPermissions ?? StaffPermissions.defaultForRole(role);

        // Add to store's staff subcollection with default or custom permissions
        await firestore
            .collection('stores')
            .doc(store.id)
            .collection('staff')
            .doc(doc.id)
            .set({
          'email': cleanEmail,
          'displayName': doc.data()['displayName'] ?? 'Staff Member',
          'role': role,
          'permissions': finalPerms.toList(),
          'joinedAt': FieldValue.serverTimestamp(),
        });

        return const Right(unit);
      }

      // 2. If user doesn't exist, create an invitation
      final inviteId = cleanEmail; // Unique ID based on email to prevent duplicates

      // Resolve the inviter's display name
      final currentUser = ref.read(firebaseAuthProvider).currentUser;
      final inviterName = currentUser?.displayName ?? currentUser?.email ?? 'Store Owner';
      
      final finalPerms = customPermissions ?? StaffPermissions.defaultForRole(role);

      await firestore.collection('store_invitations').doc(inviteId).set({
        'email': cleanEmail,
        'storeId': store.id,
        'storeName': store.storeName,
        'role': role,
        'permissions': finalPerms.toList(),
        'invitedBy': inviterName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return const Right(unit);
    } catch (e) {
      return Left('Failed to invite staff: ${e.toString()}');
    }
  }

  /// Remove an active staff member
  Future<Either<String, Unit>> removeStaff(String userId) async {
    final store = ref.read(sellerControllerProvider).value;
    if (store == null) return const Left('Store not loaded');

    final firestore = ref.read(firebaseFirestoreProvider);

    try {
      // Fetch current user roles to strip storeManager
      final doc = await firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final rolesList = List<String>.from(doc.data()?['roles'] ?? []);
        rolesList.remove('storeManager');

        await firestore.collection('users').doc(userId).update({
          'storeId': null,
          'roles': rolesList,
        });
      }

      // Delete from store staff subcollection
      await firestore
          .collection('stores')
          .doc(store.id)
          .collection('staff')
          .doc(userId)
          .delete();

      return const Right(unit);
    } catch (e) {
      return Left('Failed to remove staff: ${e.toString()}');
    }
  }

  /// Revoke a pending invitation
  Future<Either<String, Unit>> revokeInvitation(String inviteId) async {
    final firestore = ref.read(firebaseFirestoreProvider);

    try {
      await firestore.collection('store_invitations').doc(inviteId).delete();
      return const Right(unit);
    } catch (e) {
      return Left('Failed to revoke invitation: ${e.toString()}');
    }
  }

  /// Update permissions for a staff member
  Future<Either<String, Unit>> updateStaffPermissions(
    String userId,
    StaffPermissions permissions,
  ) async {
    final store = ref.read(sellerControllerProvider).value;
    if (store == null) return const Left('Store not loaded');

    final firestore = ref.read(firebaseFirestoreProvider);

    try {
      await firestore
          .collection('stores')
          .doc(store.id)
          .collection('staff')
          .doc(userId)
          .update({'permissions': permissions.toList()});
      return const Right(unit);
    } catch (e) {
      return Left('Failed to update permissions: ${e.toString()}');
    }
  }
}
