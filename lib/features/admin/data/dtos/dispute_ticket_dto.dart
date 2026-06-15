import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ecom/features/admin/domain/entities/dispute_ticket.dart';

part 'dispute_ticket_dto.g.dart';

@JsonSerializable()
class DisputeTicketDto {
  final String id;
  final String transactionId;
  final String reporterId;
  final String reportedStoreId;
  final String reason;
  final String priority;
  final String status;
  final String? assignedAgentId;

  @JsonKey(fromJson: _timestampToDateTime, toJson: _dateTimeToTimestamp)
  final DateTime createdAt;

  DisputeTicketDto({
    required this.id,
    required this.transactionId,
    required this.reporterId,
    required this.reportedStoreId,
    required this.reason,
    required this.priority,
    required this.status,
    this.assignedAgentId,
    required this.createdAt,
  });

  factory DisputeTicketDto.fromJson(Map<String, dynamic> json) => _$DisputeTicketDtoFromJson(json);
  Map<String, dynamic> toJson() => _$DisputeTicketDtoToJson(this);

  factory DisputeTicketDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return DisputeTicketDto.fromJson(data);
  }

  DisputeTicket toDomain() {
    return DisputeTicket(
      id: id,
      transactionId: transactionId,
      reporterId: reporterId,
      reportedStoreId: reportedStoreId,
      reason: reason,
      priority: TicketPriority.values.byName(priority),
      status: TicketStatus.values.byName(status),
      assignedAgentId: assignedAgentId,
      createdAt: createdAt,
    );
  }

  static DateTime _timestampToDateTime(dynamic val) => (val is Timestamp) ? val.toDate() : DateTime.now();
  static dynamic _dateTimeToTimestamp(DateTime date) => Timestamp.fromDate(date);
}