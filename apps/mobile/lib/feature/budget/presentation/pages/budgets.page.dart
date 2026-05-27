import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_list_item.dart';
import 'package:fyna/core/widgets/app_screen_header.dart';
import 'package:fyna/core/widgets/hero_gradient_card.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
import 'package:fyna/feature/budget/domain/entities/budget_entity.dart';
import 'package:intl/intl.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  List<BudgetEntity> _budgets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    if (!_isLoading) setState(() => _isLoading = true);
    setState(() => _errorMessage = null);
    try {
      // /budgets/current devolve só os do período atual com gastos calculados
      final budgets =
          await Injection.instance.budgetRepository.getCurrentBudgets();
      if (!mounted) return;
      setState(() {
        _budgets = budgets;
        _isLoading = false;
      });
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } on NetworkException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sem conexão com a internet';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar orçamentos';
          _isLoading = false;
        });
      }
    }
  }

  double get _totalLimit =>
      _budgets.fold(0.0, (sum, b) => sum + b.amountLimit);
  double get _totalSpent =>
      _budgets.fold(0.0, (sum, b) => sum + b.amountSpent);

  Future<bool> _deleteBudget(BudgetEntity budget) async {
    final confirmed = await _confirmDelete(budget);
    if (confirmed != true) return false;
    try {
      await Injection.instance.budgetRepository.deleteBudget(budget.id);
      if (!mounted) return true;
      setState(() => _budgets.removeWhere((b) => b.id == budget.id));
      _snack('Orçamento "${budget.name}" excluído', isError: false);
      return true;
    } on ServerException catch (e) {
      _snack(e.message);
      return false;
    } on NetworkException {
      _snack('Sem conexão com a internet');
      return false;
    } catch (_) {
      _snack('Erro ao excluir orçamento');
      return false;
    }
  }

  Future<bool?> _confirmDelete(BudgetEntity budget) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        return AlertDialog(
          backgroundColor: tc.neoCardElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: IconBadge(
            icon: Icons.delete_outline_rounded,
            tone: 'danger',
            size: 56,
            iconSize: 26,
            radius: 16,
          ),
          title: Text(
            'Excluir orçamento?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tc.neoText,
            ),
          ),
          content: Text(
            'O orçamento "${budget.name}" de ${_fmtCurrency(budget.amountLimit)} '
            'será excluído. Transações registradas não serão afetadas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: tc.neoTextMuted,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: tc.neoTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: tc.neoNegative,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Excluir',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _snack(String message, {bool isError = true}) {
    if (!mounted) return;
    final tc = ThemeColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? tc.neoNegative : tc.neoPositive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showActions(BudgetEntity budget) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              color: tc.neoCardElevated,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tc.neoTextFaint.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  budget.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tc.neoText,
                  ),
                ),
                Text(
                  '${_fmtCurrency(budget.amountSpent)} de ${_fmtCurrency(budget.amountLimit)} · '
                  '${budget.percentUsed.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12.5, color: tc.neoTextMuted),
                ),
                const SizedBox(height: 16),
                AppListItem(
                  leading: const IconBadge(
                    icon: Icons.edit_rounded,
                    tone: 'info',
                  ),
                  title: 'Editar limite',
                  subtitle: 'Alterar valor e alerta',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditSheet(budget);
                  },
                ),
                const SizedBox(height: 8),
                AppListItem(
                  leading: const IconBadge(
                    icon: Icons.delete_outline_rounded,
                    tone: 'danger',
                  ),
                  title: 'Excluir orçamento',
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteBudget(budget);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditSheet(BudgetEntity budget) {
    final limitController = TextEditingController(
      text: budget.amountLimit.toStringAsFixed(2).replaceAll('.', ','),
    );
    final thresholdController = TextEditingController(
      text: (budget.alertThreshold ?? 80).toStringAsFixed(0),
    );
    bool alertEnabled = budget.alertEnabled;
    bool submitting = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: BoxDecoration(
                  color: tc.neoCardElevated,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: tc.neoTextFaint.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Editar orçamento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: tc.neoText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        budget.name,
                        style:
                            TextStyle(fontSize: 13, color: tc.neoTextMuted),
                      ),
                      const SizedBox(height: 16),
                      _editFieldLabel(tc, 'LIMITE'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: limitController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: tc.neoText,
                        ),
                        decoration: _editInputDecoration(tc, prefix: 'R\$  '),
                        validator: (v) {
                          final value = _parseAmount(v ?? '');
                          if (value == null || value <= 0) {
                            return 'Valor inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Alerta de uso',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: tc.neoText,
                              ),
                            ),
                          ),
                          Switch(
                            value: alertEnabled,
                            onChanged: (v) =>
                                setSheetState(() => alertEnabled = v),
                            activeTrackColor: tc.neoTeal,
                          ),
                        ],
                      ),
                      if (alertEnabled) ...[
                        const SizedBox(height: 8),
                        _editFieldLabel(tc, 'LIMITE DE ALERTA (%)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: thresholdController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 15,
                            color: tc.neoText,
                          ),
                          decoration: _editInputDecoration(tc),
                          validator: (v) {
                            if (!alertEnabled) return null;
                            final t = _parseAmount(v ?? '');
                            if (t == null || t <= 0 || t > 100) {
                              return 'Entre 1 e 100';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  setSheetState(() => submitting = true);
                                  final ok = await _updateBudget(
                                    budget: budget,
                                    limit: _parseAmount(limitController.text)!,
                                    alertEnabled: alertEnabled,
                                    threshold: alertEnabled
                                        ? _parseAmount(
                                            thresholdController.text)
                                        : null,
                                  );
                                  if (!context.mounted) return;
                                  if (ok) {
                                    Navigator.pop(ctx);
                                  } else {
                                    setSheetState(() => submitting = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tc.neoTeal,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Salvar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _editFieldLabel(ThemeColors tc, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: tc.neoTextFaint,
        ),
      );

  InputDecoration _editInputDecoration(ThemeColors tc, {String? prefix}) {
    return InputDecoration(
      prefixText: prefix,
      prefixStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: tc.neoTextMuted,
      ),
      filled: true,
      fillColor: tc.neoCard,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tc.neoCardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tc.neoCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tc.neoTeal, width: 1.5),
      ),
    );
  }

  Future<bool> _updateBudget({
    required BudgetEntity budget,
    required double limit,
    required bool alertEnabled,
    double? threshold,
  }) async {
    try {
      final updated = await Injection.instance.budgetRepository.updateBudget(
        id: budget.id,
        amountLimit: limit,
        alertThreshold: threshold,
        alertEnabled: alertEnabled,
      );
      if (!mounted) return true;
      setState(() {
        final idx = _budgets.indexWhere((b) => b.id == budget.id);
        if (idx != -1) _budgets[idx] = updated;
      });
      _snack('Orçamento atualizado', isError: false);
      return true;
    } on ServerException catch (e) {
      _snack(e.message);
      return false;
    } on NetworkException {
      _snack('Sem conexão com a internet');
      return false;
    } catch (_) {
      _snack('Erro ao atualizar orçamento');
      return false;
    }
  }

  static double? _parseAmount(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed
        .replaceAll(RegExp(r'[^\d,.\-]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String get _monthLabel {
    return toBeginningOfSentenceCase(
            DateFormat('MMMM', 'pt_BR').format(DateTime.now())) ??
        'Mês';
  }

  int get _daysRemainingInMonth {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return lastDay - now.day;
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Scaffold(
      backgroundColor: tc.neoBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: 'Orçamentos',
              subtitle:
                  '$_monthLabel · ${_budgets.length} ${_budgets.length == 1 ? 'categoria' : 'categorias'}',
              actions: [
                HeaderActionButton(
                  icon: Icons.add_rounded,
                  onTap: () async {
                    final result = await Navigator.pushNamed(
                        context, AppRoutes.createBudget);
                    if (result == true && mounted) _loadBudgets();
                  },
                  tooltip: 'Criar orçamento',
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadBudgets,
                color: tc.neoTeal,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    children: [
                      _buildOverviewCard(tc),
                      const SizedBox(height: 16),
                      if (_errorMessage != null && !_isLoading)
                        _buildErrorBanner(tc),
                      if (_isLoading)
                        _buildLoadingState(tc)
                      else if (_budgets.isEmpty)
                        _buildEmptyState(tc)
                      else
                        ..._budgets.map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Dismissible(
                                key: ValueKey('budget-${b.id}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: tc.neoNegative
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    color: tc.neoNegative,
                                  ),
                                ),
                                confirmDismiss: (_) async {
                                  // Reaproveita o diálogo + delete da API.
                                  // Retorna false (mantém na UI) e o método
                                  // já cuida da remoção em sucesso.
                                  await _deleteBudget(b);
                                  return false;
                                },
                                child: _BudgetCard(
                                  budget: b,
                                  onTap: () => _showActions(b),
                                ),
                              ),
                            )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(ThemeColors tc) {
    final percent =
        _totalLimit > 0 ? (_totalSpent / _totalLimit).clamp(0.0, 1.0) : 0.0;
    final percentText = '${(percent * 100).toStringAsFixed(0)}% utilizado';

    return HeroGradientCard(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'USADO ESTE MÊS',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmtCurrency(_totalSpent),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.2,
                    height: 1.1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 6),
                  child: Text(
                    '/ ${_fmtCurrency(_totalLimit)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(
                percent >= 0.8
                    ? const Color(0xFFFF8585)
                    : percent >= 0.5
                        ? const Color(0xFFFFCA28)
                        : const Color(0xFF6BE3B0),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                percentText,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Text(
                '$_daysRemainingInMonth dias restantes',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          IconBadge(
            icon: Icons.pie_chart_outline_rounded,
            tone: 'neutral',
            size: 64,
            iconSize: 28,
            radius: 18,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum orçamento definido',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: tc.neoTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Crie orçamentos para controlar seus gastos.',
            style: TextStyle(fontSize: 13, color: tc.neoTextFaint),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                  context, AppRoutes.createBudget);
              if (result == true && mounted) _loadBudgets();
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Criar orçamento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: tc.neoTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              minimumSize: const Size(220, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: CircularProgressIndicator(color: tc.neoTeal),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeColors tc) {
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
            onTap: _loadBudgets,
            child:
                Icon(Icons.refresh_rounded, color: tc.neoNegative, size: 18),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetEntity budget;
  final VoidCallback onTap;

  const _BudgetCard({required this.budget, required this.onTap});

  String _toneFor(String? cat) {
    final c = (cat ?? '').toLowerCase();
    if (c.contains('aliment') || c.contains('food')) return 'food';
    if (c.contains('transp')) return 'transport';
    if (c.contains('lazer')) return 'entertainment';
    if (c.contains('saúde') || c.contains('saude')) return 'health';
    if (c.contains('compras') || c.contains('shopping')) return 'shopping';
    if (c.contains('contas') || c.contains('aluguel')) return 'bills';
    return 'neutral';
  }

  IconData _iconFor(String? cat) {
    final c = (cat ?? '').toLowerCase();
    if (c.contains('aliment')) return Icons.restaurant_rounded;
    if (c.contains('transp')) return Icons.directions_car_rounded;
    if (c.contains('lazer')) return Icons.sports_esports_rounded;
    if (c.contains('saúde') || c.contains('saude')) {
      return Icons.medical_services_rounded;
    }
    if (c.contains('compras')) return Icons.shopping_cart_rounded;
    if (c.contains('contas')) return Icons.receipt_long_rounded;
    return Icons.pie_chart_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final percent = (budget.percentUsed / 100).clamp(0.0, 1.5);
    final isOver = percent > 1.0;
    final barColor = isOver
        ? tc.neoNegative
        : percent >= 0.8
            ? tc.neoAttention
            : percent >= 0.5
                ? const Color(0xFFA48BFF)
                : tc.neoPositive;

    final pctText = '${budget.percentUsed.toStringAsFixed(0)}%';

    return Material(
      color: tc.neoCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tc.neoCardBorder),
            boxShadow: [
              BoxShadow(
                color: tc.neoCardShadow,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBadge(
                    icon: _iconFor(budget.categoryName ?? budget.name),
                    tone: _toneFor(budget.categoryName ?? budget.name),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: tc.neoText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_fmtCurrency(budget.amountSpent)} · de ${_fmtCurrency(budget.amountLimit)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: tc.neoTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pctText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: barColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent.clamp(0.0, 1.0).toDouble(),
                  minHeight: 6,
                  backgroundColor: tc.isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtCurrency(double v) {
  final f = v.abs().toStringAsFixed(2).replaceAll('.', ',');
  final p = f.split(',');
  final i = p[0]
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return 'R\$ $i,${p[1]}';
}
