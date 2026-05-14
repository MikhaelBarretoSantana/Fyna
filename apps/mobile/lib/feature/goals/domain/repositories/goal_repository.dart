import 'package:fyna/feature/goals/domain/entities/financial_goal_entity.dart';

abstract class GoalRepository {
  Future<List<FinancialGoalEntity>> getGoals({String? status});
  Future<FinancialGoalEntity> getGoal(String id);
  Future<FinancialGoalEntity> createGoal({
    required String name,
    String? description,
    required double targetAmount,
    DateTime? targetDate,
    String? color,
    String? priority,
  });
  Future<FinancialGoalEntity> addProgress(String id, double amount);
  Future<void> deleteGoal(String id);
}
