import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:ecom/features/admin/domain/entities/admin_dashboard_metrics.dart';
import 'package:ecom/features/admin/domain/entities/admin_user.dart';
import 'package:ecom/features/admin/domain/entities/dispute_ticket.dart';
import 'package:ecom/features/admin/domain/entities/platform_config.dart';
import 'package:ecom/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecom/features/seller/domain/entities/store_profile.dart';
import 'package:ecom/features/seller_application/domain/entities/seller_application.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

// ─── Admin controller — dispute + application + store actions ────────────────
@riverpod
class AdminController extends _$AdminController {
  @override
  FutureOr<void> build() {}

  // ── Dispute actions ──────────────────────────────────────────────────────
  Future<Either<String, Unit>> resolveTicket(String ticketId) async {
    return ref
        .read(adminRepositoryProvider)
        .updateTicketStatus(ticketId, TicketStatus.resolved);
  }

  Future<Either<String, Unit>> assignTicket(
    String ticketId,
    String agentId,
  ) async {
    return ref.read(adminRepositoryProvider).assignTicket(ticketId, agentId);
  }

  // ── Seller application actions ───────────────────────────────────────────
  Future<Either<String, Unit>> approveSellerApplication(
    String applicationId,
    String adminId,
  ) async {
    final result = await ref
        .read(adminRepositoryProvider)
        .approveSellerApplication(applicationId, adminId);

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
    ref.invalidate(adminDashboardMetricsProvider);
    return result;
  }

  Future<Either<String, Unit>> activateStore(String storeId) async {
    final result =
        await ref.read(adminRepositoryProvider).activateStore(storeId);
    ref.invalidate(adminDashboardMetricsProvider);
    return result;
  }

  Future<Either<String, Unit>> deleteStore(String storeId) async {
    final result =
        await ref.read(adminRepositoryProvider).deleteStore(storeId);
    ref.invalidate(adminDashboardMetricsProvider);
    return result;
  }

  // ── User actions ─────────────────────────────────────────────────────────
  Future<Either<String, Unit>> deleteUser(String uid) async {
    return ref.read(adminRepositoryProvider).deleteUser(uid);
  }

  Future<Either<String, Unit>> updateUserRoles(
    String uid,
    List<String> roles,
  ) async {
    return ref.read(adminRepositoryProvider).updateUserRoles(uid, roles);
  }

  Future<Either<String, Unit>> setUserActiveStatus(
    String uid,
    bool isActive,
  ) async {
    return ref.read(adminRepositoryProvider).setUserActiveStatus(uid, isActive);
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
