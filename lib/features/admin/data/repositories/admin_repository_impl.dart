import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecom/features/admin/data/dtos/dispute_ticket_dto.dart';
import 'package:ecom/features/admin/domain/entities/dispute_ticket.dart';
import 'package:ecom/features/admin/domain/entities/platform_config.dart';

class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepositoryImpl({required this._firestore});

  @override
  Future<Either<String, List<DisputeTicket>>> fetchActiveDisputes({required int limit}) async {
    try {
      final snapshot = await _firestore
          .collection('disputes')
          .where('status', isNotEqualTo: TicketStatus.resolved.name)
          .orderBy('status')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final tickets = snapshot.docs.map((doc) => DisputeTicketDto.fromFirestore(doc).toDomain()).toList();
      return Right(tickets);
    } catch (e) {
      return Left("Governance System Index Query Fault: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, Unit>> updateTicketStatus(String ticketId, TicketStatus nextStatus) async {
    try {
      await _firestore.collection('disputes').doc(ticketId).update({
        'status': nextStatus.name,
      });
      return const Right(unit);
    } catch (e) {
      return Left("Ticket Security Status Mutation Refused: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, PlatformConfig>> fetchSystemGlobalConfigurations() async {
    try {
      final doc = await _firestore.collection('platform_settings').doc('global_config').get();
      if (!doc.exists) {
        return const Left("Platform core global configurations documents missing from runtime target.");
      }

      final data = doc.data()!;
      return Right(PlatformConfig(
        defaultCommissionRate: (data['defaultCommissionRate'] as num?)?.toDouble() ?? 0.10,
        categoryCommissionOverrides: Map<String, double>.from(data['categoryOverrides'] ?? {}),
        maintenanceModeActive: data['maintenanceModeActive'] as bool? ?? false,
        globalRateLimitPerMinute: data['globalRateLimitPerMinute'] as int? ?? 120,
      ));
    } catch (e) {
      return Left("Configuration Synchronization Crash: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, Unit>> patchCommissionStructure(String categoryKey, double explicitRate) async {
    try {
      await _firestore.collection('platform_settings').doc('global_config').update({
        'categoryOverrides.$categoryKey': explicitRate,
      });
      return const Right(unit);
    } catch (e) {
      return Left("Ledger Parameter Adjustment Fault: ${e.toString()}");
    }
  }
}