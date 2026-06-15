import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/marketplace/domain/entities/delivery_assignment.dart';

abstract class LogisticsRepository {
  Stream<DeliveryAssignment> streamActiveAssignment(String orderId);
  Future<Either<String, Unit>> updateAgentCoordinates(String assignmentId, double lat, double lng);
  Future<Either<String, Unit>> advanceAssignmentStatus(String assignmentId, AssignmentStatus nextStatus, {String? inputOtp});
}