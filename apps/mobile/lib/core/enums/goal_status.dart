enum GoalStatus {
  IN_PROGRESS,
  COMPLETED,
  CANCELLED,
  PAUSED;

  String get label {
    switch (this) {
      case IN_PROGRESS:
        return 'Em andamento';
      case COMPLETED:
        return 'Concluída';
      case CANCELLED:
        return 'Cancelada';
      case PAUSED:
        return 'Pausada';
    }
  }

  String toJson() => name;

  static GoalStatus fromJson(String json) =>
      GoalStatus.values.firstWhere(
        (e) => e.name == json,
        orElse: () => IN_PROGRESS,
      );
}
