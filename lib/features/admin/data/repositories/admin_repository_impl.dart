import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/admin/data/dtos/admin_user_dto.dart';
import 'package:ecom/features/admin/data/dtos/dispute_ticket_dto.dart';
import 'package:ecom/features/admin/domain/entities/admin_dashboard_metrics.dart';
import 'package:ecom/features/admin/domain/entities/admin_user.dart';
import 'package:ecom/features/admin/domain/entities/audit_log.dart';
import 'package:ecom/features/admin/domain/entities/dispute_ticket.dart';
import 'package:ecom/features/admin/domain/entities/platform_config.dart';
import 'package:ecom/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecom/features/seller/domain/entities/store_profile.dart';
import 'package:ecom/features/seller_application/domain/entities/seller_application.dart';
import 'package:fpdart/fpdart.dart';

import '../../../seller/data/dtos/store_profile_dto.dart';
import '../../../seller_application/data/dtos/seller_application_dto.dart';

class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepositoryImpl({required this._firestore});

  // ─── Dashboard ─────────────────────────────────────────────────────────────
  @override
  Future<AdminDashboardMetrics> fetchDashboardMetrics() async {
    try {
      final results = await Future.wait([
        _firestore.collection('users').count().get(),
        _firestore
            .collection('users')
            .where('roles', arrayContains: 'buyer')
            .count()
            .get(),
        _firestore
            .collection('users')
            .where('roles', arrayContains: 'seller')
            .count()
            .get(),
        _firestore
            .collection('sellerApplications')
            .where('status', isEqualTo: 'pending')
            .count()
            .get(),
        _firestore
            .collection('sellerApplications')
            .where('status', isEqualTo: 'approved')
            .count()
            .get(),
        _firestore
            .collection('sellerApplications')
            .where('status', isEqualTo: 'rejected')
            .count()
            .get(),
        _firestore.collection('catalog').count().get(),
        _firestore
            .collection('catalog')
            .where('isActive', isEqualTo: true)
            .count()
            .get(),
        _firestore
            .collection('catalog')
            .where('isActive', isEqualTo: false)
            .count()
            .get(),
        _firestore
            .collection('catalog')
            .where('stockQuantity', isEqualTo: 0)
            .count()
            .get(),
        _firestore.collection('orders').count().get(),
        _firestore
            .collection('orders')
            .where('status', isEqualTo: 'pending')
            .count()
            .get(),
        _firestore
            .collection('orders')
            .where('status', isEqualTo: 'processing')
            .count()
            .get(),
        _firestore
            .collection('orders')
            .where('status', isEqualTo: 'shipped')
            .count()
            .get(),
        _firestore
            .collection('orders')
            .where('status', isEqualTo: 'delivered')
            .count()
            .get(),
        _firestore
            .collection('orders')
            .where('status', isEqualTo: 'cancelled')
            .count()
            .get(),
        _firestore.collection('chats').count().get(),
        _firestore.collection('disputes').count().get(),
        _firestore
            .collection('disputes')
            .where('status', isEqualTo: 'open')
            .count()
            .get(),
      ]);

      final totalUsers = results[0].count ?? 0;
      final totalBuyers = results[1].count ?? 0;
      final totalSellers = results[2].count ?? 0;
      final pendingApplications = results[3].count ?? 0;
      final approvedSellers = results[4].count ?? 0;
      final rejectedSellers = results[5].count ?? 0;
      final totalProducts = results[6].count ?? 0;
      final activeProducts = results[7].count ?? 0;
      final inactiveProducts = results[8].count ?? 0;
      final outOfStockProducts = results[9].count ?? 0;
      final totalOrders = results[10].count ?? 0;
      final pendingOrders = results[11].count ?? 0;
      final processingOrders = results[12].count ?? 0;
      final shippedOrders = results[13].count ?? 0;
      final deliveredOrders = results[14].count ?? 0;
      final cancelledOrders = results[15].count ?? 0;
      final totalChats = results[16].count ?? 0;
      final totalDisputes = results[17].count ?? 0;
      final openDisputes = results[18].count ?? 0;

      // Revenue — sum from orders where status == delivered
      double totalRevenue = 0;
      double platformRevenue = 0;

      double commissionRate = 0.085;
      final configDoc = await _firestore
          .collection('platform_settings')
          .doc('global_config')
          .get();
      if (configDoc.exists) {
        final configData = configDoc.data();
        commissionRate =
            (configData?['defaultCommissionRate'] as num?)?.toDouble() ?? 0.085;
      }

      final revenueSnapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
          .get();

      for (final doc in revenueSnapshot.docs) {
        final data = doc.data();
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        totalRevenue += amount;
        platformRevenue += amount * commissionRate;
      }

      return AdminDashboardMetrics(
        totalUsers: totalUsers,
        totalBuyers: totalBuyers,
        totalSellers: totalSellers,
        pendingApplications: pendingApplications,
        approvedSellers: approvedSellers,
        rejectedSellers: rejectedSellers,
        totalProducts: totalProducts,
        activeProducts: activeProducts,
        inactiveProducts: inactiveProducts,
        outOfStockProducts: outOfStockProducts,
        totalOrders: totalOrders,
        pendingOrders: pendingOrders,
        processingOrders: processingOrders,
        shippedOrders: shippedOrders,
        deliveredOrders: deliveredOrders,
        cancelledOrders: cancelledOrders,
        totalRevenue: totalRevenue,
        platformRevenue: platformRevenue,
        totalChats: totalChats,
        totalDisputes: totalDisputes,
        openDisputes: openDisputes,
      );
    } catch (_) {
      return const AdminDashboardMetrics();
    }
  }

  // ─── Disputes ──────────────────────────────────────────────────────────────
  @override
  Stream<List<DisputeTicket>> watchAllDisputes() {
    return _firestore
        .collection('disputes')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => DisputeTicketDto.fromFirestore(d).toDomain())
              .toList(),
        );
  }

  @override
  Future<Either<String, List<DisputeTicket>>> fetchActiveDisputes({
    required int limit,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('disputes')
          .where('status', isNotEqualTo: TicketStatus.resolved.name)
          .orderBy('status')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final tickets = snapshot.docs
          .map((doc) => DisputeTicketDto.fromFirestore(doc).toDomain())
          .toList();
      return Right(tickets);
    } catch (e) {
      return Left('Failed to load disputes: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Unit>> updateTicketStatus(
    String ticketId,
    TicketStatus nextStatus,
  ) async {
    try {
      await _firestore.collection('disputes').doc(ticketId).update({
        'status': nextStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left('Failed to update ticket: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Unit>> assignTicket(
    String ticketId,
    String agentId,
  ) async {
    try {
      await _firestore.collection('disputes').doc(ticketId).update({
        'assignedAgentId': agentId,
        'status': TicketStatus.underInvestigation.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left('Failed to assign ticket: ${e.toString()}');
    }
  }

  // ─── Platform Config ───────────────────────────────────────────────────────
  @override
  Future<Either<String, PlatformConfig>>
  fetchSystemGlobalConfigurations() async {
    try {
      final doc = await _firestore
          .collection('platform_settings')
          .doc('global_config')
          .get();
      if (!doc.exists) {
        return const Right(
          PlatformConfig(
            defaultCommissionRate: 0.085,
            categoryCommissionOverrides: {},
            maintenanceModeActive: false,
            globalRateLimitPerMinute: 600,
            razorpayKey: 'rzp_test_placeholder_key',
          ),
        );
      }
      final data = doc.data()!;
      return Right(
        PlatformConfig(
          defaultCommissionRate:
              (data['defaultCommissionRate'] as num?)?.toDouble() ?? 0.085,
          categoryCommissionOverrides: Map<String, double>.from(
            (data['categoryOverrides'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, (v as num).toDouble()),
                ) ??
                {},
          ),
          maintenanceModeActive:
              data['maintenanceModeActive'] as bool? ?? false,
          globalRateLimitPerMinute:
              data['globalRateLimitPerMinute'] as int? ?? 600,
          razorpayKey: 'managed_via_functions',
        ),
      );
    } catch (e) {
      return Left('Failed to load config: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Unit>> patchCommissionStructure(
    String categoryKey,
    double explicitRate,
  ) async {
    try {
      await _firestore.collection('platform_settings').doc('global_config').set(
        {'categoryOverrides.$categoryKey': explicitRate},
        SetOptions(merge: true),
      );
      return const Right(unit);
    } catch (e) {
      return Left('Failed to patch commission: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Unit>> savePlatformConfig(PlatformConfig config) async {
    try {
      await _firestore
          .collection('platform_settings')
          .doc('global_config')
          .set({
            'defaultCommissionRate': config.defaultCommissionRate,
            'categoryOverrides': config.categoryCommissionOverrides,
            'maintenanceModeActive': config.maintenanceModeActive,
            'globalRateLimitPerMinute': config.globalRateLimitPerMinute,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      return const Right(unit);
    } catch (e) {
      return Left('Failed to save config: ${e.toString()}');
    }
  }

  // ─── Seller Applications ───────────────────────────────────────────────────
  @override
  Stream<List<SellerApplication>> watchPendingSellerApplications() {
    return _firestore
        .collection(SellerApplicationDto.collectionPath)
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => SellerApplicationDto.fromFirestore(d).toDomain())
              .toList(),
        );
  }

  @override
  Future<Either<String, List<SellerApplication>>>
  fetchPendingSellerApplications() async {
    try {
      final snapshot = await _firestore
          .collection(SellerApplicationDto.collectionPath)
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .get();

      final applications = snapshot.docs
          .map((doc) => SellerApplicationDto.fromFirestore(doc).toDomain())
          .toList();

      return Right(applications);
    } catch (e) {
      return Left('Failed to load applications: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Unit>> approveSellerApplication(
    String applicationId,
    String adminId,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final applicationRef = _firestore
            .collection(SellerApplicationDto.collectionPath)
            .doc(applicationId);

        final applicationDoc = await transaction.get(applicationRef);

        if (!applicationDoc.exists) {
          throw Exception('Application not found');
        }

        final application = SellerApplicationDto.fromFirestore(
          applicationDoc,
        ).toDomain();

        final userRef = _firestore.collection('users').doc(application.userId);
        final storeRef = _firestore
            .collection('stores')
            .doc(application.userId);

        final storeDoc = await transaction.get(storeRef);
        final userDoc = await transaction.get(userRef);
        final userEmail = userDoc.data()?['email'] as String?;

        transaction.update(applicationRef, {
          'status': 'approved',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': adminId,
        });

        transaction.update(userRef, {
          'sellerApproved': true,
          'sellerApplicationStatus': 'approved',
          'roles': FieldValue.arrayUnion(['seller']),
        });

        final storeSlug = application.storeName
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
            .replaceAll(RegExp(r'\s+'), '-');

        // Set up bankAccount record automatically on approval
        final bankAccountRef = _firestore
            .collection('bankAccounts')
            .doc(application.userId);
        transaction.set(bankAccountRef, {
          'id': application.userId,
          'storeId': application.userId,
          'bankName': application.bankName ?? '',
          'accountNumber': application.accountNumber ?? '',
          'ifscCode': application.ifscCode ?? '',
          'accountHolderName': application.accountHolderName ?? '',
          'isVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!storeDoc.exists) {
          transaction.set(storeRef, {
            'storeId': application.userId,
            'sellerId': application.userId,
            'storeName': application.storeName,
            'storeSlug': storeSlug,
            'storeDescription': application.storeDescription,
            'description': application.storeDescription,
            'logoUrl': null,
            'bannerUrl': null,
            'businessCategory': application.businessCategory,
            'category': application.businessCategory,
            'rating': 0.0,
            'totalReviews': 0,
            'totalProducts': 0,
            'totalOrders': 0,
            'isVerified': true,
            'isActive': true,
            'phone': application.phoneNumber,
            'email': userEmail,
            'gstNumber': application.gstNumber ?? '',
            'address': '',
            'status': 'verified',
            'bankName': application.bankName ?? '',
            'accountNumber': application.accountNumber ?? '',
            'ifscCode': application.ifscCode ?? '',
            'accountHolderName': application.accountHolderName ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(storeRef, {
            'storeName': application.storeName,
            'storeSlug': storeSlug,
            'storeDescription': application.storeDescription,
            'description': application.storeDescription,
            'businessCategory': application.businessCategory,
            'category': application.businessCategory,
            'gstNumber': application.gstNumber ?? '',
            'status': 'verified',
            'isVerified': true,
            'isActive': true,
            'bankName': application.bankName ?? '',
            'accountNumber': application.accountNumber ?? '',
            'ifscCode': application.ifscCode ?? '',
            'accountHolderName': application.accountHolderName ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return const Right(unit);
    } catch (e) {
      return Left('Approval failed: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Unit>> rejectSellerApplication(
    String applicationId,
    String adminId,
    String reason,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final applicationRef = _firestore
            .collection(SellerApplicationDto.collectionPath)
            .doc(applicationId);

        final applicationDoc = await transaction.get(applicationRef);
        if (!applicationDoc.exists) throw Exception('Application not found');

        final application = SellerApplicationDto.fromFirestore(
          applicationDoc,
        ).toDomain();
        final userRef = _firestore.collection('users').doc(application.userId);

        transaction.update(applicationRef, {
          'status': 'rejected',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': adminId,
          'rejectionReason': reason,
        });

        transaction.update(userRef, {'sellerApplicationStatus': 'rejected'});
      });

      return const Right(unit);
    } catch (e) {
      return Left('Rejection failed: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Unit>> requestChangesOnSellerApplication(
    String applicationId,
    String adminId,
    String feedback,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final applicationRef = _firestore
            .collection(SellerApplicationDto.collectionPath)
            .doc(applicationId);

        final applicationDoc = await transaction.get(applicationRef);
        if (!applicationDoc.exists) throw Exception('Application not found');

        final application = SellerApplicationDto.fromFirestore(
          applicationDoc,
        ).toDomain();
        final userRef = _firestore.collection('users').doc(application.userId);

        transaction.update(applicationRef, {
          'status': 'changes_requested',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': adminId,
          'rejectionReason': feedback,
        });

        transaction.update(userRef, {
          'sellerApplicationStatus': 'changes_requested',
        });
      });

      return const Right(unit);
    } catch (e) {
      return Left('Request changes failed: ${e.toString()}');
    }
  }

  // ─── Stores ─────────────────────────────────────────────────────────────────
  @override
  Stream<List<StoreProfile>> watchAllStores() {
    return _firestore
        .collection('stores')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => StoreProfileDto.fromFirestore(d).toDomain())
              .toList(),
        );
  }

  @override
  Future<Either<String, Unit>> suspendStore(String storeId) async {
    try {
      final batch = _firestore.batch();

      final storeRef = _firestore.collection('stores').doc(storeId);
      batch.update(storeRef, {
        'isActive': false,
        'status': 'suspended',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return const Right(unit);
    } catch (e) {
      return Left('Failed to suspend store: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Unit>> activateStore(String storeId) async {
    try {
      await _firestore.collection('stores').doc(storeId).update({
        'isActive': true,
        'status': 'verified',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left('Failed to activate store: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Unit>> deleteStore(String storeId) async {
    try {
      final batch = _firestore.batch();

      // Mark all seller's products inactive
      final productsSnapshot = await _firestore
          .collection('catalog')
          .where('sellerId', isEqualTo: storeId)
          .get();

      for (final doc in productsSnapshot.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }

      // Remove seller role from user
      final userRef = _firestore.collection('users').doc(storeId);
      batch.update(userRef, {
        'roles': FieldValue.arrayRemove(['seller']),
        'sellerApproved': false,
        'sellerApplicationStatus': 'none',
      });

      // Delete the store
      final storeRef = _firestore.collection('stores').doc(storeId);
      batch.delete(storeRef);

      await batch.commit();
      return const Right(unit);
    } catch (e) {
      return Left('Failed to delete store: ${e.toString()}');
    }
  }

  // ─── Users ─────────────────────────────────────────────────────────────────
  @override
  Stream<List<AdminUser>> watchAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => AdminUserDto.fromFirestore(d).toDomain())
              .toList(),
        );
  }

  @override
  Future<Either<String, Unit>> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      return const Right(unit);
    } catch (e) {
      return Left('Failed to delete user: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Unit>> updateUserRoles(
    String uid,
    List<String> roles,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).update({'roles': roles});
      return const Right(unit);
    } catch (e) {
      return Left('Failed to update roles: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Unit>> setUserActiveStatus(
    String uid,
    bool isActive,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': isActive,
      });
      return const Right(unit);
    } catch (e) {
      return Left('Failed to update user status: ${e.toString()}');
    }
  }

  // ─── Audit Logs ────────────────────────────────────────────────────────────
  @override
  Stream<List<AuditLog>> watchAuditLogs() {
    return _firestore
        .collection('audit_logs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => AuditLog.fromJson(d.data(), d.id)).toList(),
        );
  }

  @override
  Future<Either<String, Unit>> createAuditLog(AuditLog log) async {
    try {
      await _firestore.collection('audit_logs').doc(log.id).set(log.toJson());
      return const Right(unit);
    } catch (e) {
      return Left('Failed to create audit log: ${e.toString()}');
    }
  }
}
