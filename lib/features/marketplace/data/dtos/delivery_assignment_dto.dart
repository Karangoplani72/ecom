import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ecom/features/marketplace/domain/entities/delivery_assignment.dart';

part 'delivery_assignment_dto.g.dart';

@JsonSerializable()
class DeliveryAssignmentDto {
  final String id;
  final String orderId;
  final String? deliveryAgentId;
  final String status;
  final double currentLatitude;
  final double currentLongitude;
  final String secureVerificationOtp;

  @JsonKey(
    fromJson: _timestampToDateTime,
    toJson: _dateTimeToTimestamp,
  )
  final DateTime? updatedTime;

  DeliveryAssignmentDto({
    required this.id,
    required this.orderId,
    this.deliveryAgentId,
    required this.status,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.secureVerificationOtp,
    this.updatedTime,
  });

  factory DeliveryAssignmentDto.fromJson(
      Map<String, dynamic> json,
      ) =>
      _$DeliveryAssignmentDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$DeliveryAssignmentDtoToJson(this);

  factory DeliveryAssignmentDto.fromFirestore(
      DocumentSnapshot doc,
      ) {
    final data = doc.data() as Map<String, dynamic>;

    return DeliveryAssignmentDto.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  DeliveryAssignment toDomain() {
    return DeliveryAssignment(
      id: id,
      orderId: orderId,
      deliveryAgentId: deliveryAgentId,
      status: AssignmentStatus.values.byName(status),
      currentLatitude: currentLatitude,
      currentLongitude: currentLongitude,
      secureVerificationOtp: secureVerificationOtp,
      updatedTime: updatedTime,
    );
  }

  static DateTime? _timestampToDateTime(
      dynamic value,
      ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }

  static dynamic _dateTimeToTimestamp(
      DateTime? value,
      ) {
    if (value == null) {
      return null;
    }

    return Timestamp.fromDate(value);
  }
}