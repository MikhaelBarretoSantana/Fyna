import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/account/domain/entities/account_entity.dart';
import 'package:fyna/feature/transaction/domain/entities/transaction_entity.dart';
import 'package:fyna/feature/recurring/domain/entities/recurring_transaction_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/spending_pattern_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/spending_prediction_entity.dart';
import 'package:intl/intl.dart';

class PlanningPage extends StatefulWidget {
  final bool isDark;
  const PlanningPage({super.key, required this.isDark});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  List<AccountEntity> _accounts = [];
  List<TransactionEntity> _transactions = [];
  List<RecurringTransactionEntity> _recurring = [];
  List<SpendingPatternEntity> _patterns = [];
  List<SpendingPredictionEntity> _predictions = [];

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedPeriod = 'Mês';
  final _periods = ['Semana', 'Mês', 'Ano'];
  int _touchedPieIndex = -1;

  double get _totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);
  double get _totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);
  double get _savings => _totalIncome - _totalExpense;
  double get _savingsRate => _totalIncome > 0 ? (_savings / _totalIncome * 100) : 0;
  double get _totalBalance => _accounts
      .where((a) => a.isActive && a.includeInTotal)
      .fold(0.0, (s, a) => s + a.currentBalance);
  double get _recurringExpenses => _recurring
      .where((r) => r.isActive && r.type == TransactionType.expense)
      .fold(0.0, (s, r) => s + r.amount);
  double get _recurringIncome => _recurring
      .where((r) => r.isActive && r.type == TransactionType.income)
      .fold(0.0, (s, r) => s + r.amount);

  Map<String, _CatSpend> get _spendingByCategory {
    final map = <String, _CatSpend>{};
    for (final t in _transactions) {
      if (t.type != TransactionType.expense) continue;
      final key = t.categoryName ?? 'Sem categoria';
      map.update(key, (v) => _CatSpend(key, v.amount + t.amount, v.count + 1),
          ifAbsent: () => _CatSpend(key, t.amount, 1));
    }
    final entries = map.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
    if (entries.length > 6) {
      final top = entries.sublist(0, 5);
      final rest = entries.sublist(5);
      top.add(_CatSpend('Outros', rest.fold(0.0, (s, e) => s + e.amount),
          rest.fold(0, (s, e) => s + e.count)));
      return {for (final e in top) e.name: e};
    }
    return {for (final e in entries) e.name: e};
  }

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Semana': return DateTime(now.year, now.month, now.day - (now.weekday - 1));
      case 'Ano': return DateTime(now.year, 1, 1);
      default: return DateTime(now.year, now.month, 1);
    }
  }

  DateTime get _endDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Semana': return DateTime(now.year, now.month, now.day + (7 - now.weekday));
      case 'Ano': return DateTime(now.year, 12, 31);
      default: return DateTime(now.year, now.month + 1, 0);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final results = await Future.wait([
        Injection.instance.accountRepository.getAccounts(),
        Injection.instance.transactionRepository.getTransactions(
            page: 0, size: 200, startDate: _startDate, endDate: _endDate),
        Injection.instance.recurringRepository.getActiveRecurring(),
        _safeLoadPatterns(),
        _safeLoadPredictions(),
      ]);
      if (mounted) {
        setState(() {
          _accounts = results[0] as List<AccountEntity>;
          _transactions = (results[1] as dynamic).content as List<TransactionEntity>;
          _recurring = results[2] as List<RecurringTransactionEntity>;
          _patterns = results[3] as List<SpendingPatternEntity>;
          _predictions = results[4] as List<SpendingPredictionEntity>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _errorMessage = 'Erro ao carregar dados'; _isLoading = false; });
    }
  }

  Future<List<SpendingPatternEntity>> _safeLoadPatterns() async {
    try { return await Injection.instance.aiInsightsRepository.getActivePatterns(); } catch (_) { return []; }
  }
  Future<List<SpendingPredictionEntity>> _safeLoadPredictions() async {
    try { return await Injection.instance.aiInsightsRepository.getPredictions(); } catch (_) { return []; }
  }

  void _onPeriodChanged(String p) {
    if (_selectedPeriod == p) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedPeriod = p);
    _loadAllData();
  }

  static const _chartColors = [
    Color(0xFF3CADE8), Color(0xFFFF6B6B), Color(0xFF00D4AA),
    Color(0xFFFFB300), Color(0xFF7C83FD), Color(0xFFE91E63), Color(0xFF4CAF50),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildHeader(),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllData,
            color: isDark ? AppColors.darkAccent : AppColors.primary,
            child: _isLoading ? _buildShimmer() : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_errorMessage != null) _buildError(),
                _buildOverview(),
                const SizedBox(height: 20),
                if (_spendingByCategory.isNotEmpty) ...[
                  _sectionTitle('Gastos por categoria', _selectedPeriod),
                  const SizedBox(height: 10),
                  _buildCategoryChart(),
                  const SizedBox(height: 20),
                ],
                if (_recurring.isNotEmpty) ...[
                  _sectionTitle('Custos fixos', '${_recurring.length}'),
                  const SizedBox(height: 10),
                  _buildRecurring(),
                  const SizedBox(height: 20),
                ],
                if (_predictions.isNotEmpty) ...[
                  _sectionTitle('Previsões IA', '${_predictions.length}'),
                  const SizedBox(height: 10),
                  _buildPredictions(),
                  const SizedBox(height: 20),
                ],
                if (_patterns.isNotEmpty) ...[
                  _sectionTitle('Padrões detectados', '${_patterns.length}'),
                  const SizedBox(height: 10),
                  _buildPatterns(),
                  const SizedBox(height: 20),
                ],
                _sectionTitle('Ferramentas', ''),
                const SizedBox(height: 10),
                _buildQuickActions(),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final fmt = DateFormat("dd MMM", 'pt_BR');
    final fmtFull = DateFormat("dd MMM yyyy", 'pt_BR');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Planejamento', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text('${fmt.format(_startDate)} — ${fmtFull.format(_endDate)}',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
        ])),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C2E) : const Color(0xFFEEEEF2),
            borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: _periods.map((p) {
            final sel = _selectedPeriod == p;
            return GestureDetector(
              onTap: () => _onPeriodChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? (isDark ? AppColors.darkAccent : AppColors.primary) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10)),
                child: Text(p, style: TextStyle(fontSize: 12,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? Colors.white : (isDark ? Colors.white38 : Colors.black45)))));
          }).toList()),
        ),
      ]),
    );
  }

  Widget _buildOverview() {
    final savingsColor = _savings >= 0 ? AppColors.success : AppColors.error;
    final rateColor = _savingsRate >= 20 ? AppColors.success : _savingsRate >= 0 ? AppColors.warning : AppColors.error;
    final ratio = _totalIncome > 0 ? (_totalExpense / _totalIncome).clamp(0.0, 1.5) : 0.0;
    final isOver = ratio > 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark ? [const Color(0xFF1A2A3E), const Color(0xFF0F1B2D)]
                : [AppColors.primaryDark, AppColors.primary]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: (isDark ? Colors.black : AppColors.primaryDark).withValues(alpha: 0.25),
            blurRadius: 16, offset: const Offset(0, 6))]),
      child: Column(children: [
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Patrimônio total', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
            const SizedBox(height: 4),
            Text(_fmtCurrency(_totalBalance), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Text('${_savingsRate.toStringAsFixed(0)}%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: rateColor)),
              Text('poupança', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5))),
            ])),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _metric('Receitas', _fmtShort(_totalIncome), Icons.arrow_upward_rounded, AppColors.success.withValues(alpha: 0.7))),
          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.1)),
          Expanded(child: _metric('Despesas', _fmtShort(_totalExpense), Icons.arrow_downward_rounded, AppColors.error.withValues(alpha: 0.7))),
          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.1)),
          Expanded(child: _metric('Economia', _fmtShort(_savings.abs()), _savings >= 0 ? Icons.savings_rounded : Icons.warning_rounded, savingsColor.withValues(alpha: 0.7), prefix: _savings < 0 ? '-' : '+')),
        ]),
        if (_totalIncome > 0) ...[
          const SizedBox(height: 16),
          Row(children: [
            Text(isOver ? 'Gastou mais que ganhou' : 'Uso da receita', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
            const Spacer(),
            Text('${(ratio * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: isOver ? AppColors.error.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.6))),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: SizedBox(height: 6, child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(isOver ? AppColors.error.withValues(alpha: 0.8)
                : ratio > 0.8 ? AppColors.warning.withValues(alpha: 0.8) : AppColors.success.withValues(alpha: 0.6))))),
        ],
      ]),
    );
  }

  Widget _metric(String label, String value, IconData icon, Color color, {String? prefix}) {
    return Column(children: [
      Icon(icon, size: 16, color: color), const SizedBox(height: 6),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5))),
      const SizedBox(height: 2),
      Text(prefix != null ? '$prefix $value' : value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
    ]);
  }

  Widget _buildCategoryChart() {
    final cats = _spendingByCategory.values.toList();
    final total = cats.fold(0.0, (s, c) => s + c.amount);
    return Container(padding: const EdgeInsets.all(20), decoration: _card(), child: Column(children: [
      SizedBox(height: 200, child: Row(children: [
        Expanded(flex: 3, child: PieChart(PieChartData(
          pieTouchData: PieTouchData(touchCallback: (event, resp) {
            setState(() { _touchedPieIndex = (!event.isInterestedForInteractions || resp?.touchedSection == null)
                ? -1 : resp!.touchedSection!.touchedSectionIndex; });
          }),
          sectionsSpace: 2, centerSpaceRadius: 36,
          sections: cats.asMap().entries.map((e) {
            final i = e.key; final c = e.value; final touched = i == _touchedPieIndex;
            return PieChartSectionData(value: c.amount,
                title: touched ? '${(c.amount / total * 100).toStringAsFixed(0)}%' : '',
                color: _chartColors[i % _chartColors.length], radius: touched ? 52 : 44,
                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white));
          }).toList()))),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cats.asMap().entries.map((e) {
            final i = e.key; final c = e.value;
            return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(
                  color: _chartColors[i % _chartColors.length], borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              Expanded(child: Text(c.name, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text('${(c.amount / total * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : Colors.black38)),
            ]));
          }).toList())),
      ])),
      const SizedBox(height: 12),
      ...cats.take(3).toList().asMap().entries.map((e) {
        final i = e.key; final c = e.value; final r = total > 0 ? c.amount / total : 0.0;
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(
              color: _chartColors[i % _chartColors.length], borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Expanded(child: Text(c.name, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textPrimary))),
          Text(_fmtCurrency(c.amount), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(width: 8),
          SizedBox(width: 50, child: ClipRRect(borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: r, backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(_chartColors[i % _chartColors.length]), minHeight: 4))),
        ]));
      }),
    ]));
  }

  Widget _buildRecurring() {
    final net = _recurringIncome - _recurringExpenses;
    final upcoming = _recurring.where((r) => r.isActive && r.nextOccurrence != null
        && r.nextOccurrence!.difference(DateTime.now()).inDays <= 7
        && !r.nextOccurrence!.isBefore(DateTime.now())).toList()
      ..sort((a, b) => a.nextOccurrence!.compareTo(b.nextOccurrence!));

    return Container(padding: const EdgeInsets.all(16), decoration: _card(), child: Column(children: [
      Row(children: [
        _miniMetric('Despesas fixas', _recurringExpenses, AppColors.error),
        const SizedBox(width: 10),
        _miniMetric('Receitas fixas', _recurringIncome, AppColors.success),
        const SizedBox(width: 10),
        _miniMetric('Saldo fixo', net.abs(), net >= 0 ? AppColors.success : AppColors.error, prefix: net >= 0 ? '+' : '-'),
      ]),
      if (upcoming.isNotEmpty) ...[
        const SizedBox(height: 14),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Próximas 7 dias', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : Colors.black38)),
            const SizedBox(height: 6),
            ...upcoming.take(3).map((r) {
              final isExp = r.type == TransactionType.expense;
              final days = r.nextOccurrence!.difference(DateTime.now()).inDays;
              return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
                Icon(Icons.repeat_rounded, size: 14, color: isExp ? AppColors.error.withValues(alpha: 0.6) : AppColors.success.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Expanded(child: Text(r.description, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(days == 0 ? 'Hoje' : days == 1 ? 'Amanhã' : 'Em $days dias',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: days <= 1 ? AppColors.warning : (isDark ? Colors.white38 : Colors.black38))),
                const SizedBox(width: 8),
                Text('${isExp ? '-' : '+'} ${_fmtShort(r.amount)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: isExp ? AppColors.error : AppColors.success)),
              ]));
            }),
          ])),
      ],
      const SizedBox(height: 10),
      GestureDetector(onTap: () => Navigator.pushNamed(context, AppRoutes.recurring),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Ver todas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkAccent : AppColors.primary)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppColors.darkAccent : AppColors.primary),
        ])),
    ]));
  }

  Widget _miniMetric(String label, double value, Color color, {String? prefix}) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: isDark ? 0.08 : 0.05), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, child: Text(
            prefix != null ? '$prefix ${_fmtShort(value)}' : _fmtShort(value),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color))),
      ])));
  }

  Widget _buildPredictions() {
    return Container(padding: const EdgeInsets.all(16), decoration: _card(), child: Column(children: [
      ..._predictions.take(4).map((p) {
        final acc = p.accuracyPercent;
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(
              color: (isDark ? AppColors.darkAccent : AppColors.primary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.auto_graph_rounded, size: 16, color: isDark ? AppColors.darkAccent : AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.categoryName ?? 'Categoria', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimary)),
            Text('Previsto: ${_fmtShort(p.predictedAmount)}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.black38)),
          ])),
          if (acc != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: (acc >= 80 ? AppColors.success : acc >= 50 ? AppColors.warning : AppColors.error).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6)),
            child: Text('${acc.toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: acc >= 80 ? AppColors.success : acc >= 50 ? AppColors.warning : AppColors.error))),
        ]));
      }),
      GestureDetector(onTap: () => Navigator.pushNamed(context, AppRoutes.aiInsights),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Ver AI Insights', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkAccent : AppColors.primary)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppColors.darkAccent : AppColors.primary),
        ])),
    ]));
  }

  Widget _buildPatterns() {
    return Column(children: _patterns.take(3).map((p) {
      final cfg = _patternCfg(p.patternType);
      return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: _card(),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(
              color: cfg.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(cfg.icon, color: cfg.color, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: cfg.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(cfg.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: cfg.color))),
            const SizedBox(height: 4),
            Text(p.description, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textPrimary, height: 1.3),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
        ]));
    }).toList());
  }

  _PCfg _patternCfg(String t) {
    switch (t) {
      case 'RECURRING': return _PCfg('Recorrente', Icons.replay_rounded, const Color(0xFF3CADE8));
      case 'INCREASING': return _PCfg('Em alta', Icons.trending_up_rounded, AppColors.warning);
      case 'DECREASING': return _PCfg('Em queda', Icons.trending_down_rounded, AppColors.success);
      case 'SEASONAL': return _PCfg('Sazonal', Icons.wb_sunny_rounded, const Color(0xFFE8893C));
      case 'ANOMALY': return _PCfg('Anomalia', Icons.warning_amber_rounded, AppColors.error);
      default: return _PCfg(t, Icons.insights_rounded, const Color(0xFF7C5CFC));
    }
  }

  Widget _buildQuickActions() {
    final actions = [
      _QA('Orçamentos', Icons.bar_chart_rounded, const Color(0xFFE85D5D), AppRoutes.budgets),
      _QA('Metas', Icons.flag_rounded, const Color(0xFFE8893C), AppRoutes.goals),
      _QA('AI Insights', Icons.smart_toy_rounded, const Color(0xFF7C5CFC), AppRoutes.aiInsights),
      _QA('Recorrentes', Icons.repeat_rounded, const Color(0xFF5CB85C), AppRoutes.recurring),
    ];
    return Row(children: actions.map((a) {
      return Expanded(child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); Navigator.pushNamed(context, a.route); },
        child: Container(
          margin: EdgeInsets.only(right: a == actions.last ? 0 : 8),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF14142A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: a.color.withValues(alpha: isDark ? 0.15 : 0.1))),
          child: Column(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(
                color: a.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(a.icon, color: a.color, size: 20)),
            const SizedBox(height: 8),
            Text(a.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.black54), textAlign: TextAlign.center),
          ]))));
    }).toList());
  }

  Widget _sectionTitle(String title, String badge) {
    return Row(children: [
      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
      if (badge.isNotEmpty) ...[const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
          child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white30 : Colors.black38)))],
    ]);
  }

  Widget _buildError() {
    return Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2))),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18), const SizedBox(width: 8),
        Expanded(child: Text(_errorMessage!, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87))),
        GestureDetector(onTap: _loadAllData, child: const Icon(Icons.refresh_rounded, color: AppColors.error, size: 18)),
      ]));
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), child: Column(children: [
        Container(height: 200, decoration: BoxDecoration(color: isDark ? const Color(0xFF1A2A3E) : const Color(0xFFD0E8EF), borderRadius: BorderRadius.circular(24))),
        const SizedBox(height: 20),
        Container(height: 260, decoration: BoxDecoration(color: isDark ? const Color(0xFF14142A) : const Color(0xFFEEEEF2), borderRadius: BorderRadius.circular(18))),
        const SizedBox(height: 20),
        Container(height: 120, decoration: BoxDecoration(color: isDark ? const Color(0xFF14142A) : const Color(0xFFEEEEF2), borderRadius: BorderRadius.circular(18))),
      ]));
  }

  BoxDecoration _card() => BoxDecoration(color: isDark ? const Color(0xFF14142A) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEF2)));

  String _fmtCurrency(double v) {
    final f = v.abs().toStringAsFixed(2).replaceAll('.', ',');
    final p = f.split(',');
    final i = p[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $i,${p[1]}';
  }
  String _fmtShort(double v) {
    if (v.abs() >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return 'R\$ ${(v / 1000).toStringAsFixed(1)}k';
    return _fmtCurrency(v);
  }
}

class _CatSpend { final String name; final double amount; final int count; const _CatSpend(this.name, this.amount, this.count); }
class _PCfg { final String label; final IconData icon; final Color color; const _PCfg(this.label, this.icon, this.color); }
class _QA { final String label; final IconData icon; final Color color; final String route; const _QA(this.label, this.icon, this.color, this.route); }