import 'package:fyna/core/enums/notification_type.dart';

/// Entidade de domínio de notificação — espelha `NotificationResponse` do backend.
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

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'].toString(),
      type: NotificationType.fromJson(json['type'] as String? ?? 'SYSTEM'),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      actionUrl: json['actionUrl'] as String?,
      metadata: json['metadata'] as String?,
      isRead: json['isRead'] as bool? ?? json['read'] as bool? ?? false,
      readAt: _parseDate(json['readAt']),
      scheduledFor: _parseDate(json['scheduledFor']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'title': title,
      'message': message,
      'actionUrl': actionUrl,
      'metadata': metadata,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationEntity copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationEntity(
      id: id,
      type: type,
      title: title,
      message: message,
      actionUrl: actionUrl,
      metadata: metadata,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      scheduledFor: scheduledFor,
      createdAt: createdAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
