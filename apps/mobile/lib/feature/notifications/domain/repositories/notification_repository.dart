import 'package:fyna/feature/notifications/domain/entities/notification_entity.dart';

/// Contrato do repositório de notificações.
abstract class NotificationRepository {
  /// Lista paginada de notificações do usuário autenticado.
  Future<List<NotificationEntity>> getNotifications({
    int page = 0,
    int size = 20,
  });

  /// Lista todas as notificações não lidas.
  Future<List<NotificationEntity>> getUnreadNotifications();

  /// Quantidade de notificações não lidas.
  Future<int> getUnreadCount();

  /// Marca uma notificação como lida.
  Future<NotificationEntity> markAsRead(String id);

  /// Marca todas as notificações do usuário como lidas.
  /// Retorna a quantidade que foi atualizada.
  Future<int> markAllAsRead();

  /// Exclui uma notificação.
  Future<void> deleteNotification(String id);
}
