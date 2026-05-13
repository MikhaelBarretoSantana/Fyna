import 'package:fyna/core/enums/notification_type.dart';

class NotificationEntity {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String? actionUrl;
  final String? metadata;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? scheduledFor;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.actionUrl,
    this.metadata,
    required this.isRead,
    this.readAt,
    this.scheduledFor,
    required this.createdAt,
  });
}
