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

  factory BudgetEntity.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    return BudgetEntity(
      id: json['id'].toString(),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName'] as String?,
      name: json['name'] as String,
      amountLimit: asDouble(json['amountLimit']),
      amountSpent: asDouble(json['amountSpent']),
      remainingAmount: asDouble(json['remainingAmount']),
      percentUsed: asDouble(json['percentUsed']),
      periodType: BudgetPeriodType.fromJson(json['periodType'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      alertThreshold: json['alertThreshold'] == null
          ? null
          : asDouble(json['alertThreshold']),
      alertEnabled: json['alertEnabled'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
