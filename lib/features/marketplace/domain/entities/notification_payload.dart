class NotificationPayload {
  final String id;
  final String title;
  final String body;
  final String deepLinkPath;
  final DateTime receivedAt;

  const NotificationPayload({
    required this.id,
    required this.title,
    required this.body,
    required this.deepLinkPath,
    required this.receivedAt,
  });
}
