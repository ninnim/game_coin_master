class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id: j['id'] ?? '',
        type: j['type'] ?? 'info',
        title: j['title'] ?? '',
        message: j['message'] ?? '',
        isRead: j['isRead'] ?? false,
        createdAt:
            DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}
