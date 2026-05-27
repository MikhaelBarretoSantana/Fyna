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
import 'package:fyna/feature/account/domain/entities/account_entity.dart';

class AccountsPage extends StatefulWidget {
  final bool isDark;
  const AccountsPage({super.key, required this.isDark});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  List<AccountEntity> _accounts = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showInactive = false;
  DateTime? _lastUpdated;

  List<AccountEntity> get _filteredAccounts {
    if (_showInactive) return _accounts;
    return _accounts.where((a) => a.isActive).toList();
  }

  double get _totalBalance => _filteredAccounts
      .where((a) => a.includeInTotal && a.isActive)
      .fold(0.0, (sum, a) => sum + a.currentBalance);

  int get _activeCount => _accounts.where((a) => a.isActive).length;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

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
          _lastUpdated = DateTime.now();
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

  Future<void> _deleteAccount(AccountEntity account) async {
    final confirmed = await _showDeleteConfirmation(account);
    if (confirmed != true) return;
    try {
      await Injection.instance.accountRepository.deleteAccount(account.id);
      if (!mounted) return;
      setState(() {
        final idx = _accounts.indexWhere((a) => a.id == account.id);
        if (idx != -1) _accounts[idx] = _copyWith(account, isActive: false);
      });
      _snack('Conta "${account.name}" desativada', isError: false);
    } on ServerException catch (e) {
      _snack(e.message);
    } on NetworkException {
      _snack('Sem conexão com a internet');
    } catch (_) {
      _snack('Erro ao desativar conta');
    }
  }

  Future<void> _reactivateAccount(AccountEntity account) async {
    try {
      await Injection.instance.accountRepository
          .updateAccount(id: account.id, isActive: true);
      if (!mounted) return;
      setState(() {
        final idx = _accounts.indexWhere((a) => a.id == account.id);
        if (idx != -1) _accounts[idx] = _copyWith(account, isActive: true);
      });
      _snack('Conta "${account.name}" reativada', isError: false);
    } catch (_) {
      _snack('Erro ao reativar conta');
    }
  }

  Future<void> _toggleIncludeInTotal(AccountEntity account) async {
    final newValue = !account.includeInTotal;
    try {
      await Injection.instance.accountRepository
          .updateAccount(id: account.id, includeInTotal: newValue);
      if (!mounted) return;
      setState(() {
        final idx = _accounts.indexWhere((a) => a.id == account.id);
        if (idx != -1) {
          _accounts[idx] = _copyWith(account, includeInTotal: newValue);
        }
      });
    } catch (_) {
      _snack('Erro ao atualizar conta');
    }
  }

  AccountEntity _copyWith(
    AccountEntity a, {
    bool? isActive,
    bool? includeInTotal,
  }) {
    return AccountEntity(
      id: a.id,
      name: a.name,
      type: a.type,
      institution: a.institution,
      color: a.color,
      icon: a.icon,
      initialBalance: a.initialBalance,
      currentBalance: a.currentBalance,
      isActive: isActive ?? a.isActive,
      includeInTotal: includeInTotal ?? a.includeInTotal,
    );
  }

  Future<bool?> _showDeleteConfirmation(AccountEntity account) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        return AlertDialog(
          backgroundColor: tc.neoCardElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: IconBadge(
            icon: Icons.archive_outlined,
            tone: 'warning',
            size: 56,
            iconSize: 26,
            radius: 16,
          ),
          title: Text(
            'Desativar conta?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tc.neoText,
            ),
          ),
          content: Text(
            'A conta "${account.name}" será desativada. Suas transações serão '
            'mantidas, mas ela não aparecerá mais na listagem principal.',
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
                  borderRadius: BorderRadius.circular(12),
                ),
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

  void _showActions(AccountEntity account) {
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
                    icon: account.includeInTotal
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    tone: 'info',
                  ),
                  title: account.includeInTotal
                      ? 'Excluir do patrimônio total'
                      : 'Incluir no patrimônio total',
                  onTap: () {
                    Navigator.pop(ctx);
                    _toggleIncludeInTotal(account);
                  },
                ),
                const SizedBox(height: 8),
                if (account.isActive)
                  AppListItem(
                    leading: const IconBadge(
                      icon: Icons.archive_outlined,
                      tone: 'warning',
                    ),
                    title: 'Desativar conta',
                    onTap: () {
                      Navigator.pop(ctx);
                      _deleteAccount(account);
                    },
                  )
                else
                  AppListItem(
                    leading: const IconBadge(
                      icon: Icons.unarchive_outlined,
                      tone: 'success',
                    ),
                    title: 'Reativar conta',
                    onTap: () {
                      Navigator.pop(ctx);
                      _reactivateAccount(account);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) return '';
    final diff = DateTime.now().difference(_lastUpdated!);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    return '${diff.inHours}h';
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
              title: 'Minhas contas',
              subtitle: _isLoading
                  ? 'Carregando...'
                  : '$_activeCount ${_activeCount == 1 ? 'conta' : 'contas'}${_lastUpdated != null ? ' · atualizadas há $_lastUpdatedText' : ''}',
              actions: [
                HeaderActionButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Nova conta',
                  onTap: () async {
                    final result = await Navigator.pushNamed(
                        context, AppRoutes.createAccount);
                    if (result == true && mounted) _loadAccounts();
                  },
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAccounts,
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
                              _buildHeroCard(tc),
                              const SizedBox(height: 14),
                              if (_filteredAccounts.isEmpty)
                                _buildEmpty(tc)
                              else ...[
                                for (final a in _filteredAccounts) ...[
                                  _AccountTile(
                                    account: a,
                                    onTap: () => _showActions(a),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                _AddAccountTile(
                                  onTap: () async {
                                    final result = await Navigator.pushNamed(
                                        context, AppRoutes.createAccount);
                                    if (result == true && mounted) {
                                      _loadAccounts();
                                    }
                                  },
                                ),
                              ],
                              if (_accounts.any((a) => !a.isActive))
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
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

  Widget _buildHeroCard(ThemeColors tc) {
    return HeroGradientCard(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PATRIMÔNIO TOTAL',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _fmt(_totalBalance),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.2,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          IconBadge(
            icon: Icons.account_balance_wallet_rounded,
            tone: 'neutral',
            size: 64,
            iconSize: 28,
            radius: 18,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma conta cadastrada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: tc.neoTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Adicione sua primeira conta para começar.',
            style: TextStyle(fontSize: 13, color: tc.neoTextFaint),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                  context, AppRoutes.createAccount);
              if (result == true && mounted) _loadAccounts();
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Criar primeira conta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: tc.neoTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              minimumSize: const Size(240, 48),
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
              onPressed: _loadAccounts,
              style: TextButton.styleFrom(foregroundColor: tc.neoTeal),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final AccountEntity account;
  final VoidCallback onTap;

  const _AccountTile({required this.account, required this.onTap});

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return fallback;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return fallback;
    return Color(0xFF000000 | value);
  }

  IconData _iconFor() {
    switch (account.type.toJson()) {
      case 'CHECKING':
        return Icons.account_balance_wallet_rounded;
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

  String _shortLabel() {
    final label = account.type.label;
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final color = _parseColor(account.color, tc.neoTeal);
    final balanceColor = account.currentBalance >= 0 ? tc.neoText : tc.neoNegative;

    return Opacity(
      opacity: account.isActive ? 1.0 : 0.55,
      child: AppListItem(
        leading: IconBadge(
          icon: _iconFor(),
          background: color.withValues(alpha: tc.isDark ? 0.22 : 0.18),
          foreground: color,
          size: 44,
          iconSize: 20,
          radius: 13,
        ),
        title: account.name,
        subtitle: _shortLabel(),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _fmt(account.currentBalance),
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: balanceColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              account.isActive ? 'Sincronizado' : 'Inativa',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: account.isActive ? tc.neoPositive : tc.neoTextFaint,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _AddAccountTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddAccountTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tc.neoTextFaint.withValues(alpha: 0.45),
            style: BorderStyle.solid,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: tc.neoTextMuted, size: 18),
            const SizedBox(width: 6),
            Text(
              'Adicionar nova conta',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tc.neoTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(double v) {
  final f = v.abs().toStringAsFixed(2).replaceAll('.', ',');
  final p = f.split(',');
  final i = p[0]
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  final sign = v < 0 ? '-' : '';
  return '${sign}R\$ $i,${p[1]}';
}
