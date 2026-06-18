import 'package:ecom/features/admin/domain/entities/dispute_ticket.dart';
import 'package:ecom/features/admin/domain/entities/platform_config.dart';
import 'package:ecom/features/seller_application/domain/entities/seller_application.dart';
import 'package:fpdart/fpdart.dart';

abstract class AdminRepository {
  Future<Either<String, List<DisputeTicket>>> fetchActiveDisputes({
    required int limit,
  });

  Future<Either<String, Unit>> updateTicketStatus(
    String ticketId,
    TicketStatus nextStatus,
  );

  Future<Either<String, PlatformConfig>> fetchSystemGlobalConfigurations();

  Future<Either<String, Unit>> patchCommissionStructure(
    String categoryKey,
    double explicitRate,
  );

  // ===========================
  // Seller Application Approval
  // ===========================

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
}
