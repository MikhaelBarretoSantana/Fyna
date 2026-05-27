import 'package:flutter/material.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_list_item.dart';
import 'package:fyna/core/widgets/app_screen_header.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
import 'package:fyna/main.dart' show themeNotifier;

/// Tela de perfil do usuário.
///
/// Mantém o parâmetro [isDark] por compatibilidade com chamadas existentes,
/// mas o tema real é lido dinamicamente via `Theme.of(context)`.
class ProfilePage extends StatefulWidget {
  final bool isDark;
  const ProfilePage({super.key, required this.isDark});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoggingOut = false;

  // Dados agregados carregados em background (não bloqueia render).
  int? _accountsCount;
  int? _transactionsCount;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final accounts =
          await Injection.instance.accountRepository.getAccounts();
      if (mounted) setState(() => _accountsCount = accounts.length);
    } catch (_) {}
    try {
      final page = await Injection.instance.transactionRepository
          .getTransactions(page: 0, size: 1);
      if (mounted) {
        // O backend devolve totalElements no PageResponse; usamos a chave.
        // Como o cliente expõe só `content`, aproximamos pelo size da página
        // se totalElements não for exposto.
        final dyn = page as dynamic;
        try {
          _transactionsCount = (dyn.totalElements as num?)?.toInt() ??
              (page.content.length);
        } catch (_) {
          _transactionsCount = page.content.length;
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  String get _userFullName =>
      Injection.instance.prefs.getString('user_full_name') ?? 'Usuário';

  String get _userEmail =>
      Injection.instance.prefs.getString('user_email') ?? '';

  String get _initials {
    final parts = _userFullName.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  String get _memberSince {
    final iso = Injection.instance.prefs.getString('user_created_at');
    if (iso == null) return '—';
    final created = DateTime.tryParse(iso);
    if (created == null) return '—';
    final now = DateTime.now();
    final months = (now.year - created.year) * 12 + (now.month - created.month);
    if (months < 1) return 'menos de 1 mês';
    if (months == 1) return '1 mês';
    if (months < 12) return '$months meses';
    final years = months ~/ 12;
    return years == 1 ? '1 ano' : '$years anos';
  }

  String _themeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        children: [
          AppScreenHeader(
            title: '',
            showBack: true,
            actions: [
              _SquareIconButton(
                icon: Icons.edit_outlined,
                onTap: () => _comingSoon('Edição de perfil'),
              ),
            ],
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
          ),
          _buildProfileHeader(tc),
          const SizedBox(height: 18),
          _buildStatsRow(tc),
          const SizedBox(height: 20),
          _sectionLabel(tc, 'CONTA'),
          const SizedBox(height: 10),
          _buildAccountSection(tc),
          const SizedBox(height: 20),
          _sectionLabel(tc, 'PREFERÊNCIAS'),
          const SizedBox(height: 10),
          _buildPreferencesSection(tc),
          const SizedBox(height: 20),
          _sectionLabel(tc, 'SOBRE'),
          const SizedBox(height: 10),
          _buildAboutSection(tc),
          const SizedBox(height: 24),
          _buildLogoutButton(tc),
          const SizedBox(height: 14),
          Text(
            'Fyna v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: tc.neoTextFaint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(ThemeColors tc, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 20, 0),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: tc.neoTextFaint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: tc.heroGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userFullName,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: tc.neoText,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _userEmail,
                  style: TextStyle(
                    fontSize: 13,
                    color: tc.neoTextMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tc.neoAttention.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded,
                          color: tc.neoAttention, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: tc.neoAttention,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(label: 'Membro há', value: _memberSince),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Transações',
              value: _transactionsCount?.toString() ?? '—',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Contas',
              value: _accountsCount?.toString() ?? '—',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          AppListItem(
            leading: const IconBadge(
              icon: Icons.person_outline_rounded,
              tone: 'transfer',
            ),
            title: 'Dados pessoais',
            onTap: () => _comingSoon('Dados pessoais'),
          ),
          const SizedBox(height: 8),
          AppListItem(
            leading: const IconBadge(
              icon: Icons.shield_outlined,
              tone: 'success',
            ),
            title: 'Segurança',
            trailing: Text(
              'Face ID ativo',
              style: TextStyle(
                fontSize: 12.5,
                color: tc.neoPositive,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _comingSoon('Configurações de segurança'),
          ),
          const SizedBox(height: 8),
          AppListItem(
            leading: const IconBadge(
              icon: Icons.notifications_none_rounded,
              tone: 'warning',
            ),
            title: 'Notificações',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          const SizedBox(height: 8),
          AppListItem(
            leading: const IconBadge(
              icon: Icons.account_balance_wallet_rounded,
              tone: 'info',
            ),
            title: 'Contas conectadas',
            trailing: Text(
              _accountsCount != null
                  ? '${_accountsCount!} ${_accountsCount == 1 ? 'conta' : 'contas'}'
                  : '—',
              style: TextStyle(
                fontSize: 12.5,
                color: tc.neoTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () => Navigator.pushNamed(context, AppRoutes.home),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          AppListItem(
            leading: const IconBadge(
              icon: Icons.palette_outlined,
              tone: 'shopping',
            ),
            title: 'Aparência',
            trailing: Text(
              _themeLabel(themeNotifier.themeMode),
              style: TextStyle(
                fontSize: 12.5,
                color: tc.neoTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: _showThemeSheet,
          ),
          const SizedBox(height: 8),
          AppListItem(
            leading: const IconBadge(
              icon: Icons.attach_money_rounded,
              tone: 'transport',
            ),
            title: 'Moeda padrão',
            trailing: Text(
              'BRL',
              style: TextStyle(
                fontSize: 12.5,
                color: tc.neoTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () => _comingSoon('Mudança de moeda'),
          ),
          const SizedBox(height: 8),
          AppListItem(
            leading: const IconBadge(
              icon: Icons.auto_awesome_rounded,
              tone: 'ai',
            ),
            title: 'Assistente IA',
            trailing: Text(
              'Ativo',
              style: TextStyle(
                fontSize: 12.5,
                color: tc.neoPositive,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiInsights),
          ),
          const SizedBox(height: 8),
          AppListItem(
            leading: const IconBadge(
              icon: Icons.category_rounded,
              tone: 'entertainment',
            ),
            title: 'Categorias',
            onTap: () => Navigator.pushNamed(context, AppRoutes.categories),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          AppListItem(
            leading: const IconBadge(
              icon: Icons.help_outline_rounded,
              tone: 'info',
            ),
            title: 'Central de ajuda',
            onTap: () => _comingSoon('Central de ajuda'),
          ),
          const SizedBox(height: 8),
          AppListItem(
            leading: const IconBadge(
              icon: Icons.description_outlined,
              tone: 'neutral',
            ),
            title: 'Termos de uso',
            onTap: () => _comingSoon('Termos de uso'),
          ),
          const SizedBox(height: 8),
          AppListItem(
            leading: const IconBadge(
              icon: Icons.privacy_tip_outlined,
              tone: 'neutral',
            ),
            title: 'Política de privacidade',
            onTap: () => _comingSoon('Política de privacidade'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: _isLoggingOut ? null : _handleLogout,
          icon: _isLoggingOut
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tc.neoNegative,
                  ),
                )
              : Icon(Icons.logout_rounded, color: tc.neoNegative, size: 20),
          label: Text(
            _isLoggingOut ? 'Saindo...' : 'Sair da conta',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: tc.neoNegative,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: tc.neoNegative.withValues(alpha: 0.35)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sheets / Dialogs ───

  void _showThemeSheet() {
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
                  'Aparência',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tc.neoText,
                  ),
                ),
                const SizedBox(height: 12),
                _themeOption(
                  tc,
                  icon: Icons.phone_android_rounded,
                  label: 'Automático',
                  description: 'Segue o sistema',
                  mode: ThemeMode.system,
                ),
                const SizedBox(height: 8),
                _themeOption(
                  tc,
                  icon: Icons.light_mode_rounded,
                  label: 'Tema claro',
                  description: 'Fundo claro o tempo todo',
                  mode: ThemeMode.light,
                ),
                const SizedBox(height: 8),
                _themeOption(
                  tc,
                  icon: Icons.dark_mode_rounded,
                  label: 'Tema escuro',
                  description: 'Fundo escuro o tempo todo',
                  mode: ThemeMode.dark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _themeOption(
    ThemeColors tc, {
    required IconData icon,
    required String label,
    required String description,
    required ThemeMode mode,
  }) {
    final isActive = themeNotifier.themeMode == mode;
    return AppListItem(
      leading: IconBadge(
        icon: icon,
        tone: isActive ? 'transfer' : 'neutral',
      ),
      title: label,
      subtitle: description,
      trailing: isActive ? Icon(Icons.check_rounded, color: tc.neoTeal) : null,
      onTap: () {
        themeNotifier.setThemeMode(mode);
        Navigator.pop(context);
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        return AlertDialog(
          backgroundColor: tc.neoCardElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: IconBadge(
            icon: Icons.logout_rounded,
            tone: 'danger',
            size: 56,
            iconSize: 26,
            radius: 16,
          ),
          title: Text(
            'Sair da conta?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tc.neoText,
            ),
          ),
          content: Text(
            'Você precisará fazer login novamente para acessar suas finanças.',
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
              child: const Text('Sair',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      await Injection.instance.authRepository.logout();
    } catch (_) {
      // Limpa tokens locais de qualquer forma
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  void _comingSoon(String feature) {
    final tc = ThemeColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature em breve'),
        backgroundColor: tc.neoTeal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tc.neoTextFaint,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tc.neoText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Material(
      color: tc.neoCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tc.neoCardBorder),
          ),
          child: Icon(icon, size: 16, color: tc.neoText),
        ),
      ),
    );
  }
}
