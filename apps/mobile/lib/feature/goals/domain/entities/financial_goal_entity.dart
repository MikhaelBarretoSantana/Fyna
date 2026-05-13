import 'package:fyna/core/enums/goal_status.dart';

class FinancialGoalEntity {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final double targetAmount;
  final double currentAmount;
  final double progressPercent;
  final DateTime? targetDate;
  final GoalStatus status;
  final int? priority;
  final DateTime? completedAt;
  final DateTime createdAt;

  const FinancialGoalEntity({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.targetAmount,
    required this.currentAmount,
    required this.progressPercent,
    this.targetDate,
    required this.status,
    this.priority,
    this.completedAt,
    required this.createdAt,
  });
}
