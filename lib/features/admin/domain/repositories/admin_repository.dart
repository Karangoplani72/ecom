import 'package:ecom/features/admin/domain/entities/admin_dashboard_metrics.dart';
import 'package:ecom/features/admin/domain/entities/dispute_ticket.dart';
import 'package:ecom/features/admin/domain/entities/platform_config.dart';
import 'package:ecom/features/admin/domain/entities/admin_user.dart';
import 'package:ecom/features/seller/domain/entities/store_profile.dart';
import 'package:ecom/features/seller_application/domain/entities/seller_application.dart';
import 'package:fpdart/fpdart.dart';

abstract class AdminRepository {
  // ─── Dashboard ────────────────────────────────────────────────────────────
  Future<AdminDashboardMetrics> fetchDashboardMetrics();

  // ─── Disputes ─────────────────────────────────────────────────────────────
  Future<Either<String, List<DisputeTicket>>> fetchActiveDisputes({
    required int limit,
  });

  Stream<List<DisputeTicket>> watchAllDisputes();

  Future<Either<String, Unit>> updateTicketStatus(
    String ticketId,
    TicketStatus nextStatus,
  );

  Future<Either<String, Unit>> assignTicket(
    String ticketId,
    String agentId,
  );

  // ─── Platform Config ─────────────────────────────────────────────────────
  Future<Either<String, PlatformConfig>> fetchSystemGlobalConfigurations();

  Future<Either<String, Unit>> patchCommissionStructure(
    String categoryKey,
    double explicitRate,
  );

  Future<Either<String, Unit>> savePlatformConfig(PlatformConfig config);

  // ─── Seller Applications ─────────────────────────────────────────────────
  Stream<List<SellerApplication>> watchPendingSellerApplications();

  Future<Either<String, List<SellerApplication>>>
      fetchPendingSellerApplications();

  Future<Either<String, Unit>> approveSellerApplication(
    String applicationId,
    String adminId,
  );

  Future<Either<String, Unit>> rejectSellerApplication(
    String applicationId,
    String adminId,
    String reason,
  );

  Future<Either<String, Unit>> requestChangesOnSellerApplication(
    String applicationId,
    String adminId,
    String feedback,
  );

  // ─── Stores ───────────────────────────────────────────────────────────────
  Stream<List<StoreProfile>> watchAllStores();

  Future<Either<String, Unit>> suspendStore(String storeId);

  Future<Either<String, Unit>> activateStore(String storeId);

  Future<Either<String, Unit>> deleteStore(String storeId);

  // ─── Users / Sellers ─────────────────────────────────────────────────────
  Stream<List<AdminUser>> watchAllUsers();

  Future<Either<String, Unit>> deleteUser(String uid);

  Future<Either<String, Unit>> updateUserRoles(
    String uid,
    List<String> roles,
  );

  Future<Either<String, Unit>> setUserActiveStatus(
    String uid,
    bool isActive,
  );
}
