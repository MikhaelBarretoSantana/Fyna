import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/account/domain/entities/account_entity.dart';

/// Datasource remoto para contas — chama /api/v1/accounts.
class AccountRemoteDatasource {
  final Dio _dio;

  AccountRemoteDatasource(this._dio);

  /// GET /api/v1/accounts
  Future<List<AccountEntity>> getAccounts() async {
    try {
      final response = await _dio.get('/accounts');
      final json = response.data as Map<String, dynamic>;

      debugPrint('Accounts response status: ${response.statusCode}');

      // Formato: { success, data: [ {...}, {...} ], timestamp }
      if (json.containsKey('success')) {
        final success = json['success'] as bool? ?? false;
        if (!success) {
          throw ServerException(
            message: json['message'] as String? ?? 'Erro ao buscar contas',
            statusCode: response.statusCode,
          );
        }
        final dataList = json['data'] as List<dynamic>? ?? [];
        return dataList
            .map((e) => AccountEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Formato direto (lista)
      if (response.data is List) {
        return (response.data as List)
            .map((e) => AccountEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// GET /api/v1/accounts/{id}
  Future<AccountEntity> getAccount(String id) async {
    try {
      final response = await _dio.get('/accounts/$id');
      final json = response.data as Map<String, dynamic>;

      if (json.containsKey('data') && json['data'] != null) {
        return AccountEntity.fromJson(json['data'] as Map<String, dynamic>);
      }

      return AccountEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// POST /api/v1/accounts
  Future<AccountEntity> createAccount(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/accounts', data: body);
      final json = response.data as Map<String, dynamic>;

      if (json.containsKey('data') && json['data'] != null) {
        return AccountEntity.fromJson(json['data'] as Map<String, dynamic>);
      }

      return AccountEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// PUT /api/v1/accounts/{id}
  Future<AccountEntity> updateAccount(
      String id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put('/accounts/$id', data: body);
      final json = response.data as Map<String, dynamic>;

      if (json.containsKey('data') && json['data'] != null) {
        return AccountEntity.fromJson(json['data'] as Map<String, dynamic>);
      }

      return AccountEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// DELETE /api/v1/accounts/{id}
  Future<void> deleteAccount(String id) async {
    try {
      await _dio.delete('/accounts/$id');
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
