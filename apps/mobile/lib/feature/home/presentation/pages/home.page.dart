import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/services/bank_notification_service.dart';
import 'package:fyna/feature/account/domain/entities/account_entity.dart';
import 'package:fyna/feature/transaction/domain/entities/transaction_entity.dart';
import 'package:fyna/feature/home/presentation/widgets/home_balance_section.dart';
import 'package:fyna/feature/home/presentation/widgets/home_quick_actions.dart';
import 'package:fyna/feature/home/presentation/widgets/home_transactions_section.dart';
import 'package:fyna/feature/profile/presentation/pages/profile.page.dart';
import 'package:fyna/feature/transaction/presentation/pages/transactions.page.dart';
import 'package:fyna/feature/account/presentation/pages/accounts.page.dart';
import 'package:fyna/feature/planning/presentation/pages/planning.page.dart';
import 'package:fyna/feature/bank_notifications/presentation/widgets/bank_transaction_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedNavIndex = 0;
  int _selectedAccountIndex = 0;

  // Dados reais do backend
  List<AccountEntity> _accounts = [];
  List<TransactionEntity> _transactions = [];

  bool _isLoadingAccounts = true;
  bool _isLoadingTransactions = true;
  String? _errorMessage;

  // Animação para o indicador do nav
  late AnimationController _navIndicatorController;

  // Notificações bancárias
  final _bankNotificationService = BankNotificationService();
  StreamSubscription<ParsedBankTransaction>? _bankNotificationSub;

  @override
  void initState() {
    super.initState();
    _navIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _loadData();
    _startBankNotificationListener();
  }

  @override
  void dispose() {
    _navIndicatorController.dispose();
    _bankNotificationSub?.cancel();
    super.dispose();
  }

  void _startBankNotificationListener() {
    try {
      _bankNotificationSub = _bankNotificationService.transactionStream
          .listen(_onBankNotification);
    } catch (_) {
      // Canal não disponível (iOS ou sem permissão) — ignora silenciosamente
    }
    // Processa notificações que chegaram com o app fechado
    _processPendingBankNotifications();
  }

  Future<void> _processPendingBankNotifications() async {
    try {
      final pending = await _bankNotificationService.getPendingTransactions();
      if (pending.isEmpty) return;

      // Limpa a fila ANTES de processar para evitar duplicação
      await _bankNotificationService.clearPending();

      // Espera as contas carregarem antes de processar
      await Future.doWhile(() async {
        if (!mounted) return false;
        if (_accounts.isNotEmpty) return false;
        await Future.delayed(const Duration(milliseconds: 200));
        return mounted && _accounts.isEmpty && _isLoadingAccounts;
      });

      // Processa uma de cada vez (mostra o dialog sequencialmente)
      for (final tx in pending) {
        if (!mounted) return;
        await _onBankNotification(tx);
      }
    } catch (e) {
      debugPrint('[Home] Erro ao processar fila de notificações: $e');
    }
  }

  Future<void> _onBankNotification(ParsedBankTransaction tx) async {
    if (!mounted) return;
    final confirmed = await BankTransactionDialog.show(context, tx);
    if (confirmed != true || !mounted) return;

    try {
      // Pega a primeira conta disponível para registrar
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transação de ${tx.bankName} registrada!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Não foi possível registrar a transação.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadAccounts(),
    ]);
    await _loadTransactions();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts =
          await Injection.instance.accountRepository.getAccounts();
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _isLoadingAccounts = false;
          if (_selectedAccountIndex >= _accounts.length) {
            _selectedAccountIndex = 0;
          }
        });
      }
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
    if (mounted) {
      setState(() => _isLoadingTransactions = true);
    }
    try {
      final selectedAccountId = _accounts.isNotEmpty
          ? _accounts[_selectedAccountIndex].id
          : null;

      final page =
          await Injection.instance.transactionRepository.getTransactions(
        page: 0,
        size: 50,
        accountId: selectedAccountId,
      );
      if (mounted) {
        setState(() {
          _transactions = page.content;
          _isLoadingTransactions = false;
        });
      }
    } on ServerException {
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
        });
      }
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
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
        });
      }
    }
  }

  // ─── Navegação para criação ───
  Future<void> _navigateToCreateTransaction({String? initialType}) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.createTransaction,
      arguments: initialType,
    );
    if (result == true) _loadData();
  }

  Future<void> _navigateToCreateAccount() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.createAccount,
    );
    if (result == true) _loadData();
  }

  void _showAddBottomSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      // Builder garante que o sheet reaja a mudanças de tema em tempo real
      builder: (_) => Builder(builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return _buildAddSheet(ctx, isDark);
      }),
    );
  }

  // ─── Bottom sheet "Mais" com grid de funcionalidades ───
  void _showMoreBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Builder(builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return _buildMoreSheet(ctx, isDark);
      }),
    );
  }

  Widget _buildMoreSheet(BuildContext ctx, bool isDark) {
    final bottomPadding = MediaQuery.of(ctx).padding.bottom;

    final menuItems = [
      _MoreMenuItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Contas',
        color: isDark ? AppColors.darkAccent : AppColors.primary,
        onTap: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                body: SafeArea(
                  child: AccountsPage(isDark: isDark),
                ),
              ),
            ),
          );
        },
      ),
      _MoreMenuItem(
        icon: Icons.smart_toy_rounded,
        label: 'AI Insights',
        color: const Color(0xFF7C5CFC),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, AppRoutes.aiInsights);
        },
      ),
      _MoreMenuItem(
        icon: Icons.notifications_outlined,
        label: 'Notificações',
        color: const Color(0xFFE8893C),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, AppRoutes.notifications);
        },
      ),
      _MoreMenuItem(
        icon: Icons.category_rounded,
        label: 'Categorias',
        color: const Color(0xFF3CADE8),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, AppRoutes.categories);
        },
      ),
      _MoreMenuItem(
        icon: Icons.replay_rounded,
        label: 'Recorrentes',
        color: const Color(0xFF5CB85C),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, AppRoutes.recurring);
        },
      ),
      _MoreMenuItem(
        icon: Icons.bar_chart_rounded,
        label: 'Orçamentos',
        color: const Color(0xFFE85D5D),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, AppRoutes.budgets);
        },
      ),
      _MoreMenuItem(
        icon: Icons.flag_rounded,
        label: 'Metas',
        color: const Color(0xFFE8893C),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, AppRoutes.goals);
        },
      ),
      _MoreMenuItem(
        icon: Icons.person_rounded,
        label: 'Perfil',
        color: isDark ? Colors.white60 : Colors.black54,
        onTap: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                body: SafeArea(
                  child: ProfilePage(isDark: isDark),
                ),
              ),
            ),
          );
        },
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding > 0 ? 12 : 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14142A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            const SizedBox(height: 20),
            // Header
            Row(
              children: [
                Text(
                  'Mais opções',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Grid 4x2
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _buildMoreGridItem(
                  isDark: isDark,
                  icon: item.icon,
                  label: item.label,
                  color: item.color,
                  onTap: item.onTap,
                  badge: item.label == 'Notificações',
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreGridItem({
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (badge)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF14142A) : Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAddSheet(BuildContext ctx, bool isDark) {
    final bottomPadding = MediaQuery.of(ctx).padding.bottom;
    final screenHeight = MediaQuery.of(ctx).size.height;
    final isSmallScreen = screenHeight < 700;
    final verticalSpacing = isSmallScreen ? 6.0 : 8.0;
    final itemPadding = isSmallScreen
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding > 0 ? 12 : 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14142A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'O que deseja adicionar?',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildSheetOption(
              isDark: isDark,
              icon: Icons.arrow_downward_rounded,
              label: 'Nova despesa',
              subtitle: 'Registrar um gasto',
              color: AppColors.error,
              padding: itemPadding,
              onTap: () {
                Navigator.pop(ctx);
                _navigateToCreateTransaction(initialType: 'EXPENSE');
              },
            ),
            SizedBox(height: verticalSpacing),
            _buildSheetOption(
              isDark: isDark,
              icon: Icons.arrow_upward_rounded,
              label: 'Nova receita',
              subtitle: 'Registrar um ganho',
              color: AppColors.success,
              padding: itemPadding,
              onTap: () {
                Navigator.pop(ctx);
                _navigateToCreateTransaction(initialType: 'INCOME');
              },
            ),
            SizedBox(height: verticalSpacing),
            _buildSheetOption(
              isDark: isDark,
              icon: Icons.swap_horiz_rounded,
              label: 'Nova transferência',
              subtitle: 'Mover entre contas',
              color: AppColors.info,
              padding: itemPadding,
              onTap: () {
                Navigator.pop(ctx);
                _navigateToCreateTransaction(initialType: 'TRANSFER');
              },
            ),
            SizedBox(height: verticalSpacing),
            _buildSheetOption(
              isDark: isDark,
              icon: Icons.account_balance_rounded,
              label: 'Nova conta',
              subtitle: 'Adicionar conta bancária',
              color: isDark ? AppColors.darkAccent : AppColors.primary,
              padding: itemPadding,
              onTap: () {
                Navigator.pop(ctx);
                _navigateToCreateAccount();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption({
    required bool isDark,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? color.withValues(alpha: 0.05)
                : color.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? color.withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white38 : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white24 : Colors.black26,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Mapeia index do nav para páginas
    // 0 = Início (home), 1 = Transações, 2 = Planejamento, 3 = Mais (abre sheet)
    Widget body;
    switch (_selectedNavIndex) {
      case 1:
        body = TransactionsPage(isDark: isDark);
        break;
      case 2:
        body = PlanningPage(isDark: isDark);
        break;
      default:
        body = _buildHomeContent(isDark);
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F5F8),
      body: SafeArea(
        bottom: false,
        child: body,
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
      floatingActionButton: _buildFab(isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHomeContent(bool isDark) {
    return Column(
      children: [
        _buildTopBar(isDark),
        if (!_isLoadingAccounts && _accounts.isNotEmpty)
          _buildAccountSelector(isDark),
        if (_isLoadingAccounts)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildShimmerSelector(isDark),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: isDark ? AppColors.darkAccent : AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  if (_errorMessage != null) _buildErrorBanner(isDark),
                  if (!_isLoadingAccounts && _accounts.isEmpty)
                    _buildEmptyAccountsState(isDark),
                  if (_accounts.isNotEmpty) ...[
                    HomeBalanceSection(
                      balance: _accounts[_selectedAccountIndex].currentBalance,
                      currencyCode: _accounts[_selectedAccountIndex].name,
                      isDark: isDark,
                      isLoading: _isLoadingAccounts,
                      accountType:
                          _accounts[_selectedAccountIndex].type.label,
                      institution:
                          _accounts[_selectedAccountIndex].institution,
                      accountColor:
                          _accounts[_selectedAccountIndex].color,
                    ),
                    HomeQuickActions(
                      isDark: isDark,
                      onAddExpense: () => _navigateToCreateTransaction(
                          initialType: 'EXPENSE'),
                      onAddIncome: () => _navigateToCreateTransaction(
                          initialType: 'INCOME'),
                      onAddTransfer: () => _navigateToCreateTransaction(
                          initialType: 'TRANSFER'),
                      onAddAccount: _navigateToCreateAccount,
                    ),
                    HomeTransactionsSection(
                      isDark: isDark,
                      transactions: _transactions,
                      isLoading: _isLoadingTransactions,
                      accountName: _accounts[_selectedAccountIndex].name,
                    ),
                  ],
                  if (_isLoadingAccounts) ...[
                    HomeBalanceSection(
                      balance: 0,
                      currencyCode: '',
                      isDark: isDark,
                      isLoading: true,
                    ),
                    HomeQuickActions(
                      isDark: isDark,
                      onAddExpense: () => _navigateToCreateTransaction(
                          initialType: 'EXPENSE'),
                      onAddIncome: () => _navigateToCreateTransaction(
                          initialType: 'INCOME'),
                      onAddTransfer: () => _navigateToCreateTransaction(
                          initialType: 'TRANSFER'),
                      onAddAccount: _navigateToCreateAccount,
                    ),
                    HomeTransactionsSection(
                      isDark: isDark,
                      isLoading: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFab(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: FloatingActionButton(
        onPressed: _showAddBottomSheet,
        elevation: 6,
        backgroundColor: isDark ? AppColors.darkAccent : AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1C2E)
                    : const Color(0xFFEEEEF2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white54 : Colors.black38,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Buscar',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiInsights),
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.notifications_none_rounded,
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
            badge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C1C2E)
                  : const Color(0xFFEEEEF2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 22,
            ),
          ),
          if (badge)
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Bottom Navigation melhorada ───
  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              // ─ Lado esquerdo (2 itens) ─
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      icon: Icons.home_rounded,
                      activeIcon: Icons.home_rounded,
                      label: 'Início',
                      index: 0,
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      icon: Icons.receipt_long_outlined,
                      activeIcon: Icons.receipt_long_rounded,
                      label: 'Transações',
                      index: 1,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              // ─ Espaço central para o FAB ─
              const SizedBox(width: 72),
              // ─ Lado direito (2 itens) ─
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      icon: Icons.insights_outlined,
                      activeIcon: Icons.insights_rounded,
                      label: 'Planejar',
                      index: 2,
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      icon: Icons.grid_view_rounded,
                      activeIcon: Icons.grid_view_rounded,
                      label: 'Mais',
                      index: 3,
                      isDark: isDark,
                      isMoreButton: true,
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

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isDark,
    bool isMoreButton = false,
  }) {
    final isSelected = _selectedNavIndex == index && !isMoreButton;
    final Color activeColor =
        isDark ? AppColors.darkAccent : AppColors.primary;
    final Color inactiveColor = isDark ? Colors.white30 : Colors.black26;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (isMoreButton) {
          _showMoreBottomSheet();
        } else {
          setState(() => _selectedNavIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador animado (pill acima do ícone)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isSelected ? 24 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemCount = _accounts.length;
          const spacing = 10.0;

          if (itemCount > 3) {
            return SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: itemCount,
                separatorBuilder: (_, __) => const SizedBox(width: spacing),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: (constraints.maxWidth - spacing * 2) / 3,
                    child: _buildAccountChip(index, isDark),
                  );
                },
              ),
            );
          }

          return Row(
            children: List.generate(itemCount, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < itemCount - 1 ? spacing : 0,
                  ),
                  child: _buildAccountChip(index, isDark),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Color _parseAccountColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return AppColors.primary;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return AppColors.primary;
    return Color(0xFF000000 | value);
  }

  Widget _buildAccountChip(int index, bool isDark) {
    final account = _accounts[index];
    final isSelected = index == _selectedAccountIndex;
    final accountColor = _parseAccountColor(account.color);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedAccountIndex = index);
        _loadTransactions();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? HSLColor.fromColor(accountColor)
                      .withLightness(0.18)
                      .toColor()
                  : accountColor)
              : (isDark
                  ? const Color(0xFF1C1C2E)
                  : const Color(0xFFEEEEF2)),
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(
                  color: isDark
                      ? accountColor.withValues(alpha: 0.4)
                      : accountColor.withValues(alpha: 0.5),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getAccountIcon(account.type.toJson()),
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white54 : Colors.black45),
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    account.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white70 : Colors.white60)
                          : (isDark ? Colors.white54 : Colors.black45),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatBalance(account.currentBalance),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAccountsState(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A2A3E), const Color(0xFF0F1B2D)]
              : [const Color(0xFF0D4F6E), const Color(0xFF082F45)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white.withValues(alpha: 0.6),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bem-vindo ao Fyna!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione sua primeira conta para começar\na gerenciar suas finanças.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  AppRoutes.createAccount,
                );
                if (result == true) {
                  _loadData();
                }
              },
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                'Criar primeira conta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0D4F6E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSelector(bool isDark) {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 10 : 0),
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C1C2E)
                  : const Color(0xFFEEEEF2),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 10),
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
              _loadData();
            },
            child: const Icon(Icons.refresh_rounded,
                color: AppColors.error, size: 20),
          ),
        ],
      ),
    );
  }

  String _formatBalance(double value) {
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'CHECKING':
        return Icons.account_balance_rounded;
      case 'SAVINGS':
        return Icons.savings_rounded;
      case 'CREDIT_CARD':
        return Icons.credit_card_rounded;
      case 'CASH':
        return Icons.payments_rounded;
      case 'INVESTMENT':
        return Icons.trending_up_rounded;
      case 'DIGITAL_WALLET':
      case 'DIGITAL_wALLET':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.account_balance_rounded;
    }
  }
}

// ─── Model para itens do menu "Mais" ───
class _MoreMenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}