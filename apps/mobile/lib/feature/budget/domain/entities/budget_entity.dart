import 'package:fyna/core/enums/budget_period_type.dart';

class BudgetEntity {
  final String id;
  final String? categoryId;
  final String? categoryName;
  final String name;
  final double amountLimit;
  final double amountSpent;
  final double remainingAmount;
  final double percentUsed;
  final BudgetPeriodType periodType;
  final DateTime startDate;
  final DateTime endDate;
  final double? alertThreshold;
  final bool alertEnabled;
  final bool isActive;

  const BudgetEntity({
    required this.id,
    this.categoryId,
    this.categoryName,
    required this.name,
    required this.amountLimit,
    required this.amountSpent,
    required this.remainingAmount,
    required this.percentUsed,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    this.alertThreshold,
    this.alertEnabled = true,
    this.isActive = true,
  });
}
