import 'package:dio/dio.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/goals/domain/entities/financial_goal_entity.dart';

class GoalRemoteDatasource {
  final Dio _dio;

  GoalRemoteDatasource(this._dio);

  Future<List<FinancialGoalEntity>> getGoals({String? status}) async {
    try {
      final response = await _dio.get(
        '/goals',
        queryParameters: status != null ? {'status': status} : null,
      );
      final json = response.data as Map<String, dynamic>;
      final data = json['data'];
      if (data is List) {
        return data
            .map((e) => FinancialGoalEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<FinancialGoalEntity> getGoal(String id) async {
    try {
      final response = await _dio.get('/goals/$id');
      final json = response.data as Map<String, dynamic>;
      return FinancialGoalEntity.fromJson(json['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<FinancialGoalEntity> createGoal({
    required String name,
    String? description,
    required double targetAmount,
    DateTime? targetDate,
    String? color,
    String? priority,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'targetAmount': targetAmount,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (targetDate != null)
          'targetDate': targetDate.toIso8601String().split('T').first,
        if (color != null) 'color': color,
        if (priority != null) 'priority': priority,
      };
      final response = await _dio.post('/goals', data: body);
      final json = response.data as Map<String, dynamic>;
      return FinancialGoalEntity.fromJson(json['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<FinancialGoalEntity> addProgress(String id, double amount) async {
    try {
      final response = await _dio.patch(
        '/goals/$id/progress',
        queryParameters: {'amount': amount},
      );
      final json = response.data as Map<String, dynamic>;
      return FinancialGoalEntity.fromJson(json['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _dio.delete('/goals/$id');
    } on DioException catch (e) {
      _handleDioError(e);
    }
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
