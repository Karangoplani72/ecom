import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:ecom/features/admin/domain/entities/admin_dashboard_metrics.dart';
import 'package:ecom/features/admin/domain/entities/admin_user.dart';
import 'package:ecom/features/admin/domain/entities/dispute_ticket.dart';
import 'package:ecom/features/admin/domain/entities/platform_config.dart';
import 'package:ecom/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecom/features/seller/domain/entities/store_profile.dart';
import 'package:ecom/features/seller_application/domain/entities/seller_application.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';
import 'package:ecom/features/admin/domain/entities/audit_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'admin_controller.g.dart';

@riverpod
AdminRepository adminRepository(Ref ref) {
  return AdminRepositoryImpl(firestore: ref.watch(firebaseFirestoreProvider));
}

// ─── Dashboard metrics ───────────────────────────────────────────────────────
@riverpod
Stream<AdminDashboardMetrics> adminDashboardMetrics(Ref ref) {
  final repo = ref.watch(adminRepositoryProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  return firestore.collection('audit_logs').snapshots().asyncMap((_) async {
    return repo.fetchDashboardMetrics();
  });
}

// ─── Seller Applications ─────────────────────────────────────────────────────
@riverpod
Stream<List<SellerApplication>> pendingSellerApplications(Ref ref) {
  return ref.watch(adminRepositoryProvider).watchPendingSellerApplications();
}

@riverpod
Stream<int> pendingEarlyReleaseRequestsCount(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return firestore
      .collection('escrows')
      .where('status', isEqualTo: 'release_requested')
      .snapshots()
      .map((snap) => snap.docs.length);
}

// ─── Stores (all) ────────────────────────────────────────────────────────────
@riverpod
Stream<List<StoreProfile>> adminAllStores(Ref ref) {
  return ref.watch(adminRepositoryProvider).watchAllStores();
}

// ─── Users (all) ─────────────────────────────────────────────────────────────
@riverpod
Stream<List<AdminUser>> adminAllUsers(Ref ref) {
  return ref.watch(adminRepositoryProvider).watchAllUsers();
}

// ─── Disputes (all) ──────────────────────────────────────────────────────────
@riverpod
Stream<List<DisputeTicket>> adminAllDisputes(Ref ref) {
  return ref.watch(adminRepositoryProvider).watchAllDisputes();
}

// ─── Audit Logs ──────────────────────────────────────────────────────────────
@riverpod
Stream<List<AuditLog>> adminAuditLogs(Ref ref) {
  return ref.watch(adminRepositoryProvider).watchAuditLogs();
}

// ─── Admin controller — dispute + application + store actions ────────────────
@riverpod
class AdminController extends _$AdminController {
  @override
  FutureOr<void> build() {
    ref.keepAlive();
  }

  Future<Either<String, Unit>> _auditActionHelper({
    required AdminRepository repo,
    required AppUser user,
    required String action,
    required String targetId,
    required String targetType,
    Map<String, dynamic>? metadata,
  }) async {
    final log = AuditLog(
      id: const Uuid().v4(),
      action: action,
      userId: user.uid,
      userEmail: user.email,
      targetId: targetId,
      targetType: targetType,
      metadata: metadata ?? {},
      createdAt: DateTime.now(),
    );

    return repo.createAuditLog(log);
  }

  // ── Dispute actions ──────────────────────────────────────────────────────
  Future<Either<String, Unit>> resolveTicket(String ticketId) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.updateTicketStatus(ticketId, TicketStatus.resolved);
    
    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'resolve_ticket',
        targetId: ticketId,
        targetType: 'dispute_ticket',
      );
    }
    return result;
  }

  Future<Either<String, Unit>> assignTicket(
    String ticketId,
    String agentId,
  ) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.assignTicket(ticketId, agentId);
    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'assign_ticket',
        targetId: ticketId,
        targetType: 'dispute_ticket',
        metadata: {'agentId': agentId},
      );
    }
    return result;
  }

  // ── Seller application actions ───────────────────────────────────────────
  Future<Either<String, Unit>> approveSellerApplication(
    String applicationId,
    String adminId,
  ) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.approveSellerApplication(applicationId, adminId);

    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'approve_seller_application',
        targetId: applicationId,
        targetType: 'seller_application',
      );
    }

    if (ref.mounted) {
      ref.invalidate(adminDashboardMetricsProvider);
    }
    return result;
  }

  Future<Either<String, Unit>> rejectSellerApplication(
    String applicationId,
    String adminId,
    String reason,
  ) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.rejectSellerApplication(applicationId, adminId, reason);

    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'reject_seller_application',
        targetId: applicationId,
        targetType: 'seller_application',
        metadata: {'reason': reason},
      );
    }

    if (ref.mounted) {
      ref.invalidate(adminDashboardMetricsProvider);
    }
    return result;
  }

  Future<Either<String, Unit>> requestChangesOnSellerApplication(
    String applicationId,
    String adminId,
    String feedback,
  ) async {
    final repo = ref.read(adminRepositoryProvider);
    return repo.requestChangesOnSellerApplication(applicationId, adminId, feedback);
  }

  // ── Store actions ────────────────────────────────────────────────────────
  Future<Either<String, Unit>> suspendStore(String storeId) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.suspendStore(storeId);
    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'suspend_store',
        targetId: storeId,
        targetType: 'store',
      );
    }
    if (ref.mounted) {
      ref.invalidate(adminDashboardMetricsProvider);
    }
    return result;
  }

  Future<Either<String, Unit>> activateStore(String storeId) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.activateStore(storeId);
    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'activate_store',
        targetId: storeId,
        targetType: 'store',
      );
    }
    if (ref.mounted) {
      ref.invalidate(adminDashboardMetricsProvider);
    }
    return result;
  }

  Future<Either<String, Unit>> deleteStore(String storeId) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.deleteStore(storeId);
    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'delete_store',
        targetId: storeId,
        targetType: 'store',
      );
    }
    if (ref.mounted) {
      ref.invalidate(adminDashboardMetricsProvider);
    }
    return result;
  }

  // ── User actions ─────────────────────────────────────────────────────────
  Future<Either<String, Unit>> deleteUser(String uid) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.deleteUser(uid);
    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'delete_user',
        targetId: uid,
        targetType: 'user',
      );
    }
    return result;
  }

  Future<Either<String, Unit>> updateUserRoles(
    String uid,
    List<String> roles,
  ) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.updateUserRoles(uid, roles);
    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'update_user_roles',
        targetId: uid,
        targetType: 'user',
        metadata: {'roles': roles},
      );
    }
    return result;
  }

  Future<Either<String, Unit>> setUserActiveStatus(
    String uid,
    bool isActive,
  ) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.setUserActiveStatus(uid, isActive);
    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'set_user_active_status',
        targetId: uid,
        targetType: 'user',
        metadata: {'isActive': isActive},
      );
    }
    return result;
  }

  // ── Order actions ────────────────────────────────────────────────────────
  Future<Either<String, Unit>> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? trackingNumber,
  }) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.updateOrderStatus(
      orderId,
      newStatus,
      trackingNumber: trackingNumber,
    );
    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'update_order_status',
        targetId: orderId,
        targetType: 'order',
        metadata: {
          'newStatus': newStatus,
          'trackingNumber': trackingNumber,
        },
      );
    }
    return result;
  }

  Future<Either<String, Unit>> processRefund({
    required String orderId,
    required String reason,
    required String reasonCategory,
    required double refundAmount,
  }) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return left('Not authenticated');

    final result = await repo.processRefund(
      orderId: orderId,
      adminId: user.uid,
      reason: reason,
      reasonCategory: reasonCategory,
      refundAmount: refundAmount,
    );

    if (result.isRight()) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'order.refund',
        targetId: orderId,
        targetType: 'order',
        metadata: {
          'reason': reason,
          'reasonCategory': reasonCategory,
          'refundAmount': refundAmount,
        },
      );
    }
    return result;
  }

  // ── Settlement actions ───────────────────────────────────────────────────
  Future<Either<String, Unit>> processSettlement(String settlementId) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.processSettlement(settlementId);
    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'process_settlement',
        targetId: settlementId,
        targetType: 'settlement',
      );
    }
    return result;
  }

  Future<Either<String, Unit>> rejectSettlement(
    String settlementId,
    String reason,
  ) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.rejectSettlement(settlementId, reason);
    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'reject_settlement',
        targetId: settlementId,
        targetType: 'settlement',
        metadata: {'reason': reason},
      );
    }
    return result;
  }

  Future<Either<String, Unit>> completeSettlement(String settlementId) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.completeSettlement(settlementId);
    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'complete_settlement',
        targetId: settlementId,
        targetType: 'settlement',
      );
    }
    return result;
  }

  // ── Ticket: reject ───────────────────────────────────────────────────────
  Future<Either<String, Unit>> rejectTicket(
    String ticketId,
    String reason,
  ) async {
    final repo = ref.read(adminRepositoryProvider);
    final user = ref.read(currentUserProfileProvider).value;

    final result = await repo.updateTicketStatus(ticketId, TicketStatus.rejected);
    if (result.isRight() && user != null) {
      await _auditActionHelper(
        repo: repo,
        user: user,
        action: 'reject_ticket',
        targetId: ticketId,
        targetType: 'dispute_ticket',
        metadata: {'reason': reason},
      );
    }
    return result;
  }
}

final platformConfigProvider = StreamProvider<PlatformConfig>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return firestore
      .collection('platform_settings')
      .doc('global_config')
      .snapshots()
      .map((doc) {
    if (!doc.exists) {
      return const PlatformConfig(
        defaultCommissionRate: 0.085,
        categoryCommissionOverrides: {},
        maintenanceModeActive: false,
        globalRateLimitPerMinute: 600,
        razorpayKey: 'rzp_test_placeholder_key',
        announcementText: '',
        featuredCategory: '',
      );
    }
    final data = doc.data()!;
    return PlatformConfig(
      defaultCommissionRate:
          (data['defaultCommissionRate'] as num?)?.toDouble() ?? 0.085,
      categoryCommissionOverrides: Map<String, double>.from(
        (data['categoryOverrides'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
      ),
      maintenanceModeActive: data['maintenanceModeActive'] as bool? ?? false,
      globalRateLimitPerMinute: data['globalRateLimitPerMinute'] as int? ?? 600,
      razorpayKey: 'managed_via_functions',
      announcementText: data['announcementText'] as String? ?? '',
      featuredCategory: data['featuredCategory'] as String? ?? '',
    );
  });
});
