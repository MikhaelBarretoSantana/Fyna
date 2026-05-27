import 'package:dio/dio.dart';
import 'package:fyna/core/enums/budget_period_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/budget/domain/entities/budget_entity.dart';

class BudgetRemoteDatasource {
  final Dio _dio;

  BudgetRemoteDatasource(this._dio);

  Future<List<BudgetEntity>> getActiveBudgets() async {
    try {
      final response = await _dio.get('/budgets');
      final json = response.data as Map<String, dynamic>;
      final data = json['data'];
      if (data is List) {
        return data
            .map((e) => BudgetEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<List<BudgetEntity>> getCurrentBudgets() async {
    try {
      final response = await _dio.get('/budgets/current');
      final json = response.data as Map<String, dynamic>;
      final data = json['data'];
      if (data is List) {
        return data
            .map((e) => BudgetEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<BudgetEntity> getBudget(String id) async {
    try {
      final response = await _dio.get('/budgets/$id');
      final json = response.data as Map<String, dynamic>;
      return BudgetEntity.fromJson(json['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<BudgetEntity> createBudget({
    String? categoryId,
    required String name,
    required double amountLimit,
    required BudgetPeriodType periodType,
    required DateTime startDate,
    required DateTime endDate,
    double? alertThreshold,
    bool? alertEnabled,
  }) async {
    try {
      final body = <String, dynamic>{
        if (categoryId != null) 'categoryId': categoryId,
        'name': name,
        'amountLimit': amountLimit,
        'periodType': periodType.toJson(),
        'startDate': _formatDate(startDate),
        'endDate': _formatDate(endDate),
        if (alertThreshold != null) 'alertThreshold': alertThreshold,
        if (alertEnabled != null) 'alertEnabled': alertEnabled,
      };
      final response = await _dio.post('/budgets', data: body);
      final json = response.data as Map<String, dynamic>;
      return BudgetEntity.fromJson(json['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<BudgetEntity> updateBudget({
    required String id,
    String? name,
    double? amountLimit,
    double? alertThreshold,
    bool? alertEnabled,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{
        if (name != null) 'name': name,
        if (amountLimit != null) 'amountLimit': amountLimit,
        if (alertThreshold != null) 'alertThreshold': alertThreshold,
        if (alertEnabled != null) 'alertEnabled': alertEnabled,
        if (isActive != null) 'isActive': isActive,
      };
      final response = await _dio.put('/budgets/$id', data: body);
      final json = response.data as Map<String, dynamic>;
      return BudgetEntity.fromJson(json['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _dio.delete('/budgets/$id');
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
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
