enum NotificationType {
  BUDGET_ALERT,
  GOAL_REACHED,
  RECURRING_REMINDER,
  AI_INSIGHT,
  SYSTEM,
  WEEKLY_SUMMARY;

  String get label {
    switch (this) {
      case BUDGET_ALERT:
        return 'Alerta de Orçamento';
      case GOAL_REACHED:
        return 'Meta Atingida';
      case RECURRING_REMINDER:
        return 'Lembrete Recorrente';
      case AI_INSIGHT:
        return 'Insight de IA';
      case SYSTEM:
        return 'Sistema';
      case WEEKLY_SUMMARY:
        return 'Resumo Semanal';
    }
  }

  String toJson() => name;

  static NotificationType fromJson(String json) =>
      NotificationType.values.firstWhere(
        (e) => e.name == json,
        orElse: () => SYSTEM,
      );
}
