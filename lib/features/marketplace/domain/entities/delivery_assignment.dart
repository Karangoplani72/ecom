enum AssignmentStatus { unassigned, accepted, enRouteToStore, packagePickedUp, delivered, failed }

class DeliveryAssignment {
  final String id;
  final String orderId;
  final String? deliveryAgentId;
  final AssignmentStatus status;
  final double currentLatitude;
  final double currentLongitude;
  final String secureVerificationOtp;
  final DateTime? updatedTime;

  const DeliveryAssignment({
    required this.id,
    required this.orderId,
    this.deliveryAgentId,
    required this.status,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.secureVerificationOtp,
    this.updatedTime,
  });

  bool get requiresHandshakeVerification =>
      status == AssignmentStatus.packagePickedUp || status == AssignmentStatus.delivered;
}