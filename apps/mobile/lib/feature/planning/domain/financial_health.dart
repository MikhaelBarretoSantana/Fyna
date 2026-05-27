/// Calculadora pura de "Saúde Financeira".
///
/// Recebe agregados (receita, despesa, gastos recorrentes, total orçado e gasto)
/// e devolve três sub-scores 0–100 + score geral + label.
///
/// Lógica isolada da UI para ser facilmente testada e reutilizada.
///
/// Mantenha em sincronia com a documentação visual em PlanningPage.
class FinancialHealthCalculator {
  /// Receita total do período (entradas).
  final double income;

  /// Despesa total do período (saídas).
  final double expense;

  /// Soma dos compromissos recorrentes ATIVOS do tipo despesa (proxy de "dívida"
  /// / comprometimento fixo). Inclui aluguel, assinaturas, cartões, contas
  /// recorrentes etc.
  final double recurringExpenses;

  /// Limite total agregado dos orçamentos do período (soma de amountLimit).
  /// Quando nulo/0, o sub-score "Orçamento" cai no fallback de gasto/receita.
  final double budgetLimit;

  /// Soma do quanto já foi gasto dos orçamentos do período.
  final double budgetSpent;

  const FinancialHealthCalculator({
    required this.income,
    required this.expense,
    required this.recurringExpenses,
    this.budgetLimit = 0,
    this.budgetSpent = 0,
  });

  // ─── Reserva (taxa de poupança) ───────────────────────────────────────────
  // savingsRate = (income - expense) / income * 100
  // Faixas: ≥30% → 95 · ≥20% → 80 · ≥10% → 65 · ≥0% → 50 · <0% → 25
  double get savingsRate =>
      income > 0 ? ((income - expense) / income) * 100 : 0;

  int get reserveScore {
    if (income <= 0) return 50;
    final rate = savingsRate;
    if (rate >= 30) return 95;
    if (rate >= 20) return 80;
    if (rate >= 10) return 65;
    if (rate >= 0) return 50;
    return 25;
  }

  // ─── Orçamento (utilização) ───────────────────────────────────────────────
  // Se há orçamentos definidos, usa gasto/limite.
  // Caso contrário, usa gasto/receita como proxy.
  // Faixas: <0.6 → 95 · <0.8 → 80 · <1.0 → 60 · ≥1.0 → 30
  int get budgetScore {
    if (budgetLimit > 0) {
      final ratio = budgetSpent / budgetLimit;
      if (ratio < 0.6) return 95;
      if (ratio < 0.8) return 80;
      if (ratio < 1.0) return 60;
      return 30;
    }
    if (income <= 0) return 50;
    final ratio = expense / income;
    if (ratio < 0.6) return 95;
    if (ratio < 0.8) return 80;
    if (ratio < 1.0) return 60;
    return 30;
  }

  // ─── Dívidas (comprometimento) ────────────────────────────────────────────
  // ratio = recurringExpenses / income
  // Faixas: <0.3 → 95 · <0.5 → 80 · <0.7 → 60 · <0.9 → 40 · ≥0.9 → 20
  int get debtScore {
    if (income <= 0) return 50;
    final ratio = recurringExpenses / income;
    if (ratio < 0.3) return 95;
    if (ratio < 0.5) return 80;
    if (ratio < 0.7) return 60;
    if (ratio < 0.9) return 40;
    return 20;
  }

  // ─── Score geral ──────────────────────────────────────────────────────────
  int get overallScore =>
      ((reserveScore + budgetScore + debtScore) / 3).round();

  HealthLabel get label {
    final s = overallScore;
    if (s >= 80) return HealthLabel.excellent;
    if (s >= 60) return HealthLabel.good;
    if (s >= 40) return HealthLabel.regular;
    return HealthLabel.attention;
  }
}

enum HealthLabel {
  excellent('ÓTIMA'),
  good('BOA'),
  regular('REGULAR'),
  attention('ATENÇÃO');

  final String text;
  const HealthLabel(this.text);
}
