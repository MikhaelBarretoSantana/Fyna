import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/network/api_response_model.dart';
import 'package:fyna/feature/auth/domain/entities/auth_entity.dart';

/// Datasource remoto para as chamadas de autenticação.
class AuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource(this._dio);

  /// POST /auth/register
  Future<AuthEntity> register(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/auth/register', data: body);
      final json = response.data as Map<String, dynamic>;

      debugPrint('Register response status: ${response.statusCode}');
      debugPrint('Register response body: $json');

      // O backend pode retornar:
      // 1) Wrapping: { success, message, data: { accessToken, ... }, timestamp }
      // 2) Direto:   { accessToken, refreshToken, tokenType, user: { ... } }
      if (json.containsKey('accessToken')) {
        // Formato direto — sem wrapper ApiResponse
        return AuthEntity.fromJson(json);
      }

      // Formato com wrapper ApiResponse
      final apiResponse = ApiResponseModel<AuthEntity>.fromJson(
        json,
        (data) => AuthEntity.fromJson(data),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw ServerException(
          message: apiResponse.message ?? 'Erro ao registrar',
          statusCode: response.statusCode,
        );
      }

      return apiResponse.data!;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// POST /auth/login
  Future<AuthEntity> login(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/auth/login', data: body);
      final json = response.data as Map<String, dynamic>;

      // Suporte a ambos os formatos de resposta
      if (json.containsKey('accessToken')) {
        return AuthEntity.fromJson(json);
      }

      final apiResponse = ApiResponseModel<AuthEntity>.fromJson(
        json,
        (data) => AuthEntity.fromJson(data),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw ServerException(
          message: apiResponse.message ?? 'Erro ao fazer login',
          statusCode: response.statusCode,
        );
      }

      return apiResponse.data!;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// POST /auth/refresh
  Future<AuthEntity> refresh(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final json = response.data as Map<String, dynamic>;
      if (json.containsKey('accessToken')) return AuthEntity.fromJson(json);
      final apiResponse = ApiResponseModel<AuthEntity>.fromJson(
        json,
        (data) => AuthEntity.fromJson(data),
      );
      if (!apiResponse.success || apiResponse.data == null) {
        throw ServerException(
          message: apiResponse.message ?? 'Sessão expirada',
          statusCode: response.statusCode,
        );
      }
      return apiResponse.data!;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// POST /auth/logout
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
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
