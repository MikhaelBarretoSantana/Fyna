import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/services/bank_notification_service.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_bottom_nav.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
import 'package:fyna/feature/account/domain/entities/account_entity.dart';
import 'package:fyna/feature/account/presentation/pages/accounts.page.dart';
import 'package:fyna/feature/ai_classification/domain/entities/spending_pattern_entity.dart';
import 'package:fyna/feature/bank_notifications/presentation/widgets/bank_transaction_dialog.dart';
import 'package:fyna/feature/home/presentation/widgets/home_account_chips.dart';
import 'package:fyna/feature/home/presentation/widgets/home_ai_insight_card.dart';
import 'package:fyna/feature/home/presentation/widgets/home_balance_section.dart';
import 'package:fyna/feature/home/presentation/widgets/home_quick_actions.dart';
import 'package:fyna/feature/home/presentation/widgets/home_top_bar.dart';
import 'package:fyna/feature/home/presentation/widgets/home_transactions_section.dart';
import 'package:fyna/feature/notifications/domain/entities/notification_entity.dart';
import 'package:fyna/feature/planning/presentation/pages/planning.page.dart';
import 'package:fyna/feature/profile/presentation/pages/profile.page.dart';
import 'package:fyna/feature/transaction/domain/entities/transaction_entity.dart';
import 'package:fyna/feature/transaction/presentation/pages/transactions.page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedNavIndex = 0;
  int _selectedAccountIndex = 0;

  List<AccountEntity> _accounts = [];
  List<TransactionEntity> _transactions = [];
  List<SpendingPatternEntity> _patterns = [];
  int _unreadNotificationCount = 0;

  /// Incrementa toda vez que o usuário cria algo pelo FAB.
  /// Usado como ValueKey das sub-tabs (Transactions/Planning) para forçar
  /// remount e recarregamento ao retornar de telas de criação.
  int _refreshTick = 0;

  bool _isLoadingAccounts = true;
  bool _isLoadingTransactions = true;
  String? _errorMessage;

  final _bankNotificationService = BankNotificationService();
  StreamSubscription<ParsedBankTransaction>? _bankNotificationSub;
  StreamSubscription<NotificationEntity>? _notificationSocketSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startBankNotificationListener();
    _startNotificationSocket();
    Injection.instance.fcmService.requestPermissionAndRegister();
  }

  @override
  void dispose() {
    _bankNotificationSub?.cancel();
    _notificationSocketSub?.cancel();
    super.dispose();
  }

  void _startNotificationSocket() {
    final socket = Injection.instance.notificationSocketService;
    socket.connect();
    _notificationSocketSub = socket.notifications.listen((_) {
      if (!mounted) return;
      setState(() => _unreadNotificationCount += 1);
    });
  }

  void _startBankNotificationListener() {
    try {
      _bankNotificationSub = _bankNotificationService.transactionStream
          .listen(_onBankNotification);
    } catch (_) {
      // Canal indisponível — ignora
    }
    _processPendingBankNotifications();
  }

  Future<void> _processPendingBankNotifications() async {
    try {
      final pending = await _bankNotificationService.getPendingTransactions();
      if (pending.isEmpty) return;
      await _bankNotificationService.clearPending();
      await Future.doWhile(() async {
        if (!mounted) return false;
        if (_accounts.isNotEmpty) return false;
        await Future.delayed(const Duration(milliseconds: 200));
        return mounted && _accounts.isEmpty && _isLoadingAccounts;
      });
      for (final tx in pending) {
        if (!mounted) return;
        await _onBankNotification(tx);
      }
    } catch (e) {
      debugPrint('[Home] Erro ao processar notificações: $e');
    }
  }

  Future<void> _onBankNotification(ParsedBankTransaction tx) async {
    if (!mounted) return;
    final confirmed = await BankTransactionDialog.show(context, tx);
    if (confirmed != true || !mounted) return;

    try {
      final accountId = _accounts.isNotEmpty ? _accounts.first.id : null;
      if (accountId == null) return;

      await Injection.instance.transactionRepository.createTransaction(
        accountId: accountId,
        amount: tx.amount,
        description: tx.description,
        type: tx.type,
        transactionDate: tx.timestamp,
      );

      if (!mounted) return;
      final tc = ThemeColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transação de ${tx.bankName} registrada!'),
          backgroundColor: tc.neoPositive,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      final tc = ThemeColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Não foi possível registrar a transação.'),
          backgroundColor: tc.neoNegative,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadAccounts(),
      _loadUnreadNotificationCount(),
      _loadPatterns(),
    ]);
    await _loadTransactions();
  }

  /// Padrões de gasto detectados pela IA — usados para popular o card de
  /// insight da Home. Falha silenciosa quando o serviço de IA está indisponível.
  Future<void> _loadPatterns() async {
    try {
      final patterns =
          await Injection.instance.aiInsightsRepository.getActivePatterns();
      if (mounted) setState(() => _patterns = patterns);
    } catch (_) {
      if (mounted) setState(() => _patterns = []);
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count =
          await Injection.instance.notificationRepository.getUnreadCount();
      if (mounted) setState(() => _unreadNotificationCount = count);
    } catch (_) {
      if (mounted) setState(() => _unreadNotificationCount = 0);
    }
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts =
          await Injection.instance.accountRepository.getAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _isLoadingAccounts = false;
        if (_selectedAccountIndex >= _accounts.length) {
          _selectedAccountIndex = 0;
        }
      });
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoadingAccounts = false;
        });
      }
    } on NetworkException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sem conexão com a internet';
          _isLoadingAccounts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar contas';
          _isLoadingAccounts = false;
        });
      }
    }
  }

  Future<void> _loadTransactions() async {
    if (mounted) setState(() => _isLoadingTransactions = true);
    try {
      final selectedAccountId = _accounts.isNotEmpty
          ? _accounts[_selectedAccountIndex].id
          : null;

      final page = await Injection.instance.transactionRepository
          .getTransactions(page: 0, size: 50, accountId: selectedAccountId);
      if (mounted) {
        setState(() {
          _transactions = page.content;
          _isLoadingTransactions = false;
        });
      }
    } on ServerException {
      if (mounted) setState(() => _isLoadingTransactions = false);
    } on NetworkException {
      if (mounted) {
        setState(() {
          if (_accounts.isNotEmpty) {
            _errorMessage = 'Sem conexão com a internet';
          }
          _isLoadingTransactions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTransactions = false);
    }
  }

  /// Incrementa o tick e dispara reload — usado quando algo foi criado.
  /// Mudar o tick remonta as sub-tabs (Transactions/Planning) via ValueKey.
  void _bumpAndReload() {
    setState(() => _refreshTick++);
    _loadData();
  }

  Future<void> _navigateToCreateTransaction({String? initialType}) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.createTransaction,
      arguments: initialType,
    );
    if (result == true) _bumpAndReload();
  }

  Future<void> _navigateToCreateAccount() async {
    final result =
        await Navigator.pushNamed(context, AppRoutes.createAccount);
    if (result == true) _bumpAndReload();
  }

  void _showAddSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSheet(
        onExpense: () => _navigateToCreateTransaction(initialType: 'EXPENSE'),
        onIncome: () => _navigateToCreateTransaction(initialType: 'INCOME'),
        onTransfer: () => _navigateToCreateTransaction(initialType: 'TRANSFER'),
        onAccount: _navigateToCreateAccount,
      ),
    );
  }

  void _showMoreSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MoreSheet(
        unreadCount: _unreadNotificationCount,
        onCategories: () =>
            Navigator.pushNamed(context, AppRoutes.categories),
        onBudgets: () => Navigator.pushNamed(context, AppRoutes.budgets),
        onGoals: () => Navigator.pushNamed(context, AppRoutes.goals),
        onRecurring: () => Navigator.pushNamed(context, AppRoutes.recurring),
        onAi: () => Navigator.pushNamed(context, AppRoutes.aiInsights),
        onNotifications: () async {
          await Navigator.pushNamed(context, AppRoutes.notifications);
          if (mounted) await _loadUnreadNotificationCount();
        },
        onAccounts: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Scaffold(body: SafeArea(child: AccountsPage(isDark: isDark)));
            },
          ),
        ),
        onProfile: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Scaffold(body: SafeArea(child: ProfilePage(isDark: isDark)));
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final isDark = tc.isDark;

    Widget body;
    switch (_selectedNavIndex) {
      case 1:
        body = TransactionsPage(
          key: ValueKey('transactions-$_refreshTick'),
          isDark: isDark,
        );
        break;
      case 2:
        body = PlanningPage(
          key: ValueKey('planning-$_refreshTick'),
          isDark: isDark,
        );
        break;
      default:
        body = _buildHomeContent(tc);
    }

    return Scaffold(
      backgroundColor: tc.neoBackground,
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedNavIndex,
        onChanged: (i) {
          if (i == 3) {
            _showMoreSheet();
          } else {
            setState(() => _selectedNavIndex = i);
          }
        },
        items: const [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Início',
          ),
          AppBottomNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Transações',
          ),
          AppBottomNavItem(
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights_rounded,
            label: 'Planejamento',
          ),
          AppBottomNavItem(
            icon: Icons.grid_view_rounded,
            activeIcon: Icons.grid_view_rounded,
            label: 'Mais',
          ),
        ],
      ),
      floatingActionButton: AppCenterFab(onTap: _showAddSheet),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHomeContent(ThemeColors tc) {
    return Column(
      children: [
        HomeTopBar(
          hasUnread: _unreadNotificationCount > 0,
          onSearchTap: () =>
              Navigator.pushNamed(context, AppRoutes.aiInsights),
          onRefreshTap: _loadData,
          onNotificationsTap: () async {
            await Navigator.pushNamed(context, AppRoutes.notifications);
            if (mounted) await _loadUnreadNotificationCount();
          },
        ),
        if (!_isLoadingAccounts && _accounts.isNotEmpty)
          HomeAccountChips(
            accounts: _accounts,
            selectedIndex: _selectedAccountIndex,
            onChanged: (i) {
              setState(() => _selectedAccountIndex = i);
              _loadTransactions();
            },
          ),
        if (_isLoadingAccounts) _buildShimmerChips(tc),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: tc.neoTeal,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  if (_errorMessage != null) _buildErrorBanner(tc),
                  if (!_isLoadingAccounts && _accounts.isEmpty)
                    _buildEmptyAccountsState(tc),
                  if (_accounts.isNotEmpty) ...[
                    HomeBalanceSection(
                      balance: _accounts[_selectedAccountIndex].currentBalance,
                      currencyCode: _accounts[_selectedAccountIndex].name,
                      isDark: tc.isDark,
                      isLoading: _isLoadingAccounts,
                      accountType:
                          _accounts[_selectedAccountIndex].type.label,
                      institution:
                          _accounts[_selectedAccountIndex].institution,
                      accountColor: _accounts[_selectedAccountIndex].color,
                      monthIncome: _sumOfType(TransactionType.income),
                      monthExpense: _sumOfType(TransactionType.expense),
                    ),
                    HomeQuickActions(
                      isDark: tc.isDark,
                      onAddExpense: () => _navigateToCreateTransaction(
                          initialType: 'EXPENSE'),
                      onAddIncome: () => _navigateToCreateTransaction(
                          initialType: 'INCOME'),
                      onAddTransfer: () => _navigateToCreateTransaction(
                          initialType: 'TRANSFER'),
                      onAddAccount: _navigateToCreateAccount,
                    ),
                    HomeAiInsightCard(
                      message: _patterns.isNotEmpty
                          ? _patterns.first.description
                          : 'Acompanhe sua análise inteligente de gastos.',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.aiInsights),
                    ),
                    HomeTransactionsSection(
                      isDark: tc.isDark,
                      transactions: _transactions,
                      isLoading: _isLoadingTransactions,
                      accountName: _accounts[_selectedAccountIndex].name,
                    ),
                  ],
                  if (_isLoadingAccounts) ...[
                    HomeBalanceSection(
                      balance: 0,
                      currencyCode: '',
                      isDark: tc.isDark,
                      isLoading: true,
                    ),
                    HomeQuickActions(
                      isDark: tc.isDark,
                      onAddExpense: () => _navigateToCreateTransaction(
                          initialType: 'EXPENSE'),
                      onAddIncome: () => _navigateToCreateTransaction(
                          initialType: 'INCOME'),
                      onAddTransfer: () => _navigateToCreateTransaction(
                          initialType: 'TRANSFER'),
                      onAddAccount: _navigateToCreateAccount,
                    ),
                    HomeTransactionsSection(isDark: tc.isDark, isLoading: true),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _sumOfType(TransactionType type) {
    return _transactions
        .where((t) => t.type == type)
        .fold<double>(0, (acc, t) => acc + t.amount);
  }

  Widget _buildShimmerChips(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 44,
        child: Row(
          children: List.generate(3, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  color: tc.neoCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: tc.neoCardBorder),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeColors tc) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tc.neoNegative.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tc.neoNegative.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: tc.neoNegative, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(fontSize: 13, color: tc.neoText),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _errorMessage = null);
              _loadData();
            },
            child: Icon(Icons.refresh_rounded,
                color: tc.neoNegative, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAccountsState(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          gradient: tc.heroGradient,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Bem-vindo ao Fyna!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Adicione sua primeira conta para começar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                      context, AppRoutes.createAccount);
                  if (result == true) _loadData();
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Criar primeira conta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0E3D4A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSheet extends StatelessWidget {
  final VoidCallback onExpense;
  final VoidCallback onIncome;
  final VoidCallback onTransfer;
  final VoidCallback onAccount;

  const _AddSheet({
    required this.onExpense,
    required this.onIncome,
    required this.onTransfer,
    required this.onAccount,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottom > 0 ? 16 : 28),
        decoration: BoxDecoration(
          color: tc.neoCardElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'O que deseja adicionar?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tc.neoText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _option(
              context,
              icon: Icons.south_rounded,
              tone: 'success',
              label: 'Nova receita',
              subtitle: 'Registrar um ganho',
              onTap: () {
                Navigator.pop(context);
                onIncome();
              },
            ),
            const SizedBox(height: 8),
            _option(
              context,
              icon: Icons.north_rounded,
              tone: 'danger',
              label: 'Nova despesa',
              subtitle: 'Registrar um gasto',
              onTap: () {
                Navigator.pop(context);
                onExpense();
              },
            ),
            const SizedBox(height: 8),
            _option(
              context,
              icon: Icons.swap_horiz_rounded,
              tone: 'info',
              label: 'Nova transferência',
              subtitle: 'Mover entre contas',
              onTap: () {
                Navigator.pop(context);
                onTransfer();
              },
            ),
            const SizedBox(height: 8),
            _option(
              context,
              icon: Icons.account_balance_rounded,
              tone: 'transfer',
              label: 'Nova conta',
              subtitle: 'Adicionar conta bancária',
              onTap: () {
                Navigator.pop(context);
                onAccount();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required String tone,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final tc = ThemeColors.of(context);
    return Material(
      color: tc.neoCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tc.neoCardBorder),
          ),
          child: Row(
            children: [
              IconBadge(icon: icon, tone: tone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: tc.neoText,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: tc.neoTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: tc.neoTextFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreSheet extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onCategories;
  final VoidCallback onBudgets;
  final VoidCallback onGoals;
  final VoidCallback onRecurring;
  final VoidCallback onAi;
  final VoidCallback onNotifications;
  final VoidCallback onAccounts;
  final VoidCallback onProfile;

  const _MoreSheet({
    required this.unreadCount,
    required this.onCategories,
    required this.onBudgets,
    required this.onGoals,
    required this.onRecurring,
    required this.onAi,
    required this.onNotifications,
    required this.onAccounts,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;

    final items = <_MoreItem>[
      _MoreItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Contas',
        tone: 'transfer',
        onTap: onAccounts,
      ),
      _MoreItem(
        icon: Icons.auto_awesome_rounded,
        label: 'AI Insights',
        tone: 'ai',
        onTap: onAi,
      ),
      _MoreItem(
        icon: Icons.notifications_none_rounded,
        label: 'Notificações',
        tone: 'warning',
        onTap: onNotifications,
        badge: unreadCount > 0,
      ),
      _MoreItem(
        icon: Icons.category_rounded,
        label: 'Categorias',
        tone: 'shopping',
        onTap: onCategories,
      ),
      _MoreItem(
        icon: Icons.replay_rounded,
        label: 'Recorrentes',
        tone: 'success',
        onTap: onRecurring,
      ),
      _MoreItem(
        icon: Icons.bar_chart_rounded,
        label: 'Orçamentos',
        tone: 'danger',
        onTap: onBudgets,
      ),
      _MoreItem(
        icon: Icons.flag_rounded,
        label: 'Metas',
        tone: 'warning',
        onTap: onGoals,
      ),
      _MoreItem(
        icon: Icons.person_rounded,
        label: 'Perfil',
        tone: 'neutral',
        onTap: onProfile,
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottom > 0 ? 12 : 28),
        decoration: BoxDecoration(
          color: tc.neoCardElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            Row(
              children: [
                Text(
                  'Mais opções',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tc.neoText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: tc.neoTextMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.82,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    item.onTap();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconBadge(
                            icon: item.icon,
                            tone: item.tone,
                            size: 52,
                            iconSize: 24,
                            radius: 16,
                          ),
                          if (item.badge)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: tc.neoNegative,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: tc.neoCardElevated, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: tc.neoTextMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final String tone;
  final VoidCallback onTap;
  final bool badge;

  _MoreItem({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
    this.badge = false,
  });
}
