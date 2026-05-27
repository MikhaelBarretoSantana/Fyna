import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_list_item.dart';
import 'package:fyna/core/widgets/app_pill_tabs.dart';
import 'package:fyna/core/widgets/app_screen_header.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
import 'package:fyna/feature/transaction/domain/entities/transaction_entity.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends StatefulWidget {
  final bool isDark;
  const TransactionsPage({super.key, required this.isDark});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  int _selectedFilter = 0; // 0=Todas, 1=Receitas, 2=Despesas, 3=Transferências
  String _selectedPeriod = 'Mês';
  final List<String> _periods = ['Semana', 'Mês', 'Ano'];

  List<TransactionEntity> _allTransactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 0;
  static const int _pageSize = 30;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTransactions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Semana':
        final weekday = now.weekday;
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
        return DateTime(now.year, now.month + 1, 0);
    }
  }

  String get _periodHeadline {
    switch (_selectedPeriod) {
      case 'Semana':
        return 'Esta semana';
      case 'Ano':
        return DateFormat('y', 'pt_BR').format(_startDate);
      case 'Mês':
      default:
        return toBeginningOfSentenceCase(
              DateFormat('MMMM', 'pt_BR').format(_startDate),
            ) ??
            'Mês';
    }
  }

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

  void _showPeriodSheet() {
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Período',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: tc.neoText,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._periods.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppListItem(
                      leading: IconBadge(
                        icon: Icons.calendar_today_rounded,
                        tone: p == _selectedPeriod ? 'transfer' : 'neutral',
                      ),
                      title: p,
                      trailing: p == _selectedPeriod
                          ? Icon(Icons.check_rounded, color: tc.neoTeal)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        if (p != _selectedPeriod) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedPeriod = p);
                          _loadTransactions(isRefresh: true);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<TransactionEntity> _filteredList() {
    switch (_selectedFilter) {
      case 1:
        return _allTransactions
            .where((t) => t.type == TransactionType.income)
            .toList();
      case 2:
        return _allTransactions
            .where((t) => t.type == TransactionType.expense)
            .toList();
      case 3:
        return _allTransactions
            .where((t) => t.type == TransactionType.transfer)
            .toList();
      default:
        return _allTransactions;
    }
  }

  Future<void> _onDelete(TransactionEntity tx) async {
    final confirmed = await _confirmDelete(tx);
    if (confirmed != true) return;
    try {
      await Injection.instance.transactionRepository.deleteTransaction(tx.id);
      if (mounted) {
        setState(() {
          _allTransactions.removeWhere((t) => t.id == tx.id);
          _calculateSummary();
        });
        _snack('Transação excluída', isError: false);
      }
    } on ServerException catch (e) {
      _snack(e.message);
    } on NetworkException {
      _snack('Sem conexão com a internet');
    } catch (_) {
      _snack('Erro ao excluir transação');
    }
  }

  Future<bool?> _confirmDelete(TransactionEntity tx) {
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
            'Excluir transação?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tc.neoText,
            ),
          ),
          content: Text(
            '"${tx.description}" de ${_formatCurrency(tx.amount)} será excluída '
            'e o saldo da conta será ajustado. Essa ação não pode ser desfeita.',
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

  Future<void> _onTogglePaid(TransactionEntity tx) async {
    final newPaid = !tx.isPaid;
    try {
      await Injection.instance.transactionRepository.updateTransaction(
        id: tx.id,
        isPaid: newPaid,
      );
      if (!mounted) return;
      setState(() {
        final idx = _allTransactions.indexWhere((t) => t.id == tx.id);
        if (idx != -1) {
          _allTransactions[idx] = TransactionEntity(
            id: tx.id,
            accountId: tx.accountId,
            categoryId: tx.categoryId,
            categoryName: tx.categoryName,
            transferPairId: tx.transferPairId,
            type: tx.type,
            amount: tx.amount,
            description: tx.description,
            notes: tx.notes,
            transactionDate: tx.transactionDate,
            dueDate: tx.dueDate,
            isPaid: newPaid,
            isRecurring: tx.isRecurring,
            recurringTransactionId: tx.recurringTransactionId,
            attachmentUrl: tx.attachmentUrl,
            createdAt: tx.createdAt,
          );
        }
      });
      _snack(newPaid ? 'Marcada como paga' : 'Marcada como pendente',
          isError: false);
    } catch (_) {
      _snack('Erro ao atualizar status');
    }
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

  void _showActions(TransactionEntity tx) {
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
                    icon: tx.isPaid
                        ? Icons.remove_circle_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    tone: tx.isPaid ? 'warning' : 'success',
                  ),
                  title: tx.isPaid
                      ? 'Marcar como pendente'
                      : 'Marcar como paga',
                  onTap: () {
                    Navigator.pop(ctx);
                    _onTogglePaid(tx);
                  },
                ),
                const SizedBox(height: 8),
                AppListItem(
                  leading: IconBadge(
                    icon: Icons.delete_outline_rounded,
                    tone: 'danger',
                  ),
                  title: 'Excluir transação',
                  onTap: () {
                    Navigator.pop(ctx);
                    _onDelete(tx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final filtered = _filteredList();
    final balance = _totalIncome - _totalExpense;

    return Column(
      children: [
        AppScreenHeader(
          title: 'Transações',
          subtitle: _isLoading
              ? 'Carregando...'
              : '$_periodHeadline · ${_allTransactions.length} lançamentos',
          showBack: false,
          actions: [
            HeaderActionButton(
              icon: Icons.tune_rounded,
              onTap: _showPeriodSheet,
              tooltip: 'Período',
            ),
          ],
        ),
        AppPillTabs(
          labels: const ['Todas', 'Receitas', 'Despesas', 'Transferências'],
          selectedIndex: _selectedFilter,
          onChanged: (i) => setState(() => _selectedFilter = i),
        ),
        const SizedBox(height: 14),
        _isLoading
            ? _summaryShimmer(tc)
            : _summaryCards(tc, balance),
        const SizedBox(height: 12),
        if (_errorMessage != null && !_isLoading) _errorBanner(tc),
        Expanded(
          child: _isLoading
              ? _listShimmer(tc)
              : filtered.isEmpty
                  ? _emptyState(tc)
                  : RefreshIndicator(
                      onRefresh: () => _loadTransactions(isRefresh: true),
                      color: tc.neoTeal,
                      child: _buildList(filtered, tc),
                    ),
        ),
      ],
    );
  }

  Widget _summaryCards(ThemeColors tc, double balance) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Entrou',
              value: _formatCurrency(_totalIncome),
              accent: tc.neoPositive,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              label: 'Saiu',
              value: _formatCurrency(_totalExpense),
              accent: tc.neoNegative,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              label: 'Saldo',
              value: _formatCurrency(balance.abs()),
              accent: balance >= 0 ? tc.neoText : tc.neoNegative,
              prefix: balance < 0 ? '- ' : '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryShimmer(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
              height: 72,
              decoration: BoxDecoration(
                color: tc.neoCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tc.neoCardBorder),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _errorBanner(ThemeColors tc) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
            onTap: () {
              setState(() => _errorMessage = null);
              _loadTransactions();
            },
            child:
                Icon(Icons.refresh_rounded, color: tc.neoNegative, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<TransactionEntity> items, ThemeColors tc) {
    final grouped = <String, List<TransactionEntity>>{};
    for (final t in items) {
      final key = DateFormat('yyyy-MM-dd').format(t.transactionDate);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
      itemCount: dates.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, idx) {
        if (idx == dates.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tc.neoTeal,
                ),
              ),
            ),
          );
        }

        final dateKey = dates[idx];
        final dayItems = grouped[dateKey]!;
        final dayTotal = _daySubtotal(dayItems);
        final isPositive = dayTotal >= 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDateLabel(dateKey).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: tc.neoTextFaint,
                      ),
                    ),
                  ),
                  Text(
                    '${isPositive ? '+' : '-'}R\$ ${_formatRawAmount(dayTotal.abs())}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isPositive ? tc.neoPositive : tc.neoNegative,
                    ),
                  ),
                ],
              ),
            ),
            for (final t in dayItems) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: tc.neoNegative.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.delete_outline_rounded,
                        color: tc.neoNegative, size: 22),
                  ),
                  confirmDismiss: (_) => _confirmDelete(t),
                  onDismissed: (_) {
                    Injection.instance.transactionRepository
                        .deleteTransaction(t.id);
                    setState(() {
                      _allTransactions.removeWhere((x) => x.id == t.id);
                      _calculateSummary();
                    });
                    _snack('Transação excluída', isError: false);
                  },
                  child: AppListItem(
                    leading: IconBadge(
                      icon: _iconFor(t),
                      tone: _toneFor(t),
                    ),
                    title: t.description,
                    subtitle: _subtitleFor(t),
                    trailing: Text(
                      '${_signFor(t)}R\$ ${_formatRawAmount(t.amount)}',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _amountColor(t, tc),
                      ),
                    ),
                    onTap: () => _showActions(t),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _emptyState(ThemeColors tc) {
    final label = _selectedFilter == 0
        ? 'transações'
        : _selectedFilter == 1
            ? 'receitas'
            : _selectedFilter == 2
                ? 'despesas'
                : 'transferências';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconBadge(
              icon: Icons.receipt_long_rounded,
              tone: 'neutral',
              size: 64,
              iconSize: 28,
              radius: 18,
            ),
            const SizedBox(height: 14),
            Text(
              'Nenhuma $label',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: tc.neoTextMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Suas $label neste período\naparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: tc.neoTextFaint,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                final initialType = _selectedFilter == 1
                    ? 'INCOME'
                    : _selectedFilter == 3
                        ? 'TRANSFER'
                        : 'EXPENSE';
                Navigator.pushNamed(
                  context,
                  AppRoutes.createTransaction,
                  arguments: initialType,
                ).then((r) {
                  if (r == true) _loadTransactions(isRefresh: true);
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: tc.neoTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Adicionar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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

  Widget _listShimmer(ThemeColors tc) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 64,
          decoration: BoxDecoration(
            color: tc.neoCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tc.neoCardBorder),
          ),
        );
      },
    );
  }

  double _daySubtotal(List<TransactionEntity> items) {
    double total = 0;
    for (final t in items) {
      if (t.type == TransactionType.income) {
        total += t.amount;
      } else if (t.type == TransactionType.expense) {
        total -= t.amount;
      }
    }
    return total;
  }

  String _formatCurrency(double value) =>
      'R\$ ${_formatRawAmount(value)}';

  String _formatRawAmount(double value) {
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$intPart,${parts[1]}';
  }

  String _formatDateLabel(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Hoje · ${DateFormat('dd MMM', 'pt_BR').format(date)}';
    if (d == yesterday) {
      return 'Ontem · ${DateFormat('dd MMM', 'pt_BR').format(date)}';
    }
    return DateFormat("dd 'de' MMMM", 'pt_BR').format(date);
  }

  String _subtitleFor(TransactionEntity t) {
    final parts = <String>[];
    if (t.categoryName != null && t.categoryName!.isNotEmpty) {
      parts.add(t.categoryName!);
    }
    if (!t.isPaid) parts.add('Pendente');
    return parts.join(' · ');
  }

  String _signFor(TransactionEntity t) {
    if (t.type == TransactionType.income) return '+';
    if (t.type == TransactionType.expense) return '-';
    return '';
  }

  Color _amountColor(TransactionEntity t, ThemeColors tc) {
    if (t.type == TransactionType.income) return tc.neoPositive;
    if (t.type == TransactionType.expense) return tc.neoNegative;
    return tc.neoTeal;
  }

  String _toneFor(TransactionEntity t) {
    if (t.type == TransactionType.transfer) return 'transfer';
    final cat = (t.categoryName ?? '').toLowerCase();
    if (cat.contains('aliment') ||
        cat.contains('comida') ||
        cat.contains('delivery') ||
        cat.contains('ifood') ||
        cat.contains('restaur')) {
      return 'food';
    }
    if (cat.contains('transp') || cat.contains('uber') || cat.contains('99')) {
      return 'transport';
    }
    if (cat.contains('mercado') ||
        cat.contains('compras') ||
        cat.contains('shopping')) {
      return 'shopping';
    }
    if (cat.contains('saúde') ||
        cat.contains('saude') ||
        cat.contains('médic')) {
      return 'health';
    }
    if (cat.contains('lazer') || cat.contains('entreten')) {
      return 'entertainment';
    }
    if (cat.contains('contas') ||
        cat.contains('aluguel') ||
        cat.contains('condomín')) {
      return 'bills';
    }
    if (cat.contains('salár') || cat.contains('salario')) return 'salary';
    return t.type == TransactionType.income ? 'success' : 'neutral';
  }

  IconData _iconFor(TransactionEntity t) {
    if (t.type == TransactionType.transfer) return Icons.swap_horiz_rounded;
    final cat = (t.categoryName ?? '').toLowerCase();
    if (cat.contains('delivery') || cat.contains('ifood')) {
      return Icons.delivery_dining_rounded;
    }
    if (cat.contains('mercado') || cat.contains('compras')) {
      return Icons.shopping_cart_rounded;
    }
    if (cat.contains('aliment') || cat.contains('restaur')) {
      return Icons.restaurant_rounded;
    }
    if (cat.contains('transp') || cat.contains('uber') || cat.contains('99')) {
      return Icons.directions_car_rounded;
    }
    if (cat.contains('salár') || cat.contains('salario')) {
      return Icons.flash_on_rounded;
    }
    if (cat.contains('saúde') || cat.contains('saude')) {
      return Icons.medical_services_rounded;
    }
    if (cat.contains('lazer')) return Icons.sports_esports_rounded;
    if (cat.contains('aluguel') || cat.contains('moradia')) {
      return Icons.home_rounded;
    }
    if (cat.contains('contas')) return Icons.receipt_long_rounded;
    return t.type == TransactionType.income
        ? Icons.south_rounded
        : Icons.north_rounded;
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final String prefix;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.accent,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
              '$prefix$value',
              style: TextStyle(
                fontSize: 15,
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
