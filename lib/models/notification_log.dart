/// A logged notification (activity feed entry).
class NotificationLog {
  final String id;
  final String title;
  final String body;
  final String audience;
  final int sent;
  final bool delivered;
  final String? createdAt;
  final Map<String, dynamic> data;

  NotificationLog({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    required this.sent,
    required this.delivered,
    this.createdAt,
    required this.data,
  });

  factory NotificationLog.fromJson(Map<String, dynamic> j) => NotificationLog(
        id: j['id'] ?? '',
        title: (j['title'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        audience: (j['audience'] ?? '').toString(),
        sent: (j['sent'] ?? 0) as int,
        delivered: j['delivered'] ?? false,
        createdAt: j['created_at']?.toString(),
        data: (j['data'] as Map?)?.cast<String, dynamic>() ?? {},
      );
}
