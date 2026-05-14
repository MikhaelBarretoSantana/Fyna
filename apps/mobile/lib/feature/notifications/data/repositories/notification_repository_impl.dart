import 'package:fyna/feature/notifications/data/datasource/notification_remote_datasource.dart';
import 'package:fyna/feature/notifications/domain/entities/notification_entity.dart';
import 'package:fyna/feature/notifications/domain/repositories/notification_repository.dart';

/// Implementação concreta do [NotificationRepository].
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDatasource _datasource;

  NotificationRepositoryImpl({required NotificationRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<List<NotificationEntity>> getNotifications({
    int page = 0,
    int size = 20,
  }) {
    return _datasource.getNotifications(page: page, size: size);
  }

  @override
  Future<List<NotificationEntity>> getUnreadNotifications() {
    return _datasource.getUnreadNotifications();
  }

  @override
  Future<int> getUnreadCount() {
    return _datasource.getUnreadCount();
  }

  @override
  Future<NotificationEntity> markAsRead(String id) {
    return _datasource.markAsRead(id);
  }

  @override
  Future<int> markAllAsRead() {
    return _datasource.markAllAsRead();
  }

  @override
  Future<void> deleteNotification(String id) {
    return _datasource.deleteNotification(id);
  }
}
