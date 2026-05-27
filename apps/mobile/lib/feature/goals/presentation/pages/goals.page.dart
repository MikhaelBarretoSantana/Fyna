import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/enums/goal_status.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_list_item.dart';
import 'package:fyna/core/widgets/app_screen_header.dart';
import 'package:fyna/core/widgets/hero_gradient_card.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
import 'package:fyna/feature/goals/domain/entities/financial_goal_entity.dart';
import 'package:intl/intl.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  List<FinancialGoalEntity> _goals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    if (!_isLoading) setState(() => _isLoading = true);
    setState(() => _errorMessage = null);
    try {
      final goals = await Injection.instance.goalRepository.getGoals();
      if (mounted) {
        setState(() {
          _goals = goals;
          _isLoading = false;
        });
      }
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
          _errorMessage = 'Erro ao carregar metas';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteGoal(FinancialGoalEntity goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index == -1) return;
    setState(() => _goals.removeAt(index));
    try {
      await Injection.instance.goalRepository.deleteGoal(goal.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _goals.insert(index, goal));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao excluir meta'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showGoalActions(FinancialGoalEntity goal) {
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
                  goal.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tc.neoText,
                  ),
                ),
                Text(
                  '${_fmt(goal.currentAmount)} de ${_fmt(goal.targetAmount)} · '
                  '${goal.progressPercent.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12.5, color: tc.neoTextMuted),
                ),
                const SizedBox(height: 16),
                AppListItem(
                  leading: const IconBadge(
                    icon: Icons.add_circle_rounded,
                    tone: 'success',
                  ),
                  title: 'Adicionar valor',
                  subtitle: 'Soma um aporte ao acumulado',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddProgressSheet(goal);
                  },
                ),
                const SizedBox(height: 8),
                AppListItem(
                  leading: const IconBadge(
                    icon: Icons.delete_outline_rounded,
                    tone: 'danger',
                  ),
                  title: 'Excluir meta',
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteGoal(goal);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddProgressSheet(FinancialGoalEntity goal) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

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
                        'Adicionar à meta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: tc.neoText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: tc.neoTextMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'VALOR DO APORTE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: tc.neoTextFaint,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: tc.neoText,
                        ),
                        decoration: InputDecoration(
                          prefixText: 'R\$  ',
                          prefixStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: tc.neoTextMuted,
                          ),
                          hintText: '0,00',
                          filled: true,
                          fillColor: tc.neoCard,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
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
                            borderSide:
                                BorderSide(color: tc.neoTeal, width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          final value = _parseAmount(v ?? '');
                          if (value == null || value <= 0) {
                            return 'Informe um valor positivo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [50, 100, 200, 500, 1000].map((quick) {
                          return ActionChip(
                            label: Text('+R\$ $quick'),
                            backgroundColor: tc.neoCard,
                            side: BorderSide(color: tc.neoCardBorder),
                            labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tc.neoText),
                            onPressed: () {
                              final current = _parseAmount(controller.text) ?? 0;
                              controller.text =
                                  (current + quick).toStringAsFixed(2).replaceAll('.', ',');
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  final value =
                                      _parseAmount(controller.text)!;
                                  setSheetState(() => submitting = true);
                                  final ok = await _addProgress(goal, value);
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
                              : const Text('Confirmar aporte'),
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

  /// Soma `amount` ao currentAmount da meta via backend.
  /// Retorna true em sucesso. Faz update otimista da lista local em sucesso.
  Future<bool> _addProgress(FinancialGoalEntity goal, double amount) async {
    try {
      final updated = await Injection.instance.goalRepository
          .addProgress(goal.id, amount);
      if (!mounted) return true;
      setState(() {
        final idx = _goals.indexWhere((g) => g.id == goal.id);
        if (idx != -1) _goals[idx] = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aporte de ${_fmt(amount)} adicionado'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    } on ServerException catch (e) {
      _toastError(e.message);
      return false;
    } on NetworkException {
      _toastError('Sem conexão com a internet');
      return false;
    } catch (_) {
      _toastError('Erro ao registrar aporte');
      return false;
    }
  }

  void _toastError(String message) {
    if (!mounted) return;
    final tc = ThemeColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: tc.neoNegative,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Parser que aceita "1.234,56", "1234,56", "1234.56" ou "1234".
  static double? _parseAmount(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed
        .replaceAll(RegExp(r'[^\d,.\-]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final activeGoals =
        _goals.where((g) => g.status == GoalStatus.IN_PROGRESS).toList();
    final totalCurrent =
        activeGoals.fold<double>(0.0, (s, g) => s + g.currentAmount);

    // Meta destaque: a com maior progressPercent entre ativas
    final featured = activeGoals.isEmpty
        ? null
        : (activeGoals.toList()
              ..sort((a, b) => b.progressPercent.compareTo(a.progressPercent)))
            .first;
    final otherGoals = featured == null
        ? <FinancialGoalEntity>[]
        : _goals.where((g) => g.id != featured.id).toList();

    return Scaffold(
      backgroundColor: tc.neoBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: 'Metas',
              subtitle: _isLoading
                  ? 'Carregando...'
                  : '${activeGoals.length} ${activeGoals.length == 1 ? 'ativa' : 'ativas'} · ${_fmtShort(totalCurrent)} acumulados',
              actions: [
                HeaderActionButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Criar meta',
                  onTap: () async {
                    final created = await Navigator.pushNamed(
                        context, AppRoutes.createGoal);
                    if (created == true) _loadGoals();
                  },
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadGoals,
                color: tc.neoTeal,
                child: _isLoading
                    ? _buildLoading(tc)
                    : _errorMessage != null
                        ? _buildErrorState(tc)
                        : _goals.isEmpty
                            ? _buildEmpty(tc)
                            : ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 32),
                                children: [
                                  if (featured != null)
                                    GestureDetector(
                                      onTap: () =>
                                          _showGoalActions(featured),
                                      child: _FeaturedGoalCard(goal: featured),
                                    ),
                                  if (otherGoals.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 22, 0, 10),
                                      child: Text(
                                        'OUTRAS METAS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.1,
                                          color: tc.neoTextFaint,
                                        ),
                                      ),
                                    ),
                                    for (final g in otherGoals) ...[
                                      _GoalListTile(
                                        goal: g,
                                        onTap: () => _showGoalActions(g),
                                        onDelete: () => _deleteGoal(g),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ],
                                ],
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeColors tc) {
    return Center(child: CircularProgressIndicator(color: tc.neoTeal));
  }

  Widget _buildEmpty(ThemeColors tc) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconBadge(
                  icon: Icons.flag_rounded,
                  tone: 'neutral',
                  size: 64,
                  iconSize: 28,
                  radius: 18,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma meta definida',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: tc.neoTextMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Defina metas para alcançar seus sonhos.',
                  style: TextStyle(fontSize: 13, color: tc.neoTextFaint),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: () async {
                    final created = await Navigator.pushNamed(
                        context, AppRoutes.createGoal);
                    if (created == true) _loadGoals();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Criar meta'),
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
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeColors tc) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconBadge(
                    icon: Icons.error_outline_rounded,
                    tone: 'danger',
                    size: 56,
                    iconSize: 26,
                    radius: 16,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? 'Erro inesperado',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: tc.neoTextMuted),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loadGoals,
                    style: TextButton.styleFrom(foregroundColor: tc.neoTeal),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedGoalCard extends StatelessWidget {
  final FinancialGoalEntity goal;
  const _FeaturedGoalCard({required this.goal});

  bool get _onTrack {
    if (goal.targetDate == null) return true;
    final daysLeft = goal.targetDate!.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return goal.progressPercent >= 100;
    final expected = 100 -
        (daysLeft /
                math.max(
                    1,
                    goal.targetDate!
                        .difference(goal.createdAt)
                        .inDays))
            .clamp(0.0, 1.0) *
            100;
    return goal.progressPercent >= expected - 10;
  }

  @override
  Widget build(BuildContext context) {
    final percent = (goal.progressPercent / 100).clamp(0.0, 1.0);
    final statusLabel = _onTrack ? 'NO PRAZO' : 'ATRASADA';
    final statusColor = _onTrack
        ? const Color(0xFF6BE3B0)
        : const Color(0xFFFFCA28);
    final goalGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _parseColor(goal.color, fallback: const Color(0xFF13B679)),
        _parseColor(goal.color, fallback: const Color(0xFF0E8C5E))
            .withValues(alpha: 0.9),
      ],
    );

    return HeroGradientCard(
      gradient: goalGradient,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 8,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.16),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    Text(
                      '${goal.progressPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acumulado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _fmt(goal.currentAmount),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      goal.targetDate != null
                          ? 'Meta · ${_fmtMonth(goal.targetDate!)}'
                          : 'Sem prazo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      _fmt(goal.targetAmount),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalListTile extends StatelessWidget {
  final FinancialGoalEntity goal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GoalListTile({
    required this.goal,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final percent = (goal.progressPercent / 100).clamp(0.0, 1.0);
    final goalColor = _parseColor(goal.color, fallback: tc.neoTeal);
    final pctText = '${goal.progressPercent.toStringAsFixed(0)}%';

    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: tc.neoNegative.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline_rounded, color: tc.neoNegative),
      ),
      onDismissed: (_) => onDelete(),
      child: AppListItem(
        onTap: onTap,
        leading: IconBadge(
          icon: Icons.flag_rounded,
          background: goalColor.withValues(alpha: tc.isDark ? 0.18 : 0.14),
          foreground: goalColor,
        ),
        title: goal.name,
        subtitle:
            '${_fmt(goal.currentAmount)}  ·  ${goal.targetDate != null ? _fmtMonth(goal.targetDate!) : 'Sem prazo'}',
        trailing: Text(
          pctText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: goalColor,
          ),
        ),
        extra: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 5,
            backgroundColor: tc.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            valueColor: AlwaysStoppedAnimation(goalColor),
          ),
        ),
      ),
    );
  }
}

Color _parseColor(String? hex, {required Color fallback}) {
  if (hex == null || hex.isEmpty) return fallback;
  final cleaned = hex.replaceAll('#', '');
  if (cleaned.length != 6) return fallback;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return fallback;
  return Color(0xFF000000 | value);
}

String _fmt(double v) {
  final f = v.abs().toStringAsFixed(2).replaceAll('.', ',');
  final p = f.split(',');
  final i = p[0]
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return 'R\$ $i,${p[1]}';
}

String _fmtShort(double v) {
  if (v.abs() >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
  if (v.abs() >= 1000) return 'R\$ ${(v / 1000).toStringAsFixed(1)}K';
  return _fmt(v);
}

String _fmtMonth(DateTime d) {
  return toBeginningOfSentenceCase(
        DateFormat('MMM y', 'pt_BR').format(d).replaceAll('.', ''),
      ) ??
      DateFormat('MMM y', 'pt_BR').format(d);
}
