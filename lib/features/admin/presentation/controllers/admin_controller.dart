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
Future<AdminDashboardMetrics> adminDashboardMetrics(Ref ref) async {
  return ref.read(adminRepositoryProvider).fetchDashboardMetrics();
}

// ─── Seller Applications ─────────────────────────────────────────────────────
@riverpod
Stream<List<SellerApplication>> pendingSellerApplications(Ref ref) {
  return ref.watch(adminRepositoryProvider).watchPendingSellerApplications();
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
  FutureOr<void> build() {}

  Future<Either<String, Unit>> _auditAction(
    String action,
    String targetId,
    String targetType, {
    Map<String, dynamic>? metadata,
  }) async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return const Right(unit);

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

    return ref.read(adminRepositoryProvider).createAuditLog(log);
  }

  // ── Dispute actions ──────────────────────────────────────────────────────
  Future<Either<String, Unit>> resolveTicket(String ticketId) async {
    final result = await ref
        .read(adminRepositoryProvider)
        .updateTicketStatus(ticketId, TicketStatus.resolved);
    
    if (result.isRight()) {
      await _auditAction('resolve_ticket', ticketId, 'dispute_ticket');
    }
    return result;
  }

  Future<Either<String, Unit>> assignTicket(
    String ticketId,
    String agentId,
  ) async {
    final result = await ref.read(adminRepositoryProvider).assignTicket(ticketId, agentId);
    if (result.isRight()) {
      await _auditAction('assign_ticket', ticketId, 'dispute_ticket', metadata: {'agentId': agentId});
    }
    return result;
  }

  // ── Seller application actions ───────────────────────────────────────────
  Future<Either<String, Unit>> approveSellerApplication(
    String applicationId,
    String adminId,
  ) async {
    final result = await ref
        .read(adminRepositoryProvider)
        .approveSellerApplication(applicationId, adminId);

    if (result.isRight()) {
      await _auditAction('approve_seller_application', applicationId, 'seller_application');
    }

    ref.invalidate(adminDashboardMetricsProvider);
    return result;
  }

  Future<Either<String, Unit>> rejectSellerApplication(
    String applicationId,
    String adminId,
    String reason,
  ) async {
    final result = await ref
        .read(adminRepositoryProvider)
        .rejectSellerApplication(applicationId, adminId, reason);

    if (result.isRight()) {
      await _auditAction('reject_seller_application', applicationId, 'seller_application', metadata: {'reason': reason});
    }

    ref.invalidate(adminDashboardMetricsProvider);
    return result;
  }

  Future<Either<String, Unit>> requestChangesOnSellerApplication(
    String applicationId,
    String adminId,
    String feedback,
  ) async {
    return ref
        .read(adminRepositoryProvider)
        .requestChangesOnSellerApplication(applicationId, adminId, feedback);
  }

  // ── Store actions ────────────────────────────────────────────────────────
  Future<Either<String, Unit>> suspendStore(String storeId) async {
    final result =
        await ref.read(adminRepositoryProvider).suspendStore(storeId);
    if (result.isRight()) {
      await _auditAction('suspend_store', storeId, 'store');
    }
    ref.invalidate(adminDashboardMetricsProvider);
    return result;
  }

  Future<Either<String, Unit>> activateStore(String storeId) async {
    final result =
        await ref.read(adminRepositoryProvider).activateStore(storeId);
    if (result.isRight()) {
      await _auditAction('activate_store', storeId, 'store');
    }
    ref.invalidate(adminDashboardMetricsProvider);
    return result;
  }

  Future<Either<String, Unit>> deleteStore(String storeId) async {
    final result =
        await ref.read(adminRepositoryProvider).deleteStore(storeId);
    if (result.isRight()) {
      await _auditAction('delete_store', storeId, 'store');
    }
    ref.invalidate(adminDashboardMetricsProvider);
    return result;
  }

  // ── User actions ─────────────────────────────────────────────────────────
  Future<Either<String, Unit>> deleteUser(String uid) async {
    final result = await ref.read(adminRepositoryProvider).deleteUser(uid);
    if (result.isRight()) {
      await _auditAction('delete_user', uid, 'user');
    }
    return result;
  }

  Future<Either<String, Unit>> updateUserRoles(
    String uid,
    List<String> roles,
  ) async {
    final result = await ref.read(adminRepositoryProvider).updateUserRoles(uid, roles);
    if (result.isRight()) {
      await _auditAction('update_user_roles', uid, 'user', metadata: {'roles': roles});
    }
    return result;
  }

  Future<Either<String, Unit>> setUserActiveStatus(
    String uid,
    bool isActive,
  ) async {
    final result = await ref.read(adminRepositoryProvider).setUserActiveStatus(uid, isActive);
    if (result.isRight()) {
      await _auditAction('set_user_active_status', uid, 'user', metadata: {'isActive': isActive});
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
    );
  });
});
