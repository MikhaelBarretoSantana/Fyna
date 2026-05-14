/// Tipos de notificação — espelha `NotificationType` do backend.
enum NotificationType {
  BUDGET_ALERT,
  GOAL_PROGRESS,
  GOAL_COMPLETED,
  BILL_REMINDER,
  RECURRING_TRANSACTION,
  AI_INSIGHT,
  SPENDING_ANOMALY,
  INVESTMENT_RECOMMENDATION,
  WEEKLY_SUMMARY,
  SYSTEM,
  SECURITY;

  String get label {
    switch (this) {
      case BUDGET_ALERT:
        return 'Alerta de Orçamento';
      case GOAL_PROGRESS:
        return 'Progresso da Meta';
      case GOAL_COMPLETED:
        return 'Meta Atingida';
      case BILL_REMINDER:
        return 'Conta a Pagar';
      case RECURRING_TRANSACTION:
        return 'Transação Recorrente';
      case AI_INSIGHT:
        return 'Insight de IA';
      case SPENDING_ANOMALY:
        return 'Gasto Atípico';
      case INVESTMENT_RECOMMENDATION:
        return 'Recomendação de Investimento';
      case WEEKLY_SUMMARY:
        return 'Resumo Semanal';
      case SYSTEM:
        return 'Sistema';
      case SECURITY:
        return 'Segurança';
    }
  }

  String toJson() => name;

  static NotificationType fromJson(String json) =>
      NotificationType.values.firstWhere(
        (e) => e.name == json,
        orElse: () => SYSTEM,
      );
}
