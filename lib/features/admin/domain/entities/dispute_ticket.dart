enum TicketPriority { low, medium, high, critical }
enum TicketStatus { open, underInvestigation, resolved, rejected }

class DisputeTicket {
  final String id;
  final String transactionId;
  final String reporterId;
  final String reportedStoreId;
  final String reason;
  final TicketPriority priority;
  final TicketStatus status;
  final String? assignedAgentId;
  final DateTime createdAt;

  const DisputeTicket({
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

  bool get isEscalated => priority == TicketPriority.high || priority == TicketPriority.critical;
}