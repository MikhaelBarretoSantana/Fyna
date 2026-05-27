import 'package:fyna/core/enums/budget_period_type.dart';
import 'package:fyna/feature/budget/domain/entities/budget_entity.dart';

abstract class BudgetRepository {
  Future<List<BudgetEntity>> getActiveBudgets();
  Future<List<BudgetEntity>> getCurrentBudgets();
  Future<BudgetEntity> getBudget(String id);

  Future<BudgetEntity> createBudget({
    String? categoryId,
    required String name,
    required double amountLimit,
    required BudgetPeriodType periodType,
    required DateTime startDate,
    required DateTime endDate,
    double? alertThreshold,
    bool? alertEnabled,
  });

  Future<BudgetEntity> updateBudget({
    required String id,
    String? name,
    double? amountLimit,
    double? alertThreshold,
    bool? alertEnabled,
    bool? isActive,
  });

  Future<void> deleteBudget(String id);
}
