import 'package:fyna/core/enums/budget_period_type.dart';
import 'package:fyna/feature/budget/data/datasource/budget_remote_datasource.dart';
import 'package:fyna/feature/budget/domain/entities/budget_entity.dart';
import 'package:fyna/feature/budget/domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetRemoteDatasource _datasource;

  BudgetRepositoryImpl({required BudgetRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<List<BudgetEntity>> getActiveBudgets() =>
      _datasource.getActiveBudgets();

  @override
  Future<List<BudgetEntity>> getCurrentBudgets() =>
      _datasource.getCurrentBudgets();

  @override
  Future<BudgetEntity> getBudget(String id) => _datasource.getBudget(id);

  @override
  Future<BudgetEntity> createBudget({
    String? categoryId,
    required String name,
    required double amountLimit,
    required BudgetPeriodType periodType,
    required DateTime startDate,
    required DateTime endDate,
    double? alertThreshold,
    bool? alertEnabled,
  }) =>
      _datasource.createBudget(
        categoryId: categoryId,
        name: name,
        amountLimit: amountLimit,
        periodType: periodType,
        startDate: startDate,
        endDate: endDate,
        alertThreshold: alertThreshold,
        alertEnabled: alertEnabled,
      );

  @override
  Future<BudgetEntity> updateBudget({
    required String id,
    String? name,
    double? amountLimit,
    double? alertThreshold,
    bool? alertEnabled,
    bool? isActive,
  }) =>
      _datasource.updateBudget(
        id: id,
        name: name,
        amountLimit: amountLimit,
        alertThreshold: alertThreshold,
        alertEnabled: alertEnabled,
        isActive: isActive,
      );

  @override
  Future<void> deleteBudget(String id) => _datasource.deleteBudget(id);
}
