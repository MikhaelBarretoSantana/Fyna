import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_list_item.dart';
import 'package:fyna/core/widgets/app_screen_header.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
import 'package:fyna/feature/recurring/domain/entities/recurring_transaction_entity.dart';

class RecurringTransactionsPage extends StatefulWidget {
  const RecurringTransactionsPage({super.key});

  @override
  State<RecurringTransactionsPage> createState() =>
      _RecurringTransactionsPageState();
}

class _RecurringTransactionsPageState extends State<RecurringTransactionsPage> {
  List<RecurringTransactionEntity> _allRecurring = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadRecurring();
  }

  Future<void> _loadRecurring() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final recurring =
          await Injection.instance.recurringRepository.getAllRecurring();
      if (mounted) {
        setState(() {
          _allRecurring = recurring;
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
          _errorMessage = 'Erro ao carregar recorrências';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleActive(RecurringTransactionEntity item) async {
    final newStatus = !item.isActive;
    try {
      await Injection.instance.recurringRepository
          .updateRecurring(id: item.id, isActive: newStatus);
      if (!mounted) return;
      setState(() {
        final idx = _allRecurring.indexWhere((r) => r.id == item.id);
        if (idx != -1) {
          _allRecurring[idx] = _copyWith(item, isActive: newStatus);
        }
      });
      _snack(newStatus ? 'Recorrência reativada' : 'Recorrência pausada',
          isError: false);
    } catch (_) {
      _snack('Erro ao atualizar recorrência');
    }
  }

  Future<void> _delete(RecurringTransactionEntity item) async {
    final confirmed = await _confirmDelete(item);
    if (confirmed != true) return;
    try {
      await Injection.instance.recurringRepository.deleteRecurring(item.id);
      if (!mounted) return;
      setState(() {
        final idx = _allRecurring.indexWhere((r) => r.id == item.id);
        if (idx != -1) {
          _allRecurring[idx] = _copyWith(item, isActive: false);
        }
      });
      _snack('Recorrência desativada', isError: false);
    } catch (_) {
      _snack('Erro ao desativar recorrência');
    }
  }

  RecurringTransactionEntity _copyWith(
    RecurringTransactionEntity item, {
    required bool isActive,
  }) {
    return RecurringTransactionEntity(
      id: item.id,
      accountId: item.accountId,
      categoryId: item.categoryId,
      categoryName: item.categoryName,
      type: item.type,
      amount: item.amount,
      description: item.description,
      frequency: item.frequency,
      frequencyInterval: item.frequencyInterval,
      startDate: item.startDate,
      endDate: item.endDate,
      nextOccurrence: item.nextOccurrence,
      lastGenerated: item.lastGenerated,
      isActive: isActive,
    );
  }

  Future<bool?> _confirmDelete(RecurringTransactionEntity item) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        return AlertDialog(
          backgroundColor: tc.neoCardElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: IconBadge(
            icon: Icons.pause_circle_outline_rounded,
            tone: 'warning',
            size: 56,
            iconSize: 26,
            radius: 16,
          ),
          title: Text(
            'Desativar recorrência?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tc.neoText,
            ),
          ),
          content: Text(
            '"${item.description}" de ${_fmt(item.amount)} (${item.frequency.label}) '
            'será desativada. Transações já geradas não serão afetadas.',
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
                backgroundColor: tc.neoAttention,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Desativar',
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

  void _showActions(RecurringTransactionEntity item) {
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
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tc.neoTextFaint.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                AppListItem(
                  leading: IconBadge(
                    icon: item.isActive
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    tone: item.isActive ? 'warning' : 'success',
                  ),
                  title: item.isActive
                      ? 'Pausar recorrência'
                      : 'Reativar recorrência',
                  onTap: () {
                    Navigator.pop(ctx);
                    _toggleActive(item);
                  },
                ),
                const SizedBox(height: 8),
                AppListItem(
                  leading: const IconBadge(
                    icon: Icons.delete_outline_rounded,
                    tone: 'danger',
                  ),
                  title: 'Desativar e excluir',
                  onTap: () {
                    Navigator.pop(ctx);
                    _delete(item);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Calculados ───
  List<RecurringTransactionEntity> get _filtered {
    if (_showInactive) return _allRecurring;
    return _allRecurring.where((r) => r.isActive).toList();
  }

  double get _totalExpenses => _allRecurring
      .where((r) => r.isActive && r.type == TransactionType.expense)
      .fold(0.0, (s, r) => s + r.amount);

  double get _totalIncome => _allRecurring
      .where((r) => r.isActive && r.type == TransactionType.income)
      .fold(0.0, (s, r) => s + r.amount);

  int get _activeCount => _allRecurring.where((r) => r.isActive).length;

  RecurringTransactionEntity? get _nextDue {
    final now = DateTime.now();
    final upcoming = _allRecurring
        .where((r) =>
            r.isActive &&
            r.nextOccurrence != null &&
            !r.nextOccurrence!.isBefore(now))
        .toList()
      ..sort((a, b) => a.nextOccurrence!.compareTo(b.nextOccurrence!));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  String get _subtitleText {
    if (_isLoading) return 'Carregando...';
    final next = _nextDue;
    if (next == null) {
      return '$_activeCount ${_activeCount == 1 ? 'ativa' : 'ativas'}';
    }
    final days =
        next.nextOccurrence!.difference(DateTime.now()).inDays;
    final when = days <= 0
        ? 'hoje'
        : days == 1
            ? 'amanhã'
            : 'em $days dias';
    return '$_activeCount ${_activeCount == 1 ? 'ativa' : 'ativas'} · próximo pagamento $when';
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
              title: 'Recorrências',
              subtitle: _subtitleText,
              actions: [
                HeaderActionButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Criar recorrência',
                  onTap: () async {
                    final result = await Navigator.pushNamed(
                        context, AppRoutes.createRecurring);
                    if (result == true && mounted) _loadRecurring();
                  },
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadRecurring,
                color: tc.neoTeal,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: tc.neoTeal))
                    : _errorMessage != null
                        ? _buildError(tc)
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                            children: [
                              _buildSummary(tc),
                              const SizedBox(height: 16),
                              if (_filtered.isEmpty)
                                _buildEmpty(tc)
                              else
                                for (final item in _filtered) ...[
                                  _RecurringTile(
                                    item: item,
                                    onTap: () => _showActions(item),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              if (_allRecurring.any((r) => !r.isActive))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TextButton.icon(
                                    onPressed: () => setState(
                                        () => _showInactive = !_showInactive),
                                    icon: Icon(
                                      _showInactive
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _showInactive
                                          ? 'Ocultar inativas'
                                          : 'Ver inativas',
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: tc.neoTextMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ThemeColors tc) {
    return Row(
      children: [
        Expanded(
          child: _SummaryStat(
            label: 'Entra/mês',
            value: _fmt(_totalIncome),
            accent: tc.neoPositive,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryStat(
            label: 'Sai/mês',
            value: _fmt(_totalExpenses),
            accent: tc.neoNegative,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          IconBadge(
            icon: Icons.repeat_rounded,
            tone: 'neutral',
            size: 64,
            iconSize: 28,
            radius: 18,
          ),
          const SizedBox(height: 16),
          Text(
            'Sem recorrências ativas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: tc.neoTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cadastre pagamentos automáticos como\nassinaturas, contas e salário.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: tc.neoTextFaint),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                  context, AppRoutes.createRecurring);
              if (result == true && mounted) _loadRecurring();
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Nova recorrência'),
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

  Widget _buildError(ThemeColors tc) {
    return Center(
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
              onPressed: _loadRecurring,
              style: TextButton.styleFrom(foregroundColor: tc.neoTeal),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringTransactionEntity item;
  final VoidCallback onTap;

  const _RecurringTile({required this.item, required this.onTap});

  String _toneFor(RecurringTransactionEntity r) {
    if (r.type == TransactionType.income) return 'salary';
    final cat = (r.categoryName ?? r.description).toLowerCase();
    if (cat.contains('aliment') || cat.contains('ifood')) return 'food';
    if (cat.contains('transp')) return 'transport';
    if (cat.contains('lazer') || cat.contains('streaming') ||
        cat.contains('netflix') || cat.contains('spotify')) {
      return 'entertainment';
    }
    if (cat.contains('shopping') || cat.contains('compras')) return 'shopping';
    if (cat.contains('saúde') || cat.contains('saude')) return 'health';
    if (cat.contains('aluguel') || cat.contains('contas') ||
        cat.contains('luz') || cat.contains('água') || cat.contains('agua')) {
      return 'bills';
    }
    return 'neutral';
  }

  IconData _iconFor(RecurringTransactionEntity r) {
    final cat = (r.categoryName ?? r.description).toLowerCase();
    if (r.type == TransactionType.income) return Icons.flash_on_rounded;
    if (cat.contains('netflix')) return Icons.movie_outlined;
    if (cat.contains('spotify')) return Icons.headset_rounded;
    if (cat.contains('aluguel')) return Icons.home_rounded;
    if (cat.contains('vivo') || cat.contains('claro') || cat.contains('tim') ||
        cat.contains('oi') || cat.contains('telefone')) {
      return Icons.phone_iphone_rounded;
    }
    if (cat.contains('luz') || cat.contains('água') || cat.contains('agua') ||
        cat.contains('gás') || cat.contains('contas')) {
      return Icons.receipt_long_rounded;
    }
    if (cat.contains('transp')) return Icons.directions_car_rounded;
    return Icons.repeat_rounded;
  }

  String _subtitleText() {
    final freq = item.frequency.label;
    final day = item.startDate.day;
    final dayLabel = item.frequency.toJson() == 'MONTHLY' ||
            item.frequency.toJson() == 'BIMONTHLY' ||
            item.frequency.toJson() == 'YEARLY'
        ? ' · dia ${day.toString().padLeft(2, '0')}'
        : '';
    if (item.nextOccurrence != null) {
      final days = item.nextOccurrence!.difference(DateTime.now()).inDays;
      final when = days < 0
          ? 'vencida'
          : days == 0
              ? 'hoje'
              : days == 1
                  ? 'amanhã'
                  : 'em $days dias';
      return '$freq$dayLabel · $when';
    }
    return '$freq$dayLabel';
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final isIncome = item.type == TransactionType.income;
    final color = isIncome ? tc.neoPositive : tc.neoNegative;
    final sign = isIncome ? '+' : '-';

    return Opacity(
      opacity: item.isActive ? 1.0 : 0.5,
      child: AppListItem(
        leading: IconBadge(
          icon: _iconFor(item),
          tone: _toneFor(item),
        ),
        title: item.description,
        subtitle: _subtitleText(),
        trailing: Text(
          '$sign ${_fmt(item.amount)}',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: tc.neoCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.neoCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: tc.neoTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmt(double v) {
  final f = v.abs().toStringAsFixed(2).replaceAll('.', ',');
  final p = f.split(',');
  final i = p[0]
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return 'R\$ $i,${p[1]}';
}
