import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/notifications/domain/entities/notification_entity.dart';

/// Datasource remoto para notificações — chama /api/v1/notifications.
class NotificationRemoteDatasource {
  final Dio _dio;

  NotificationRemoteDatasource(this._dio);

  /// GET /api/v1/notifications?page=&size=
  /// Retorna `PageResponse<NotificationResponse>`.
  Future<List<NotificationEntity>> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'page': page, 'size': size},
      );
      final json = response.data as Map<String, dynamic>;

      debugPrint('Notifications response status: ${response.statusCode}');

      // Formato: { success, data: { content: [...], page, size, ... }, timestamp }
      if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
        final pageData = json['data'] as Map<String, dynamic>;
        final content = pageData['content'] as List<dynamic>? ?? [];
        return content
            .map((e) => NotificationEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// GET /api/v1/notifications/unread
  Future<List<NotificationEntity>> getUnreadNotifications() async {
    try {
      final response = await _dio.get('/notifications/unread');
      final json = response.data as Map<String, dynamic>;

      if (json.containsKey('data') && json['data'] is List) {
        return (json['data'] as List)
            .map((e) => NotificationEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// GET /api/v1/notifications/unread/count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread/count');
      final json = response.data as Map<String, dynamic>;

      final data = json['data'];
      if (data is Map<String, dynamic>) {
        final count = data['count'];
        if (count is num) return count.toInt();
      }
      return 0;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// PATCH /api/v1/notifications/{id}/read
  Future<NotificationEntity> markAsRead(String id) async {
    try {
      final response = await _dio.patch('/notifications/$id/read');
      final json = response.data as Map<String, dynamic>;

      if (json.containsKey('data') && json['data'] != null) {
        return NotificationEntity.fromJson(
            json['data'] as Map<String, dynamic>);
      }

      return NotificationEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// PATCH /api/v1/notifications/read-all
  Future<int> markAllAsRead() async {
    try {
      final response = await _dio.patch('/notifications/read-all');
      final json = response.data as Map<String, dynamic>;

      final data = json['data'];
      if (data is Map<String, dynamic>) {
        final updated = data['updated'];
        if (updated is num) return updated.toInt();
      }
      return 0;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// DELETE /api/v1/notifications/{id}
  Future<void> deleteNotification(String id) async {
    try {
      await _dio.delete('/notifications/$id');
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Converte DioException em exceções do domínio.
  Never _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw TimeoutException();
      case DioExceptionType.connectionError:
        throw NetworkException();
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        String message = 'Erro no servidor';
        if (data is Map<String, dynamic>) {
          message = data['message'] as String? ?? message;
        }
        throw ServerException(
          message: message,
          statusCode: e.response?.statusCode,
        );
      default:
        throw ServerException(
          message: e.message ?? 'Erro inesperado',
        );
    }
  }
}
