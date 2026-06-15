import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/admin/domain/entities/dispute_ticket.dart';
import 'package:ecom/features/admin/domain/entities/platform_config.dart';

abstract class AdminRepository {
  Future<Either<String, List<DisputeTicket>>> fetchActiveDisputes({required int limit});
  Future<Either<String, Unit>> updateTicketStatus(String ticketId, TicketStatus nextStatus);
  Future<Either<String, PlatformConfig>> fetchSystemGlobalConfigurations();
  Future<Either<String, Unit>> patchCommissionStructure(String categoryKey, double explicitRate);
}