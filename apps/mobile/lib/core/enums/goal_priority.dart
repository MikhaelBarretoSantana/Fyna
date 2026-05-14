enum GoalPriority {
  LOW,
  MEDIUM,
  HIGH;

  String get label {
    switch (this) {
      case LOW:
        return 'Baixa';
      case MEDIUM:
        return 'Média';
      case HIGH:
        return 'Alta';
    }
  }

  String toJson() => name;

  static GoalPriority fromJson(String json) => GoalPriority.values.firstWhere(
        (e) => e.name == json,
        orElse: () => LOW,
      );
}
