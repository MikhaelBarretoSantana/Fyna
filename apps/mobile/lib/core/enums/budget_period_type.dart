enum BudgetPeriodType {
  DAILY,
  WEEKLY,
  BIWEEKLY,
  MONTHLY,
  QUARTERLY,
  SEMIANNUALLY,
  ANNUALLY;

  String get label {
    switch (this) {
      case DAILY:
        return 'Diário';
      case WEEKLY:
        return 'Semanal';
      case BIWEEKLY:
        return 'Quinzenal';
      case MONTHLY:
        return 'Mensal';
      case QUARTERLY:
        return 'Trimestral';
      case SEMIANNUALLY:
        return 'Semestral';
      case ANNUALLY:
        return 'Anual';
    }
  }

  String toJson() => name;

  static BudgetPeriodType fromJson(String json) =>
      BudgetPeriodType.values.firstWhere(
        (e) => e.name == json,
        orElse: () => MONTHLY,
      );
}
