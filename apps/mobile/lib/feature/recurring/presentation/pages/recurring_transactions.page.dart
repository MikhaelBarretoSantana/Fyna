import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/enums/recurring_frequency.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/recurring/domain/entities/recurring_transaction_entity.dart';
import 'package:intl/intl.dart';

class RecurringTransactionsPage extends StatefulWidget {
  const RecurringTransactionsPage({super.key});

  @override
  State<RecurringTransactionsPage> createState() =>
      _RecurringTransactionsPageState();
}

class _RecurringTransactionsPageState extends State<RecurringTransactionsPage> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  List<RecurringTransactionEntity> _allRecurring = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showInactive = false;

  // ─── Calculados ───
  List<RecurringTransactionEntity> get _filtered {
    if (_showInactive) return _allRecurring;
    return _allRecurring.where((r) => r.isActive).toList();
  }

  double get _totalExpenses {
    return _allRecurring
        .where((r) => r.isActive && r.type == TransactionType.expense)
        .fold(0.0, (s, r) => s + r.amount);
  }

  double get _totalIncome {
    return _allRecurring
        .where((r) => r.isActive && r.type == TransactionType.income)
        .fold(0.0, (s, r) => s + r.amount);
  }

  int get _activeCount => _allRecurring.where((r) => r.isActive).length;
  int get _inactiveCount => _allRecurring.where((r) => !r.isActive).length;

  // Próximas a vencer (nos próximos 7 dias)
  List<RecurringTransactionEntity> get _upcoming {
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 7));
    return _allRecurring
        .where((r) =>
            r.isActive &&
            r.nextOccurrence != null &&
            r.nextOccurrence!.isBefore(limit) &&
            !r.nextOccurrence!.isBefore(now))
        .toList()
      ..sort((a, b) => a.nextOccurrence!.compareTo(b.nextOccurrence!));
  }

  @override
  void initState() {
    super.initState();
    _loadRecurring();
  }

  // ─── Carregamento ───
  Future<void> _loadRecurring() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Carrega todas (ativas + inativas) para ter contadores corretos
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

  // ─── Ações ───
  Future<void> _navigateToCreate() async {
    final result =
        await Navigator.pushNamed(context, AppRoutes.createRecurring);
    if (result == true && mounted) _loadRecurring();
  }

  Future<void> _toggleActive(RecurringTransactionEntity item) async {
    final newStatus = !item.isActive;
    try {
      await Injection.instance.recurringRepository.updateRecurring(
        id: item.id,
        isActive: newStatus,
      );
      if (mounted) {
        setState(() {
          final idx = _allRecurring.indexWhere((r) => r.id == item.id);
          if (idx != -1) {
            _allRecurring[idx] = RecurringTransactionEntity(
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
              isActive: newStatus,
            );
          }
        });
        _showSnackBar(
          newStatus ? 'Recorrência reativada' : 'Recorrência pausada',
          isError: false,
        );
      }
    } catch (_) {
      _showSnackBar('Erro ao atualizar recorrência');
    }
  }

  Future<void> _deleteRecurring(RecurringTransactionEntity item) async {
    final confirmed = await _showDeleteConfirmation(item);
    if (confirmed != true) return;

    try {
      await Injection.instance.recurringRepository.deleteRecurring(item.id);
      if (mounted) {
        setState(() {
          final idx = _allRecurring.indexWhere((r) => r.id == item.id);
          if (idx != -1) {
            _allRecurring[idx] = RecurringTransactionEntity(
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
              isActive: false,
            );
          }
        });
        _showSnackBar('Recorrência desativada', isError: false);
      }
    } catch (_) {
      _showSnackBar('Erro ao desativar recorrência');
    }
  }

  Future<bool?> _showDeleteConfirmation(RecurringTransactionEntity item) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.pause_circle_outline_rounded,
              color: AppColors.warning, size: 28),
        ),
        title: Text('Desativar recorrência?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            )),
        content: Text(
          '"${item.description}" de ${_formatCurrency(item.amount)} '
          '(${item.frequency.label}) será desativada. '
          'Transações já geradas não serão afetadas.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white60 : AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                )),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Desativar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Bottom sheet de ações ───
  void _showActions(RecurringTransactionEntity item) {
    HapticFeedback.mediumImpact();
    final isExpense = item.type == TransactionType.expense;
    final color = isExpense ? AppColors.error : AppColors.success;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return Container(
          padding:
              EdgeInsets.fromLTRB(20, 14, 20, bottomPadding > 0 ? 12 : 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14142A) : Colors.white,
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
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.repeat_rounded, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.description,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            )),
                        Text(
                          '${_formatCurrency(item.amount)} · ${item.frequency.label}',
                          style: TextStyle(
                            fontSize: 13,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Toggle ativo/inativo
              _buildActionTile(
                icon: item.isActive
                    ? Icons.pause_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
                label: item.isActive ? 'Pausar recorrência' : 'Reativar',
                color:
                    item.isActive ? AppColors.warning : AppColors.success,
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleActive(item);
                },
              ),
              if (item.isActive) ...[
                const SizedBox(height: 8),
                _buildActionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Desativar permanentemente',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteRecurring(item);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.06 : 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: color.withValues(alpha: isDark ? 0.15 : 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    )),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: isDark ? Colors.white24 : Colors.black26, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F5F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadRecurring,
                color: isDark ? AppColors.darkAccent : AppColors.primary,
                child: _isLoading
                    ? _buildLoadingContent()
                    : _allRecurring.isEmpty
                        ? _buildEmptyState()
                        : _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1C2E)
                    : const Color(0xFFEEEEF2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recorrentes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    )),
                if (!_isLoading)
                  Text(
                    '$_activeCount ativa${_activeCount != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _navigateToCreate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkAccent : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text('Nova',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Content ───
  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null) _buildErrorBanner(),
          // Resumo financeiro
          _buildSummaryCard(),
          const SizedBox(height: 16),
          // Próximas a vencer
          if (_upcoming.isNotEmpty) ...[
            _buildSectionTitle('Próximas 7 dias', '${_upcoming.length}'),
            const SizedBox(height: 8),
            ..._upcoming.map((r) => _buildRecurringCard(r, highlight: true)),
            const SizedBox(height: 20),
          ],
          // Toggle + lista principal
          _buildToggle(),
          const SizedBox(height: 12),
          // Agrupado por tipo
          _buildGroupedList(),
        ],
      ),
    );
  }

  // ─── Resumo ───
  Widget _buildSummaryCard() {
    final net = _totalIncome - _totalExpenses;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A2A3E), const Color(0xFF0F1B2D)]
              : [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primaryDark)
                .withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Despesas fixas',
                  _formatCurrency(_totalExpenses),
                  Icons.arrow_downward_rounded,
                  AppColors.error.withValues(alpha: 0.7),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Receitas fixas',
                  _formatCurrency(_totalIncome),
                  Icons.arrow_upward_rounded,
                  AppColors.success.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  net >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16,
                  color: net >= 0
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.error.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  'Saldo recorrente: ${net >= 0 ? '+' : ''}${_formatCurrency(net)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            )),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            )),
      ],
    );
  }

  // ─── Toggle ───
  Widget _buildToggle() {
    return Row(
      children: [
        Text(
          _showInactive ? 'Todas as recorrências' : 'Ativas',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const Spacer(),
        if (_inactiveCount > 0)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showInactive = !_showInactive);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _showInactive
                    ? (isDark ? AppColors.darkAccent : AppColors.primary)
                        .withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Text(
                _showInactive
                    ? 'Ocultar inativas'
                    : 'Ver inativas ($_inactiveCount)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkAccent : AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Lista agrupada ───
  Widget _buildGroupedList() {
    final expenses =
        _filtered.where((r) => r.type == TransactionType.expense).toList();
    final income =
        _filtered.where((r) => r.type == TransactionType.income).toList();
    final transfers =
        _filtered.where((r) => r.type == TransactionType.transfer).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (expenses.isNotEmpty) ...[
          _buildSectionTitle('Despesas', '${expenses.length}'),
          const SizedBox(height: 8),
          ...expenses.map((r) => _buildRecurringCard(r)),
          const SizedBox(height: 16),
        ],
        if (income.isNotEmpty) ...[
          _buildSectionTitle('Receitas', '${income.length}'),
          const SizedBox(height: 8),
          ...income.map((r) => _buildRecurringCard(r)),
          const SizedBox(height: 16),
        ],
        if (transfers.isNotEmpty) ...[
          _buildSectionTitle('Transferências', '${transfers.length}'),
          const SizedBox(height: 8),
          ...transfers.map((r) => _buildRecurringCard(r)),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, String count) {
    return Row(
      children: [
        Text(title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
            )),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(count,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white30 : Colors.black38,
              )),
        ),
      ],
    );
  }

  // ─── Card de recorrência ───
  Widget _buildRecurringCard(RecurringTransactionEntity item,
      {bool highlight = false}) {
    final isExpense = item.type == TransactionType.expense;
    final isIncome = item.type == TransactionType.income;
    final color = isExpense
        ? AppColors.error
        : isIncome
            ? AppColors.success
            : AppColors.info;
    final sign = isExpense
        ? '-'
        : isIncome
            ? '+'
            : '';

    final daysUntil = item.nextOccurrence != null
        ? item.nextOccurrence!
            .difference(DateTime.now())
            .inDays
        : null;

    return GestureDetector(
      onLongPress: () => _showActions(item),
      child: Opacity(
        opacity: item.isActive ? 1.0 : 0.5,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14142A) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlight
                  ? (isDark ? AppColors.darkAccent : AppColors.primary)
                      .withValues(alpha: 0.25)
                  : (isDark
                      ? const Color(0xFF252540)
                      : const Color(0xFFEEEEF2)),
            ),
          ),
          child: Row(
            children: [
              // Ícone
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.repeat_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.description,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(item.frequency.label,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.white30 : Colors.black38,
                            )),
                        if (item.categoryName != null) ...[
                          Text(' · ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black26,
                              )),
                          Flexible(
                            child: Text(item.categoryName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white30
                                      : Colors.black38,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                    // Próxima ocorrência
                    if (item.nextOccurrence != null && item.isActive) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 12,
                              color: daysUntil != null && daysUntil <= 2
                                  ? AppColors.warning
                                  : (isDark
                                      ? Colors.white70
                                      : Colors.black26)),
                          const SizedBox(width: 4),
                          Text(
                            _formatNextOccurrence(
                                item.nextOccurrence!, daysUntil),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: daysUntil != null && daysUntil <= 2
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: daysUntil != null && daysUntil <= 2
                                  ? AppColors.warning
                                  : (isDark
                                      ? Colors.white24
                                      : Colors.black26),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Valor + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign ${_formatCurrency(item.amount)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (!item.isActive)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Inativa',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          )),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNextOccurrence(DateTime date, int? daysUntil) {
    if (daysUntil == null) return DateFormat('dd/MM').format(date);
    if (daysUntil == 0) return 'Hoje';
    if (daysUntil == 1) return 'Amanhã';
    if (daysUntil <= 7) return 'Em $daysUntil dias';
    return DateFormat('dd/MM').format(date);
  }

  // ─── Error ───
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                )),
          ),
          GestureDetector(
            onTap: _loadRecurring,
            child: const Icon(Icons.refresh_rounded,
                color: AppColors.error, size: 18),
          ),
        ],
      ),
    );
  }

  // ─── Empty ───
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1C2E)
                        : const Color(0xFFEEEEF2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.repeat_rounded,
                      size: 32,
                      color: isDark ? Colors.white12 : Colors.black12),
                ),
                const SizedBox(height: 16),
                Text('Nenhuma recorrência',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black26,
                    )),
                const SizedBox(height: 6),
                Text(
                  'Automatize despesas e receitas fixas\ncomo aluguel, salário, assinaturas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black26,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _navigateToCreate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkAccent.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.darkAccent
                                : AppColors.primary),
                        const SizedBox(width: 6),
                        Text('Criar recorrência',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkAccent
                                  : AppColors.primary,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Loading ───
  Widget _buildLoadingContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A2A3E)
                  : const Color(0xFFD0E8EF),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(4, (i) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF14142A)
                    : const Color(0xFFEEEEF2),
                borderRadius: BorderRadius.circular(18),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Utils ───
  String _formatCurrency(double value) {
    final formatted = value.abs().toStringAsFixed(2).replaceAll('.', ',');
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }
}