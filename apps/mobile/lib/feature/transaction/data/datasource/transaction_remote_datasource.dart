import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/network/page_response_model.dart';
import 'package:fyna/feature/transaction/domain/entities/transaction_entity.dart';

/// Datasource remoto para transações — chama /api/v1/transactions.
class TransactionRemoteDatasource {
  final Dio _dio;

  TransactionRemoteDatasource(this._dio);

  /// GET /api/v1/transactions
  Future<PageResponseModel<TransactionEntity>> getTransactions({
    int page = 0,
    int size = 20,
    String? startDate,
    String? endDate,
    String? accountId,
    String? categoryId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        'sort': 'transactionDate,desc',
      };

      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (accountId != null) queryParams['accountId'] = accountId;
      if (categoryId != null) queryParams['categoryId'] = categoryId;

      final response = await _dio.get(
        '/transactions',
        queryParameters: queryParams,
      );
      final json = response.data as Map<String, dynamic>;

      debugPrint('Transactions response status: ${response.statusCode}');

      // Formato: { success, data: { content: [...], page, size, ... }, timestamp }
      if (json.containsKey('success')) {
        final success = json['success'] as bool? ?? false;
        if (!success) {
          throw ServerException(
            message:
                json['message'] as String? ?? 'Erro ao buscar transações',
            statusCode: response.statusCode,
          );
        }
        final data = json['data'] as Map<String, dynamic>? ?? {};
        return PageResponseModel.fromJson(
          data,
          (item) => TransactionEntity.fromJson(item),
        );
      }

      // Formato direto (PageResponse sem wrapper)
      return PageResponseModel.fromJson(
        json,
        (item) => TransactionEntity.fromJson(item),
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// GET /api/v1/transactions/{id}
  Future<TransactionEntity> getTransaction(String id) async {
    try {
      final response = await _dio.get('/transactions/$id');
      final json = response.data as Map<String, dynamic>;

      if (json.containsKey('data') && json['data'] != null) {
        return TransactionEntity.fromJson(
            json['data'] as Map<String, dynamic>);
      }

      return TransactionEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// POST /api/v1/transactions
  Future<TransactionEntity> createTransaction(
      Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/transactions', data: body);
      final json = response.data as Map<String, dynamic>;

      if (json.containsKey('data') && json['data'] != null) {
        return TransactionEntity.fromJson(
            json['data'] as Map<String, dynamic>);
      }

      return TransactionEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// PUT /api/v1/transactions/{id}
  Future<TransactionEntity> updateTransaction(
      String id, Map<String, dynamic> body) async {
    try {
      final response =
          await _dio.put('/transactions/$id', data: body);
      final json = response.data as Map<String, dynamic>;

      if (json.containsKey('data') && json['data'] != null) {
        return TransactionEntity.fromJson(
            json['data'] as Map<String, dynamic>);
      }

      return TransactionEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// DELETE /api/v1/transactions/{id}
  Future<void> deleteTransaction(String id) async {
    try {
      await _dio.delete('/transactions/$id');
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
