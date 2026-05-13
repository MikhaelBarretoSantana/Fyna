enum RecurringFrequency {
  DAILY,
  WEEKLY,
  BIWEEKLY,
  MONTHLY,
  BIMONTHLY,
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
      case BIMONTHLY:
        return 'Bimestral';
      case QUARTERLY:
        return 'Trimestral';
      case SEMIANNUALLY:
        return 'Semestral';
      case ANNUALLY:
        return 'Anual';
    }
  }

  String toJson() => name;

  static RecurringFrequency fromJson(String json) =>
      RecurringFrequency.values.firstWhere(
        (e) => e.name == json,
        orElse: () => MONTHLY,
      );
}
