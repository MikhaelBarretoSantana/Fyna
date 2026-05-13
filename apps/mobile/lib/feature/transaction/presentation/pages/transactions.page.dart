import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/transaction/domain/entities/transaction_entity.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends StatefulWidget {
  final bool isDark;
  const TransactionsPage({super.key, required this.isDark});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with SingleTickerProviderStateMixin {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  late TabController _tabController;
  String _selectedPeriod = 'Mês';
  final List<String> _periods = ['Semana', 'Mês', 'Ano'];

  // ─── Dados da API ───
  List<TransactionEntity> _allTransactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // ─── Paginação ───
  int _currentPage = 0;
  static const int _pageSize = 30;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // ─── Resumo calculado ───
  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Cálculo do range de datas ───
  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Semana':
        // Início da semana (segunda-feira)
        final weekday = now.weekday; // 1=Mon, 7=Sun
        return DateTime(now.year, now.month, now.day - (weekday - 1));
      case 'Ano':
        return DateTime(now.year, 1, 1);
      case 'Mês':
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime get _endDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Semana':
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day + (7 - weekday));
      case 'Ano':
        return DateTime(now.year, 12, 31);
      case 'Mês':
      default:
        return DateTime(now.year, now.month + 1, 0); // último dia do mês
    }
  }

  // ─── Carregamento de dados ───
  Future<void> _loadTransactions({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _hasMore = true;
    }

    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final page =
          await Injection.instance.transactionRepository.getTransactions(
        page: 0,
        size: _pageSize,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _allTransactions = page.content;
          _currentPage = 0;
          _hasMore = page.content.length >= _pageSize;
          _isLoading = false;
          _calculateSummary();
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
          _errorMessage = 'Erro ao carregar transações';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final page =
          await Injection.instance.transactionRepository.getTransactions(
        page: nextPage,
        size: _pageSize,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _allTransactions.addAll(page.content);
          _currentPage = nextPage;
          _hasMore = page.content.length >= _pageSize;
          _isLoadingMore = false;
          _calculateSummary();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _calculateSummary() {
    double income = 0;
    double expense = 0;
    for (final t in _allTransactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else if (t.type == TransactionType.expense) {
        expense += t.amount;
      }
    }
    _totalIncome = income;
    _totalExpense = expense;
  }

  void _onPeriodChanged(String period) {
    if (_selectedPeriod == period) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedPeriod = period);
    _loadTransactions();
  }

  // ─── Filtro por tipo (client-side) ───
  List<TransactionEntity> _filteredByType(TransactionType? type) {
    if (type == null) return _allTransactions;
    return _allTransactions.where((t) => t.type == type).toList();
  }

  // ─── Agrupamento por data ───
  Map<String, List<TransactionEntity>> _groupByDate(
      List<TransactionEntity> transactions) {
    final grouped = <String, List<TransactionEntity>>{};
    for (final t in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(t.transactionDate);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  // ─── Ações em transações ───
  Future<void> _onTransactionTap(TransactionEntity transaction) async {
    HapticFeedback.selectionClick();
    // TODO: Navegar para tela de detalhes / edição
    // final result = await Navigator.pushNamed(
    //   context,
    //   AppRoutes.editTransaction,
    //   arguments: transaction,
    // );
    // if (result == true) _loadTransactions(isRefresh: true);
  }

  Future<void> _onDeleteTransaction(TransactionEntity transaction) async {
    final confirmed = await _showDeleteConfirmation(transaction);
    if (confirmed != true) return;

    try {
      await Injection.instance.transactionRepository
          .deleteTransaction(transaction.id);

      if (mounted) {
        setState(() {
          _allTransactions.removeWhere((t) => t.id == transaction.id);
          _calculateSummary();
        });
        _showSnackBar('Transação excluída', isError: false);
      }
    } on ServerException catch (e) {
      _showSnackBar(e.message);
    } on NetworkException {
      _showSnackBar('Sem conexão com a internet');
    } catch (_) {
      _showSnackBar('Erro ao excluir transação');
    }
  }

  Future<void> _onTogglePaid(TransactionEntity transaction) async {
    final newPaidStatus = !transaction.isPaid;

    try {
      await Injection.instance.transactionRepository.updateTransaction(
        id: transaction.id,
        isPaid: newPaidStatus,
      );

      if (mounted) {
        // Atualizar localmente para feedback instantâneo
        setState(() {
          final idx = _allTransactions.indexWhere((t) => t.id == transaction.id);
          if (idx != -1) {
            _allTransactions[idx] = TransactionEntity(
              id: transaction.id,
              accountId: transaction.accountId,
              categoryId: transaction.categoryId,
              categoryName: transaction.categoryName,
              transferPairId: transaction.transferPairId,
              type: transaction.type,
              amount: transaction.amount,
              description: transaction.description,
              notes: transaction.notes,
              transactionDate: transaction.transactionDate,
              dueDate: transaction.dueDate,
              isPaid: newPaidStatus,
              isRecurring: transaction.isRecurring,
              recurringTransactionId: transaction.recurringTransactionId,
              attachmentUrl: transaction.attachmentUrl,
            );
          }
        });
        _showSnackBar(
          newPaidStatus ? 'Marcada como paga' : 'Marcada como pendente',
          isError: false,
        );
      }
    } catch (_) {
      _showSnackBar('Erro ao atualizar status');
    }
  }

  Future<bool?> _showDeleteConfirmation(TransactionEntity transaction) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error,
            size: 28,
          ),
        ),
        title: Text(
          'Excluir transação?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A transação "${transaction.description}" de '
              '${_formatCurrency(transaction.amount)} será excluída '
              'e o saldo da conta será ajustado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Essa ação não pode ser desfeita.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Excluir',
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

  // ─── Bottom sheet de ações para uma transação ───
  void _showTransactionActions(TransactionEntity transaction) {
    HapticFeedback.mediumImpact();
    final isExpense = transaction.type == TransactionType.expense;
    final isIncome = transaction.type == TransactionType.income;
    final typeColor = isExpense
        ? AppColors.error
        : isIncome
            ? AppColors.success
            : AppColors.info;

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
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Header com info da transação
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isExpense
                          ? Icons.arrow_downward_rounded
                          : isIncome
                              ? Icons.arrow_upward_rounded
                              : Icons.swap_horiz_rounded,
                      color: typeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatCurrency(transaction.amount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Ações
              _buildActionTile(
                icon: transaction.isPaid
                    ? Icons.remove_circle_outline_rounded
                    : Icons.check_circle_outline_rounded,
                label: transaction.isPaid
                    ? 'Marcar como pendente'
                    : 'Marcar como paga',
                color: transaction.isPaid ? AppColors.warning : AppColors.success,
                onTap: () {
                  Navigator.pop(ctx);
                  _onTogglePaid(transaction);
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Excluir transação',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(ctx);
                  _onDeleteTransaction(transaction);
                },
              ),
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
            border:
                Border.all(color: color.withValues(alpha: isDark ? 0.15 : 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
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
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildPeriodFilter(),
        const SizedBox(height: 16),
        _isLoading ? _buildSummaryShimmer() : _buildSummaryCards(),
        const SizedBox(height: 16),
        _buildTabBar(),
        const SizedBox(height: 4),
        // Error banner
        if (_errorMessage != null && !_isLoading) _buildErrorBanner(),
        // Lista de transações
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionsList(null),
              _buildTransactionsList(TransactionType.expense),
              _buildTransactionsList(TransactionType.income),
              _buildTransactionsList(TransactionType.transfer),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Header com título e filtro de período ───
  Widget _buildPeriodFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transações',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _periodLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF1C1C2E) : const Color(0xFFEEEEF2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _periods.map((period) {
                final isSelected = _selectedPeriod == period;
                return GestureDetector(
                  onTap: () => _onPeriodChanged(period),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.darkAccent : AppColors.primary)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      period,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white38 : Colors.black45),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String get _periodLabel {
    final fmt = DateFormat("dd MMM", 'pt_BR');
    final fmtFull = DateFormat("dd MMM yyyy", 'pt_BR');
    final start = _startDate;
    final end = _endDate;

    if (start.year == end.year) {
      return '${fmt.format(start)} — ${fmtFull.format(end)}';
    }
    return '${fmtFull.format(start)} — ${fmtFull.format(end)}';
  }

  // ─── Cards de resumo ───
  Widget _buildSummaryCards() {
    final balance = _totalIncome - _totalExpense;
    final balanceColor = balance >= 0
        ? (isDark ? AppColors.darkAccent : AppColors.primary)
        : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              label: 'Receitas',
              value: _formatCurrency(_totalIncome),
              icon: Icons.arrow_upward_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryCard(
              label: 'Despesas',
              value: _formatCurrency(_totalExpense),
              icon: Icons.arrow_downward_rounded,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryCard(
              label: 'Balanço',
              value: _formatCurrency(balance.abs()),
              icon: balance >= 0
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: balanceColor,
              prefix: balance < 0 ? '-' : '+',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? prefix,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14142A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              prefix != null ? '$prefix $value' : value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
              height: 96,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF14142A)
                    : const Color(0xFFEEEEF2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Tab bar ───
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : const Color(0xFFEEEEF2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? AppColors.darkAccent : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white38 : Colors.black45,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        padding: const EdgeInsets.all(3),
        tabs: [
          _buildTabLabel('Todos', null),
          _buildTabLabel('Despesas', TransactionType.expense),
          _buildTabLabel('Receitas', TransactionType.income),
          _buildTabLabel('Transf.', TransactionType.transfer),
        ],
      ),
    );
  }

  Widget _buildTabLabel(String text, TransactionType? type) {
    final count = type == null
        ? _allTransactions.length
        : _allTransactions.where((t) => t.type == type).length;
    return Tab(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(text, overflow: TextOverflow.ellipsis),
          ),
          if (count > 0 && !_isLoading) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Error banner ───
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _errorMessage = null);
              _loadTransactions();
            },
            child: const Icon(Icons.refresh_rounded,
                color: AppColors.error, size: 18),
          ),
        ],
      ),
    );
  }

  // ─── Lista de transações ───
  Widget _buildTransactionsList(TransactionType? filterType) {
    if (_isLoading) {
      return _buildListShimmer();
    }

    final filtered = _filteredByType(filterType);

    if (filtered.isEmpty) {
      return _buildEmptyState(filterType);
    }

    final grouped = _groupByDate(filtered);
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () => _loadTransactions(isRefresh: true),
      color: isDark ? AppColors.darkAccent : AppColors.primary,
      child: ListView.builder(
        controller: filterType == null ? _scrollController : null,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        itemCount: dates.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading more indicator
          if (index == dates.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? AppColors.darkAccent : AppColors.primary,
                  ),
                ),
              ),
            );
          }

          final dateKey = dates[index];
          final items = grouped[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : 12,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      _formatDateLabel(dateKey),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    const Spacer(),
                    // Subtotal do dia
                    Text(
                      _daySubtotal(items),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ],
                ),
              ),
              ...items.map((t) => _buildTransactionItem(t)),
            ],
          );
        },
      ),
    );
  }

  String _daySubtotal(List<TransactionEntity> items) {
    double total = 0;
    for (final t in items) {
      if (t.type == TransactionType.income) {
        total += t.amount;
      } else if (t.type == TransactionType.expense) {
        total -= t.amount;
      }
    }
    final sign = total >= 0 ? '+' : '-';
    return '$sign ${_formatCurrency(total.abs())}';
  }

  Widget _buildTransactionItem(TransactionEntity transaction) {
    final isExpense = transaction.type == TransactionType.expense;
    final isIncome = transaction.type == TransactionType.income;
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
    final formatted = '$sign ${_formatCurrency(transaction.amount)}';

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 24),
      ),
      confirmDismiss: (_) async {
        return await _showDeleteConfirmation(transaction);
      },
      onDismissed: (_) {
        Injection.instance.transactionRepository
            .deleteTransaction(transaction.id);
        setState(() {
          _allTransactions.removeWhere((t) => t.id == transaction.id);
          _calculateSummary();
        });
        _showSnackBar('Transação excluída', isError: false);
      },
      child: GestureDetector(
        onTap: () => _onTransactionTap(transaction),
        onLongPress: () => _showTransactionActions(transaction),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14142A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF252540)
                  : const Color(0xFFEEEEF2),
            ),
          ),
          child: Row(
            children: [
              // Ícone do tipo
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isExpense
                      ? Icons.arrow_downward_rounded
                      : isIncome
                          ? Icons.arrow_upward_rounded
                          : Icons.swap_horiz_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Descrição e categoria
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (transaction.categoryName != null) ...[
                          Flexible(
                            child: Text(
                              transaction.categoryName!,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDark ? Colors.white30 : Colors.black38,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (transaction.categoryName != null &&
                            !transaction.isPaid)
                          Text(
                            ' · ',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black26,
                            ),
                          ),
                        if (!transaction.isPaid)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Pendente',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Valor
              Text(
                formatted,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shimmer para lista ───
  Widget _buildListShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          height: 68,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14142A) : const Color(0xFFEEEEF2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C2E)
                      : const Color(0xFFE4E4E8),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1C2E)
                            : const Color(0xFFE4E4E8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 70,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1C2E)
                            : const Color(0xFFE4E4E8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 14,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C2E)
                      : const Color(0xFFE4E4E8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Estado vazio ───
  Widget _buildEmptyState(TransactionType? type) {
    final label = type == null
        ? 'transações'
        : type == TransactionType.expense
            ? 'despesas'
            : type == TransactionType.income
                ? 'receitas'
                : 'transferências';

    return Center(
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
              child: Icon(
                Icons.receipt_long_rounded,
                size: 32,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma $label',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Suas $label neste período\naparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black26,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                final initialType = type == TransactionType.income
                    ? 'INCOME'
                    : type == TransactionType.transfer
                        ? 'TRANSFER'
                        : 'EXPENSE';
                Navigator.pushNamed(
                  context,
                  AppRoutes.createTransaction,
                  arguments: initialType,
                ).then((result) {
                  if (result == true) _loadTransactions(isRefresh: true);
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkAccent.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: isDark ? AppColors.darkAccent : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Adicionar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkAccent
                            : AppColors.primary,
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

  // ─── Utils ───
  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }

  String _formatDateLabel(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Hoje';
    if (d == yesterday) return 'Ontem';
    return DateFormat("dd 'de' MMMM", 'pt_BR').format(date);
  }
}