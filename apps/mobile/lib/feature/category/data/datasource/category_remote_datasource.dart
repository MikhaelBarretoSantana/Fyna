import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/category/domain/entities/category_entity.dart';

/// Datasource remoto para categorias — chama /api/v1/categories.
class CategoryRemoteDatasource {
  final Dio _dio;

  CategoryRemoteDatasource(this._dio);

  /// GET /api/v1/categories
  Future<List<CategoryEntity>> getCategories({String? type}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;

      final response = await _dio.get(
        '/categories',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final json = response.data as Map<String, dynamic>;

      debugPrint('Categories response status: ${response.statusCode}');

      // Formato: { success, data: [ {...}, {...} ], timestamp }
      if (json.containsKey('success')) {
        final success = json['success'] as bool? ?? false;
        if (!success) {
          throw ServerException(
            message:
                json['message'] as String? ?? 'Erro ao buscar categorias',
            statusCode: response.statusCode,
          );
        }
        final dataList = json['data'] as List<dynamic>? ?? [];
        return dataList
            .map((e) => CategoryEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Formato direto (lista)
      if (response.data is List) {
        return (response.data as List)
            .map((e) => CategoryEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// GET /api/v1/categories/system
  Future<List<CategoryEntity>> getSystemCategories() async {
    try {
      final response = await _dio.get('/categories/system');
      final json = response.data as Map<String, dynamic>;

      if (json.containsKey('success')) {
        final success = json['success'] as bool? ?? false;
        if (!success) {
          throw ServerException(
            message: json['message'] as String? ??
                'Erro ao buscar categorias do sistema',
            statusCode: response.statusCode,
          );
        }
        final dataList = json['data'] as List<dynamic>? ?? [];
        return dataList
            .map((e) => CategoryEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (response.data is List) {
        return (response.data as List)
            .map((e) => CategoryEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// GET /api/v1/categories/{id}
  Future<CategoryEntity> getCategory(String id) async {
    try {
      final response = await _dio.get('/categories/$id');
      final json = response.data as Map<String, dynamic>;

      if (json.containsKey('data') && json['data'] != null) {
        return CategoryEntity.fromJson(json['data'] as Map<String, dynamic>);
      }

      return CategoryEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// POST /api/v1/categories
  Future<CategoryEntity> createCategory(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/categories', data: body);
      final json = response.data as Map<String, dynamic>;

      if (json.containsKey('data') && json['data'] != null) {
        return CategoryEntity.fromJson(json['data'] as Map<String, dynamic>);
      }

      return CategoryEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// PUT /api/v1/categories/{id}
  Future<CategoryEntity> updateCategory(
      String id, Map<String, dynamic> body) async {
    try {
      final response =
          await _dio.put('/categories/$id', data: body);
      final json = response.data as Map<String, dynamic>;

      if (json.containsKey('data') && json['data'] != null) {
        return CategoryEntity.fromJson(json['data'] as Map<String, dynamic>);
      }

      return CategoryEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// DELETE /api/v1/categories/{id}
  Future<void> deleteCategory(String id) async {
    try {
      await _dio.delete('/categories/$id');
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
