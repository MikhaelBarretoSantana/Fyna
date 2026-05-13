enum RiskTolerance {
  CONSERVATIVE,
  MODERATELY_CONSERVATIVE,
  MODERATE,
  MODERATELY_AGGRESSIVE,
  AGGRESSIVE;

  String get label {
    switch (this) {
      case CONSERVATIVE:
        return 'Conservador';
      case MODERATELY_CONSERVATIVE:
        return 'Moderadamente Conservador';
      case MODERATE:
        return 'Moderado';
      case MODERATELY_AGGRESSIVE:
        return 'Moderadamente Agressivo';
      case AGGRESSIVE:
        return 'Agressivo';
    }
  }

  String toJson() => name;

  static RiskTolerance fromJson(String json) =>
      RiskTolerance.values.firstWhere(
        (e) => e.name == json,
        orElse: () => MODERATE,
      );
}
