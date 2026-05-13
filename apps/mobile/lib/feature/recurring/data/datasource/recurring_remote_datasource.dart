import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/recurring/domain/entities/recurring_transaction_entity.dart';

/// Datasource remoto para recorrências — chama /api/v1/recurring-transactions.
class RecurringRemoteDatasource {
  final Dio _dio;

  RecurringRemoteDatasource(this._dio);

  /// GET /api/v1/recurring-transactions
  Future<List<RecurringTransactionEntity>> getActiveRecurring() async {
    try {
      final response = await _dio.get('/recurring-transactions');
      return _parseList(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// GET /api/v1/recurring-transactions/all
  Future<List<RecurringTransactionEntity>> getAllRecurring() async {
    try {
      final response = await _dio.get('/recurring-transactions/all');
      return _parseList(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// GET /api/v1/recurring-transactions/{id}
  Future<RecurringTransactionEntity> getRecurring(String id) async {
    try {
      final response = await _dio.get('/recurring-transactions/$id');
      final json = response.data as Map<String, dynamic>;
      if (json.containsKey('data') && json['data'] != null) {
        return RecurringTransactionEntity.fromJson(
            json['data'] as Map<String, dynamic>);
      }
      return RecurringTransactionEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// POST /api/v1/recurring-transactions
  Future<RecurringTransactionEntity> createRecurring(
      Map<String, dynamic> body) async {
    try {
      final response =
          await _dio.post('/recurring-transactions', data: body);
      final json = response.data as Map<String, dynamic>;
      if (json.containsKey('data') && json['data'] != null) {
        return RecurringTransactionEntity.fromJson(
            json['data'] as Map<String, dynamic>);
      }
      return RecurringTransactionEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// PUT /api/v1/recurring-transactions/{id}
  Future<RecurringTransactionEntity> updateRecurring(
      String id, Map<String, dynamic> body) async {
    try {
      final response =
          await _dio.put('/recurring-transactions/$id', data: body);
      final json = response.data as Map<String, dynamic>;
      if (json.containsKey('data') && json['data'] != null) {
        return RecurringTransactionEntity.fromJson(
            json['data'] as Map<String, dynamic>);
      }
      return RecurringTransactionEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// DELETE /api/v1/recurring-transactions/{id}
  Future<void> deleteRecurring(String id) async {
    try {
      await _dio.delete('/recurring-transactions/$id');
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  List<RecurringTransactionEntity> _parseList(dynamic responseData) {
    final json = responseData as Map<String, dynamic>;
    if (json.containsKey('success')) {
      final success = json['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          message:
              json['message'] as String? ?? 'Erro ao buscar recorrências',
        );
      }
      final dataList = json['data'] as List<dynamic>? ?? [];
      return dataList
          .map((e) =>
              RecurringTransactionEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (responseData is List) {
      return (responseData as List)
          .map((e) =>
              RecurringTransactionEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

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
        throw ServerException(message: e.message ?? 'Erro inesperado');
    }
  }
}