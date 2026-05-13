import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/enums/account_types.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/account/domain/entities/account_entity.dart';

class AccountsPage extends StatefulWidget {
  final bool isDark;
  const AccountsPage({super.key, required this.isDark});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // ─── Dados da API ───
  List<AccountEntity> _accounts = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showInactive = false;

  // ─── Calculados ───
  double get _totalBalance {
    return _filteredAccounts
        .where((a) => a.includeInTotal)
        .fold(0.0, (sum, a) => sum + a.currentBalance);
  }

  List<AccountEntity> get _filteredAccounts {
    if (_showInactive) return _accounts;
    return _accounts.where((a) => a.isActive).toList();
  }

  int get _activeCount => _accounts.where((a) => a.isActive).length;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  // ─── Carregamento ───
  Future<void> _loadAccounts() async {
    if (!_isLoading) setState(() => _isLoading = true);
    setState(() => _errorMessage = null);

    try {
      final accounts =
          await Injection.instance.accountRepository.getAccounts();
      if (mounted) {
        setState(() {
          _accounts = accounts;
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
          _errorMessage = 'Erro ao carregar contas';
          _isLoading = false;
        });
      }
    }
  }

  // ─── Ações ───
  Future<void> _navigateToCreate() async {
    final result =
        await Navigator.pushNamed(context, AppRoutes.createAccount);
    if (result == true && mounted) _loadAccounts();
  }

  Future<void> _deleteAccount(AccountEntity account) async {
    final confirmed = await _showDeleteConfirmation(account);
    if (confirmed != true) return;

    try {
      await Injection.instance.accountRepository.deleteAccount(account.id);
      if (mounted) {
        setState(() {
          // Backend faz soft delete (isActive = false)
          final idx = _accounts.indexWhere((a) => a.id == account.id);
          if (idx != -1) {
            _accounts[idx] = AccountEntity(
              id: account.id,
              name: account.name,
              type: account.type,
              institution: account.institution,
              color: account.color,
              icon: account.icon,
              initialBalance: account.initialBalance,
              currentBalance: account.currentBalance,
              isActive: false,
              includeInTotal: account.includeInTotal,
            );
          }
        });
        _showSnackBar('Conta "${account.name}" desativada', isError: false);
      }
    } on ServerException catch (e) {
      _showSnackBar(e.message);
    } on NetworkException {
      _showSnackBar('Sem conexão com a internet');
    } catch (_) {
      _showSnackBar('Erro ao desativar conta');
    }
  }

  Future<void> _reactivateAccount(AccountEntity account) async {
    try {
      await Injection.instance.accountRepository.updateAccount(
        id: account.id,
        isActive: true,
      );
      if (mounted) {
        setState(() {
          final idx = _accounts.indexWhere((a) => a.id == account.id);
          if (idx != -1) {
            _accounts[idx] = AccountEntity(
              id: account.id,
              name: account.name,
              type: account.type,
              institution: account.institution,
              color: account.color,
              icon: account.icon,
              initialBalance: account.initialBalance,
              currentBalance: account.currentBalance,
              isActive: true,
              includeInTotal: account.includeInTotal,
            );
          }
        });
        _showSnackBar('Conta "${account.name}" reativada', isError: false);
      }
    } catch (_) {
      _showSnackBar('Erro ao reativar conta');
    }
  }

  Future<void> _toggleIncludeInTotal(AccountEntity account) async {
    final newValue = !account.includeInTotal;
    try {
      await Injection.instance.accountRepository.updateAccount(
        id: account.id,
        includeInTotal: newValue,
      );
      if (mounted) {
        setState(() {
          final idx = _accounts.indexWhere((a) => a.id == account.id);
          if (idx != -1) {
            _accounts[idx] = AccountEntity(
              id: account.id,
              name: account.name,
              type: account.type,
              institution: account.institution,
              color: account.color,
              icon: account.icon,
              initialBalance: account.initialBalance,
              currentBalance: account.currentBalance,
              isActive: account.isActive,
              includeInTotal: newValue,
            );
          }
        });
      }
    } catch (_) {
      _showSnackBar('Erro ao atualizar conta');
    }
  }

  Future<bool?> _showDeleteConfirmation(AccountEntity account) {
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
          child: const Icon(
            Icons.archive_outlined,
            color: AppColors.warning,
            size: 28,
          ),
        ),
        title: Text(
          'Desativar conta?',
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
              'A conta "${account.name}" será desativada. '
              'Suas transações serão mantidas, mas ela não aparecerá mais na listagem principal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (account.currentBalance != 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saldo atual: ${_formatCurrency(account.currentBalance)}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
  void _showAccountActions(AccountEntity account) {
    HapticFeedback.mediumImpact();
    final accountColor = _parseColor(account.color);

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
                      color: accountColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getAccountIcon(account.type),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _formatCurrency(account.currentBalance),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: account.currentBalance >= 0
                                ? accountColor
                                : AppColors.error,
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
                icon: account.includeInTotal
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                label: account.includeInTotal
                    ? 'Excluir do patrimônio total'
                    : 'Incluir no patrimônio total',
                color: isDark ? AppColors.darkAccent : AppColors.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleIncludeInTotal(account);
                },
              ),
              const SizedBox(height: 8),
              if (!account.isActive)
                _buildActionTile(
                  icon: Icons.refresh_rounded,
                  label: 'Reativar conta',
                  color: AppColors.success,
                  onTap: () {
                    Navigator.pop(ctx);
                    _reactivateAccount(account);
                  },
                )
              else
                _buildActionTile(
                  icon: Icons.archive_outlined,
                  label: 'Desativar conta',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteAccount(account);
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
    return RefreshIndicator(
      onRefresh: _loadAccounts,
      color: isDark ? AppColors.darkAccent : AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildHeader(),
            const SizedBox(height: 20),
            // Error
            if (_errorMessage != null) _buildErrorBanner(),
            // Balance card
            _isLoading ? _buildBalanceShimmer() : _buildTotalBalanceCard(),
            const SizedBox(height: 24),
            // Toggle
            if (!_isLoading) _buildToggle(),
            const SizedBox(height: 12),
            // Content
            if (_isLoading)
              _buildListShimmer()
            else if (_filteredAccounts.isEmpty)
              _buildEmptyState()
            else
              _buildAccountsByType(),
          ],
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              if (!_isLoading)
                Text(
                  '$_activeCount conta${_activeCount != 1 ? 's' : ''} ativa${_activeCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _navigateToCreate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkAccent : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Nova conta',
                    style: TextStyle(
                      fontSize: 13,
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
    );
  }

  // ─── Patrimônio total ───
  Widget _buildTotalBalanceCard() {
    final activeAccounts = _accounts.where((a) => a.isActive).toList();
    final includedCount =
        activeAccounts.where((a) => a.includeInTotal).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
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
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Patrimônio total',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              if (includedCount < activeAccounts.length)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$includedCount de ${activeAccounts.length} contas',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(_totalBalance),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Mini stats
          Row(
            children: [
              _buildMiniStat(
                '$_activeCount',
                'Contas ativas',
                Icons.account_balance_rounded,
              ),
              const SizedBox(width: 24),
              if (_activeCount > 0)
                _buildMiniStat(
                  _formatCurrencyShort(_totalBalance / _activeCount),
                  'Média por conta',
                  Icons.analytics_rounded,
                ),
            ],
          ),
          // Distribuição por tipo (mini bar horizontal)
          if (activeAccounts.length > 1) ...[
            const SizedBox(height: 16),
            _buildTypeDistributionBar(activeAccounts),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeDistributionBar(List<AccountEntity> accounts) {
    final total =
        accounts.fold<double>(0, (s, a) => s + a.currentBalance.abs());
    if (total <= 0) return const SizedBox.shrink();

    // Agrupar por tipo
    final typeMap = <AccountTypes, double>{};
    for (final a in accounts) {
      typeMap.update(a.type, (v) => v + a.currentBalance.abs(),
          ifAbsent: () => a.currentBalance.abs());
    }

    final entries = typeMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Row(
              children: entries.map((e) {
                final fraction = e.value / total;
                return Expanded(
                  flex: (fraction * 100).round().clamp(1, 100),
                  child: Container(
                    color: _typeColor(e.key),
                    margin: const EdgeInsets.only(right: 1),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: entries.map((e) {
            final percent = ((e.value / total) * 100).round();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _typeColor(e.key),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${e.key.label} $percent%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _typeColor(AccountTypes type) {
    switch (type) {
      case AccountTypes.checking:
        return const Color(0xFF3CADE8);
      case AccountTypes.savings:
        return const Color(0xFF00D4AA);
      case AccountTypes.creditCard:
        return const Color(0xFFFF6B6B);
      case AccountTypes.cash:
        return const Color(0xFFFFB300);
      case AccountTypes.investment:
        return const Color(0xFF7C83FD);
      case AccountTypes.digitalWallet:
        return const Color(0xFFE91E63);
      case AccountTypes.other:
        return Colors.white38;
    }
  }

  Widget _buildBalanceShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 170,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A3E) : const Color(0xFFD0E8EF),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  // ─── Toggle ativa/todas ───
  Widget _buildToggle() {
    final inactiveCount = _accounts.where((a) => !a.isActive).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            _showInactive ? 'Todas as contas' : 'Contas ativas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const Spacer(),
          if (inactiveCount > 0)
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showInactive
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_outlined,
                      size: 14,
                      color: isDark ? AppColors.darkAccent : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showInactive
                          ? 'Ocultar inativas'
                          : 'Ver inativas ($inactiveCount)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? AppColors.darkAccent : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Lista agrupada por tipo ───
  Widget _buildAccountsByType() {
    final types = AccountTypes.values;
    final sections = <Widget>[];

    for (final type in types) {
      final accs = _filteredAccounts.where((a) => a.type == type).toList();
      if (accs.isEmpty) continue;

      final sectionBalance = accs.fold<double>(0, (s, a) => s + a.currentBalance);

      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _typeColor(type).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAccountIcon(type),
                  size: 14,
                  color: _typeColor(type),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                type.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const Spacer(),
              Text(
                _formatCurrency(sectionBalance),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
            ],
          ),
        ),
      );

      for (final account in accs) {
        sections.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildAccountCard(account),
          ),
        );
      }
    }

    return Column(children: sections);
  }

  Widget _buildAccountCard(AccountEntity account) {
    final accountColor = _parseColor(account.color);
    final isInactive = !account.isActive;

    return Dismissible(
      key: ValueKey(account.id),
      direction: account.isActive
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.archive_outlined,
            color: AppColors.warning, size: 24),
      ),
      confirmDismiss: (_) => _showDeleteConfirmation(account),
      onDismissed: (_) {
        Injection.instance.accountRepository.deleteAccount(account.id);
        setState(() {
          final idx = _accounts.indexWhere((a) => a.id == account.id);
          if (idx != -1) {
            _accounts[idx] = AccountEntity(
              id: account.id,
              name: account.name,
              type: account.type,
              institution: account.institution,
              color: account.color,
              icon: account.icon,
              initialBalance: account.initialBalance,
              currentBalance: account.currentBalance,
              isActive: false,
              includeInTotal: account.includeInTotal,
            );
          }
        });
        _showSnackBar('Conta "${account.name}" desativada', isError: false);
      },
      child: GestureDetector(
        onLongPress: () => _showAccountActions(account),
        child: Opacity(
          opacity: isInactive ? 0.5 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14142A) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isInactive
                    ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06))
                    : (isDark
                        ? accountColor.withValues(alpha: 0.15)
                        : accountColor.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                // Ícone colorido
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accountColor,
                        accountColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getAccountIcon(account.type),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Nome + instituição
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              account.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!account.includeInTotal) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.visibility_off_outlined,
                                size: 14,
                                color:
                                    isDark ? Colors.white70 : Colors.black26),
                          ],
                        ],
                      ),
                      if (account.institution != null &&
                          account.institution!.isNotEmpty)
                        Text(
                          account.institution!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white30 : Colors.black38,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Saldo + badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(account.currentBalance),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: account.currentBalance >= 0
                            ? (isDark ? Colors.white : AppColors.textPrimary)
                            : AppColors.error,
                      ),
                    ),
                    if (isInactive)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Inativa',
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
        ),
      ),
    );
  }

  // ─── Error ───
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
            onTap: _loadAccounts,
            child: const Icon(Icons.refresh_rounded,
                color: AppColors.error, size: 18),
          ),
        ],
      ),
    );
  }

  // ─── Empty ───
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14142A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEF2),
        ),
      ),
      child: Column(
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
              Icons.account_balance_wallet_rounded,
              size: 32,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _showInactive
                ? 'Nenhuma conta encontrada'
                : 'Nenhuma conta ativa',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _showInactive
                ? 'Crie sua primeira conta para começar.'
                : 'Suas contas ativas aparecerão aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black26,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _navigateToCreate,
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
                  Icon(Icons.add_rounded,
                      size: 18,
                      color:
                          isDark ? AppColors.darkAccent : AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Criar conta',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.darkAccent : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shimmer ───
  Widget _buildListShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(4, (i) {
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
      ),
    );
  }

  // ─── Utils ───
  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return AppColors.primary;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return AppColors.primary;
    return Color(0xFF000000 | value);
  }

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }

  String _formatCurrencyShort(double value) {
    if (value.abs() >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(1)}k';
    }
    return _formatCurrency(value);
  }

  IconData _getAccountIcon(AccountTypes type) {
    switch (type) {
      case AccountTypes.checking:
        return Icons.account_balance_rounded;
      case AccountTypes.savings:
        return Icons.savings_rounded;
      case AccountTypes.creditCard:
        return Icons.credit_card_rounded;
      case AccountTypes.cash:
        return Icons.payments_rounded;
      case AccountTypes.investment:
        return Icons.trending_up_rounded;
      case AccountTypes.digitalWallet:
        return Icons.account_balance_wallet_rounded;
      case AccountTypes.other:
        return Icons.more_horiz_rounded;
    }
  }
}