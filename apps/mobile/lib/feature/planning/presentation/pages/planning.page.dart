import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_screen_header.dart';
import 'package:fyna/core/widgets/hero_gradient_card.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
import 'package:fyna/feature/ai_classification/domain/entities/spending_pattern_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/spending_prediction_entity.dart';
import 'package:fyna/feature/budget/domain/entities/budget_entity.dart';
import 'package:fyna/feature/goals/domain/entities/financial_goal_entity.dart';
import 'package:fyna/feature/planning/domain/financial_health.dart';
import 'package:fyna/feature/recurring/domain/entities/recurring_transaction_entity.dart';
import 'package:fyna/feature/transaction/domain/entities/transaction_entity.dart';
import 'package:intl/intl.dart';

class PlanningPage extends StatefulWidget {
  final bool isDark;
  const PlanningPage({super.key, required this.isDark});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  List<TransactionEntity> _transactions = [];
  List<RecurringTransactionEntity> _recurring = [];
  List<SpendingPatternEntity> _patterns = [];
  List<SpendingPredictionEntity> _predictions = [];
  List<FinancialGoalEntity> _goals = [];
  List<BudgetEntity> _budgets = [];

  bool _isLoading = true;
  String? _errorMessage;

  // Período fixo no mês corrente (alinhado ao design)
  DateTime get _startDate => DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime get _endDate =>
      DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  double get _totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);
  double get _totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);
  double get _savings => _totalIncome - _totalExpense;
  double get _savingsRate =>
      _totalIncome > 0 ? (_savings / _totalIncome * 100) : 0;
  double get _recurringExpenses => _recurring
      .where((r) => r.isActive && r.type == TransactionType.expense)
      .fold(0.0, (s, r) => s + r.amount);
  double get _recurringIncome => _recurring
      .where((r) => r.isActive && r.type == TransactionType.income)
      .fold(0.0, (s, r) => s + r.amount);
  double get _recurringNet => _recurringIncome - _recurringExpenses;

  double get _goalsAccumulated =>
      _goals.fold(0.0, (s, g) => s + g.currentAmount);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        Injection.instance.transactionRepository.getTransactions(
            page: 0, size: 200, startDate: _startDate, endDate: _endDate),
        Injection.instance.recurringRepository.getActiveRecurring(),
        _safeLoadPatterns(),
        _safeLoadPredictions(),
        _safeLoadGoals(),
        _safeLoadBudgets(),
      ]);
      if (!mounted) return;
      setState(() {
        _transactions =
            (results[0] as dynamic).content as List<TransactionEntity>;
        _recurring = results[1] as List<RecurringTransactionEntity>;
        _patterns = results[2] as List<SpendingPatternEntity>;
        _predictions = results[3] as List<SpendingPredictionEntity>;
        _goals = results[4] as List<FinancialGoalEntity>;
        _budgets = results[5] as List<BudgetEntity>;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar dados';
          _isLoading = false;
        });
      }
    }
  }

  Future<List<SpendingPatternEntity>> _safeLoadPatterns() async {
    try {
      return await Injection.instance.aiInsightsRepository.getActivePatterns();
    } catch (_) {
      return [];
    }
  }

  Future<List<SpendingPredictionEntity>> _safeLoadPredictions() async {
    try {
      return await Injection.instance.aiInsightsRepository.getPredictions();
    } catch (_) {
      return [];
    }
  }

  Future<List<FinancialGoalEntity>> _safeLoadGoals() async {
    try {
      return await Injection.instance.goalRepository.getGoals();
    } catch (_) {
      return [];
    }
  }

  Future<List<BudgetEntity>> _safeLoadBudgets() async {
    try {
      return await Injection.instance.budgetRepository.getCurrentBudgets();
    } catch (_) {
      return [];
    }
  }

  // ─── Cálculo de saúde financeira (delegado para a classe pura) ───
  FinancialHealthCalculator get _health => FinancialHealthCalculator(
        income: _totalIncome,
        expense: _totalExpense,
        recurringExpenses: _recurringExpenses,
        budgetLimit: _budgetLimit,
        budgetSpent: _budgetSpent,
      );

  int get _reserveScore => _health.reserveScore;
  int get _budgetScore => _health.budgetScore;
  int get _debtScore => _health.debtScore;
  int get _healthScore => _health.overallScore;

  ({String label, Color color}) get _healthLabel {
    final tc = ThemeColors.of(context);
    switch (_health.label) {
      case HealthLabel.excellent:
        return (label: HealthLabel.excellent.text, color: tc.neoPositive);
      case HealthLabel.good:
        return (label: HealthLabel.good.text, color: const Color(0xFF6BE3B0));
      case HealthLabel.regular:
        return (label: HealthLabel.regular.text, color: tc.neoAttention);
      case HealthLabel.attention:
        return (label: HealthLabel.attention.text, color: tc.neoNegative);
    }
  }

  String get _aiSuggestion {
    if (_patterns.isNotEmpty) {
      final top = _patterns.first;
      return top.description;
    }
    if (_savingsRate < 10) {
      return 'Você está economizando pouco. Reveja seus gastos fixos para aumentar a reserva.';
    }
    if (_totalExpense > _totalIncome) {
      return 'Gastos acima da receita este mês. Considere ajustar despesas variáveis.';
    }
    return 'Mantenha o ritmo de economia para alcançar suas metas mais rápido.';
  }

  String get _aiSuggestionTitle {
    if (_savingsRate >= 20) return 'Você está no caminho certo!';
    if (_savingsRate >= 10) return 'Pode melhorar sua poupança';
    return 'Aumente sua reserva';
  }

  String get _monthLabel {
    return toBeginningOfSentenceCase(
            DateFormat('MMMM', 'pt_BR').format(_startDate)) ??
        '';
  }

  String _fmtCurrency(double v) {
    final f = v.abs().toStringAsFixed(2).replaceAll('.', ',');
    final p = f.split(',');
    final i = p[0]
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $i,${p[1]}';
  }

  String _fmtShort(double v) {
    if (v.abs() >= 1000000) {
      return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (v.abs() >= 1000) {
      return 'R\$ ${(v / 1000).toStringAsFixed(1)}k';
    }
    return _fmtCurrency(v);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Column(
      children: [
        AppScreenHeader(
          title: 'Planejamento',
          subtitle: '$_monthLabel · seu plano financeiro',
          showBack: false,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllData,
            color: tc.neoTeal,
            child: _isLoading
                ? _buildShimmer(tc)
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) _buildError(tc),
                        _buildHealthCard(tc),
                        const SizedBox(height: 14),
                        _buildSummaryGrid(tc),
                        const SizedBox(height: 14),
                        _buildAiInsight(tc),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthCard(ThemeColors tc) {
    final health = _healthLabel;
    return HeroGradientCard(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAÚDE FINANCEIRA',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_healthScore',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '/100',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: health.color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  health.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: health.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(label: 'Reserva', score: _reserveScore),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(label: 'Orçamento', score: _budgetScore),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(label: 'Dívidas', score: _debtScore),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double get _budgetSpent =>
      _budgets.fold(0.0, (s, b) => s + b.amountSpent);
  double get _budgetLimit =>
      _budgets.fold(0.0, (s, b) => s + b.amountLimit);

  Widget _buildSummaryGrid(ThemeColors tc) {
    final hasBudgets = _budgets.isNotEmpty;
    final budgetSubtitle = hasBudgets
        ? '${_budgets.length} ${_budgets.length == 1 ? 'categoria' : 'categorias'}'
        : 'Crie seu primeiro';
    final budgetValueText = hasBudgets
        ? '${_fmtShort(_budgetSpent)} / ${_fmtShort(_budgetLimit)}'
        : 'Configurar →';
    final budgetOver = hasBudgets && _budgetSpent > _budgetLimit;
    final budgetValueColor = !hasBudgets
        ? tc.neoTeal
        : budgetOver
            ? tc.neoNegative
            : tc.neoText;

    final goalsSubtitle =
        _goals.isNotEmpty ? '${_goals.length} ativas' : 'Sem metas';
    final recurringSubtitle = _recurring.isNotEmpty
        ? '${_recurring.length} ativas'
        : 'Sem recorrências';
    final aiSubtitle = (_predictions.length + _patterns.length) > 0
        ? '${_predictions.length + _patterns.length} novos'
        : 'Nenhum insight';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _SummaryGridCard(
          icon: Icons.pie_chart_rounded,
          tone: 'danger',
          title: 'Orçamentos',
          subtitle: budgetSubtitle,
          valueText: budgetValueText,
          valueColor: budgetValueColor,
          isLink: !hasBudgets,
          onTap: () async {
            await Navigator.pushNamed(context, AppRoutes.budgets);
            if (mounted) _loadAllData();
          },
        ),
        _SummaryGridCard(
          icon: Icons.flag_rounded,
          tone: 'transport',
          title: 'Metas',
          subtitle: goalsSubtitle,
          valueText: _fmtShort(_goalsAccumulated),
          valueColor: tc.neoText,
          onTap: () => Navigator.pushNamed(context, AppRoutes.goals),
        ),
        _SummaryGridCard(
          icon: Icons.repeat_rounded,
          tone: 'info',
          title: 'Recorrências',
          subtitle: recurringSubtitle,
          valueText:
              '${_recurringNet >= 0 ? '+' : '-'}${_fmtShort(_recurringNet.abs())}/mês',
          valueColor: _recurringNet >= 0 ? tc.neoPositive : tc.neoNegative,
          onTap: () => Navigator.pushNamed(context, AppRoutes.recurring),
        ),
        _SummaryGridCard(
          icon: Icons.auto_awesome_rounded,
          tone: 'ai',
          title: 'AI Insights',
          subtitle: aiSubtitle,
          valueText: 'Ver análise',
          valueColor: tc.neoAi,
          isLink: true,
          onTap: () => Navigator.pushNamed(context, AppRoutes.aiInsights),
        ),
      ],
    );
  }

  Widget _buildAiInsight(ThemeColors tc) {
    return Material(
      color: tc.badge('warning').bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiInsights),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(
                icon: Icons.notifications_rounded,
                tone: 'warning',
                background: Colors.white.withValues(
                  alpha: tc.isDark ? 0.06 : 0.6,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _aiSuggestionTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tc.neoText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _aiSuggestion,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: tc.neoTextMuted,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeColors tc) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tc.neoNegative.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tc.neoNegative.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: tc.neoNegative, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(fontSize: 13, color: tc.neoText),
            ),
          ),
          GestureDetector(
            onTap: _loadAllData,
            child:
                Icon(Icons.refresh_rounded, color: tc.neoNegative, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(ThemeColors tc) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: tc.heroGradient,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: List.generate(
              4,
              (_) => Container(
                decoration: BoxDecoration(
                  color: tc.neoCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: tc.neoCardBorder),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: tc.neoCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tc.neoCardBorder),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final int score;

  const _MiniMetric({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    final value = (score.clamp(0, 100)) / 100.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(
                Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGridCard extends StatelessWidget {
  final IconData icon;
  final String tone;
  final String title;
  final String subtitle;
  final String valueText;
  final Color valueColor;
  final bool isLink;
  final VoidCallback onTap;

  const _SummaryGridCard({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.valueText,
    required this.valueColor,
    this.isLink = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Material(
      color: tc.neoCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tc.neoCardBorder),
            boxShadow: [
              BoxShadow(
                color: tc.neoCardShadow,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBadge(icon: icon, tone: tone, size: 36, iconSize: 18),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: tc.neoTextFaint,
                    size: 20,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tc.neoText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: tc.neoTextMuted,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  valueText,
                  style: TextStyle(
                    fontSize: isLink ? 13 : 15,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
