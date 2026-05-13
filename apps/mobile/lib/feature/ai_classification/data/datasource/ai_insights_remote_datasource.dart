import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/ai_classification/domain/entities/ai_classification_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/spending_pattern_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/spending_prediction_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/investment_recommendation_entity.dart';

/// Datasource remoto para AI Insights — chama /api/v1/ai/*.
class AIInsightsRemoteDatasource {
  final Dio _dio;

  AIInsightsRemoteDatasource(this._dio);

  // ═══════════════════════════════════════
  //  Trigger Analysis & Health
  // ═══════════════════════════════════════

  /// POST /api/v1/ai/analyze — dispara análise completa (async no backend).
  Future<void> triggerAnalysis() async {
    try {
      await _dio.post('/ai/analyze');
    } on DioException catch (e) {
      debugPrint('AI analysis trigger failed: ${e.message}');
    }
  }

  /// GET /api/v1/ai/health — verifica se o motor de IA está rodando.
  Future<bool> isAIHealthy() async {
    try {
      final response = await _dio.get('/ai/health');
      final json = response.data as Map<String, dynamic>;
      if (json.containsKey('data') && json['data'] is Map) {
        return (json['data'] as Map)['ai_engine_healthy'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ═══════════════════════════════════════
  //  Spending Patterns
  // ═══════════════════════════════════════

  /// GET /api/v1/ai/patterns
  Future<List<SpendingPatternEntity>> getActivePatterns({String? type}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;

      final response = await _dio.get(
        '/ai/patterns',
        queryParameters: queryParams,
      );
      return _parseList(response.data, SpendingPatternEntity.fromJson);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════
  //  Spending Predictions
  // ═══════════════════════════════════════

  /// GET /api/v1/ai/predictions
  Future<List<SpendingPredictionEntity>> getPredictions({
    String? startDate,
    String? endDate,
    String? categoryId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (categoryId != null) queryParams['categoryId'] = categoryId;

      final response = await _dio.get(
        '/ai/predictions',
        queryParameters: queryParams,
      );
      return _parseList(response.data, SpendingPredictionEntity.fromJson);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════
  //  AI Classifications
  // ═══════════════════════════════════════

  /// GET /api/v1/ai/classifications/pending
  Future<List<AIClassificationEntity>> getPendingClassifications() async {
    try {
      final response = await _dio.get('/ai/classifications/pending');
      return _parseList(response.data, AIClassificationEntity.fromJson);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// POST /api/v1/ai/classifications/{id}/confirm
  Future<AIClassificationEntity> confirmClassification(
    String id,
    String confirmedCategoryId,
  ) async {
    try {
      final response = await _dio.post(
        '/ai/classifications/$id/confirm',
        data: {'confirmedCategoryId': confirmedCategoryId},
      );
      final json = response.data as Map<String, dynamic>;
      if (json.containsKey('data') && json['data'] != null) {
        return AIClassificationEntity.fromJson(
            json['data'] as Map<String, dynamic>);
      }
      return AIClassificationEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════
  //  Investment Recommendations
  // ═══════════════════════════════════════

  /// GET /api/v1/ai/recommendations
  Future<List<InvestmentRecommendationEntity>> getRecommendations({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/ai/recommendations',
        queryParameters: {'page': page, 'size': size},
      );
      final json = response.data as Map<String, dynamic>;

      // Formato: { success, data: { content: [...] }, timestamp }
      if (json.containsKey('success')) {
        final data = json['data'] as Map<String, dynamic>? ?? {};
        final list = data['content'] as List<dynamic>? ?? [];
        return list
            .map((item) => InvestmentRecommendationEntity.fromJson(
                item as Map<String, dynamic>))
            .toList();
      }

      final list = json['content'] as List<dynamic>? ?? [];
      return list
          .map((item) => InvestmentRecommendationEntity.fromJson(
              item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// GET /api/v1/ai/recommendations/unviewed
  Future<List<InvestmentRecommendationEntity>>
      getUnviewedRecommendations() async {
    try {
      final response = await _dio.get('/ai/recommendations/unviewed');
      return _parseList(
          response.data, InvestmentRecommendationEntity.fromJson);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// PATCH /api/v1/ai/recommendations/{id}/view
  Future<InvestmentRecommendationEntity> markAsViewed(String id) async {
    try {
      final response = await _dio.patch('/ai/recommendations/$id/view');
      final json = response.data as Map<String, dynamic>;
      if (json.containsKey('data') && json['data'] != null) {
        return InvestmentRecommendationEntity.fromJson(
            json['data'] as Map<String, dynamic>);
      }
      return InvestmentRecommendationEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// PATCH /api/v1/ai/recommendations/{id}/follow
  Future<InvestmentRecommendationEntity> markAsFollowed(String id) async {
    try {
      final response = await _dio.patch('/ai/recommendations/$id/follow');
      final json = response.data as Map<String, dynamic>;
      if (json.containsKey('data') && json['data'] != null) {
        return InvestmentRecommendationEntity.fromJson(
            json['data'] as Map<String, dynamic>);
      }
      return InvestmentRecommendationEntity.fromJson(json);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════
  //  Helpers
  // ═══════════════════════════════════════

  /// Parseia resposta de lista com wrapper ApiResponse.
  List<T> _parseList<T>(
    dynamic responseData,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final json = responseData as Map<String, dynamic>;

    if (json.containsKey('success')) {
      final success = json['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          message: json['message'] as String? ?? 'Erro ao buscar dados de IA',
        );
      }
      final data = json['data'];
      if (data is List) {
        return data
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    if (json.containsKey('data') && json['data'] is List) {
      return (json['data'] as List)
          .map((item) => fromJson(item as Map<String, dynamic>))
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
        throw ServerException(
          message: e.message ?? 'Erro inesperado',
        );
    }
  }
}