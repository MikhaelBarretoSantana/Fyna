import 'package:fyna/core/enums/risk_tolerance.dart';

class RiskProfileEntity {
  final String id;
  final RiskTolerance riskTolerance;
  final int investmentHorizonYears;
  final double? monthlyIncome;
  final double? monthlyExpenses;
  final double? emergencyFund;
  final double? totalInvestments;
  final int calculatedScore;
  final DateTime? lastAssessmentAt;
  final DateTime createdAt;

  const RiskProfileEntity({
    required this.id,
    required this.riskTolerance,
    required this.investmentHorizonYears,
    this.monthlyIncome,
    this.monthlyExpenses,
    this.emergencyFund,
    this.totalInvestments,
    required this.calculatedScore,
    this.lastAssessmentAt,
    required this.createdAt,
  });
}
