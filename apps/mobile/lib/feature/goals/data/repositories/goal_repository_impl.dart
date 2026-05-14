import 'package:fyna/feature/goals/data/datasource/goal_remote_datasource.dart';
import 'package:fyna/feature/goals/domain/entities/financial_goal_entity.dart';
import 'package:fyna/feature/goals/domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  final GoalRemoteDatasource _datasource;

  GoalRepositoryImpl({required GoalRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<List<FinancialGoalEntity>> getGoals({String? status}) =>
      _datasource.getGoals(status: status);

  @override
  Future<FinancialGoalEntity> getGoal(String id) => _datasource.getGoal(id);

  @override
  Future<FinancialGoalEntity> createGoal({
    required String name,
    String? description,
    required double targetAmount,
    DateTime? targetDate,
    String? color,
    String? priority,
  }) =>
      _datasource.createGoal(
        name: name,
        description: description,
        targetAmount: targetAmount,
        targetDate: targetDate,
        color: color,
        priority: priority,
      );

  @override
  Future<FinancialGoalEntity> addProgress(String id, double amount) =>
      _datasource.addProgress(id, amount);

  @override
  Future<void> deleteGoal(String id) => _datasource.deleteGoal(id);
}
