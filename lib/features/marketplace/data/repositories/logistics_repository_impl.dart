import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/marketplace/domain/repositories/logistics_repository.dart';
import 'package:ecom/features/marketplace/data/dtos/delivery_assignment_dto.dart';
import 'package:ecom/features/marketplace/domain/entities/delivery_assignment.dart';

class LogisticsRepositoryImpl implements LogisticsRepository {
  final FirebaseFirestore _firestore;

  LogisticsRepositoryImpl({required this._firestore});

  @override
  Stream<DeliveryAssignment> streamActiveAssignment(String orderId) {
    return _firestore
        .collection('logistics_assignments')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        throw Exception("Target logistics routing profile missing.");
      }
      return DeliveryAssignmentDto.fromFirestore(snapshot.docs.first).toDomain();
    });
  }

  @override
  Future<Either<String, Unit>> updateAgentCoordinates(String assignmentId, double lat, double lng) async {
    try {
      await _firestore.collection('logistics_assignments').doc(assignmentId).update({
        'currentLatitude': lat,
        'currentLongitude': lng,
        'updatedTime': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left("Location Tracking Matrix Write Fault: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, Unit>> advanceAssignmentStatus(String assignmentId, AssignmentStatus nextStatus, {String? inputOtp}) async {
    try {
      final docRef = _firestore.collection('logistics_assignments').doc(assignmentId);

      // Execute within an isolated transaction layer to maintain state consistency
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("Assignment tracker not found.");

        final data = snapshot.data()!;

        if (nextStatus == AssignmentStatus.delivered) {
          if (data['secureVerificationOtp']?.toString() != inputOtp) {
            throw Exception("Handshake security failed: OTP entry mismatched.");
          }
        }

        transaction.update(docRef, {
          'status': nextStatus.name,
          'updatedTime': FieldValue.serverTimestamp(),
        });
      });

      return const Right(unit);
    } catch (e) {
      return Left("Logistics Workflow Rejection: ${e.toString()}");
    }
  }
}