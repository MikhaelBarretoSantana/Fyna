import 'package:flutter/material.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/themes/theme_notifier.dart';
import 'package:fyna/main.dart' show themeNotifier;

/// Tela de perfil do usuário.
class ProfilePage extends StatefulWidget {
  final bool isDark;

  const ProfilePage({super.key, required this.isDark});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoggingOut = false;
  bool _showBalances = true;

  /// Lê o tema dinamicamente do contexto — reage em tempo real às mudanças
  /// de tema sem precisar navegar pra fora da tela.
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // Lê as iniciais do nome armazenado no SharedPreferences
  String get _userFullName {
    final prefs = Injection.instance.prefs;
    return prefs.getString('user_full_name') ?? 'Usuário';
  }

  String get _userEmail {
    final prefs = Injection.instance.prefs;
    return prefs.getString('user_email') ?? '';
  }

  String get _userLogin {
    final prefs = Injection.instance.prefs;
    return prefs.getString('user_login') ?? '';
  }

  String get _initials {
    final parts = _userFullName.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Header com avatar e informações
          _buildProfileHeader(),

          const SizedBox(height: 24),

          // Seção: Finanças
          _buildSectionTitle('Finanças'),
          _buildFinancesSection(),

          const SizedBox(height: 20),

          // Seção: Preferências
          _buildSectionTitle('Preferências'),
          _buildPreferencesSection(),

          const SizedBox(height: 20),

          // Seção: Configurações
          _buildSectionTitle('Configurações'),
          _buildSettingsSection(),

          const SizedBox(height: 20),

          // Seção: Sobre
          _buildSectionTitle('Sobre'),
          _buildAboutSection(),

          const SizedBox(height: 32),

          // Botão de logout
          _buildLogoutButton(),

          const SizedBox(height: 16),

          // Versão
          Text(
            'Fyna v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header com avatar ──────────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.accent.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF252540)
              : AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppColors.darkAccent, AppColors.darkPrimary]
                    : [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.darkAccent : AppColors.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userFullName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (_userEmail.isNotEmpty)
                  Text(
                    _userEmail,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (_userLogin.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '@$_userLogin',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Seções ─────────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white38 : Colors.black45,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildFinancesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14142A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEF2),
        ),
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.pie_chart_rounded,
            title: 'Orçamentos',
            subtitle: 'Gerenciar limites de gastos',
            onTap: () => Navigator.pushNamed(context, AppRoutes.budgets),
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.flag_rounded,
            title: 'Metas financeiras',
            subtitle: 'Acompanhar seus objetivos',
            onTap: () => Navigator.pushNamed(context, AppRoutes.goals),
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.repeat_rounded,
            title: 'Recorrências',
            subtitle: 'Despesas e receitas fixas',
            onTap: () => Navigator.pushNamed(context, AppRoutes.recurring),
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.category_rounded,
            title: 'Categorias',
            subtitle: 'Organizar suas transações',
            onTap: () => Navigator.pushNamed(context, AppRoutes.categories),
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.auto_awesome_rounded,
            title: 'Insights da IA',
            subtitle: 'Análises e recomendações',
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiInsights),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14142A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEF2),
        ),
      ),
      child: Column(
        children: [
          _buildThemeSelector(),
          _buildDivider(),
          _buildToggleTile(
            icon: Icons.visibility_rounded,
            title: 'Exibir saldos',
            subtitle: 'Mostrar valores na tela inicial',
            value: _showBalances,
            onChanged: (val) => setState(() => _showBalances = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14142A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEF2),
        ),
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.notifications_rounded,
            title: 'Notificações',
            subtitle: 'Gerenciar alertas e lembretes',
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.lock_rounded,
            title: 'Segurança',
            subtitle: 'Senha e autenticação',
            onTap: () => _showComingSoon('Segurança'),
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.download_rounded,
            title: 'Exportar dados',
            subtitle: 'Baixar seus dados em CSV',
            onTap: () => _showComingSoon('Exportação'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14142A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEF2),
        ),
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.info_outline_rounded,
            title: 'Sobre o Fyna',
            subtitle: 'Versão, licenças e créditos',
            onTap: () => _showAboutDialog(),
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.help_outline_rounded,
            title: 'Ajuda e suporte',
            subtitle: 'FAQ e contato',
            onTap: () => _showComingSoon('Ajuda'),
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.description_outlined,
            title: 'Termos de uso',
            subtitle: 'Política de privacidade',
            onTap: () => _showComingSoon('Termos'),
          ),
        ],
      ),
    );
  }

  // ─── Componentes reutilizáveis ─────────────────────────────────────────────

  Widget _buildThemeSelector() {
    final currentMode = themeNotifier.themeMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkAccent.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.palette_rounded,
              color: isDark ? AppColors.darkAccent : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tema',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getThemeLabel(currentMode),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          // Chips de seleção de tema
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeChip(
                icon: Icons.phone_android_rounded,
                label: 'Auto',
                isSelected: currentMode == ThemeMode.system,
                onTap: () => _setTheme(ThemeMode.system),
              ),
              const SizedBox(width: 6),
              _buildThemeChip(
                icon: Icons.light_mode_rounded,
                label: 'Claro',
                isSelected: currentMode == ThemeMode.light,
                onTap: () => _setTheme(ThemeMode.light),
              ),
              const SizedBox(width: 6),
              _buildThemeChip(
                icon: Icons.dark_mode_rounded,
                label: 'Escuro',
                isSelected: currentMode == ThemeMode.dark,
                onTap: () => _setTheme(ThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkAccent : AppColors.primary)
              : (isDark ? const Color(0xFF1C1C2E) : const Color(0xFFF0F0F4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white30 : Colors.black38),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white30 : Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkAccent.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.darkAccent : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: isDark ? AppColors.darkAccent : AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white54 : Colors.black54,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white30 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: isDark ? const Color(0xFF252540) : const Color(0xFFF0F0F4),
      ),
    );
  }

  // ─── Logout ────────────────────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: _isLoggingOut ? null : _handleLogout,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: isDark ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoggingOut)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error.withValues(alpha: 0.7),
                  ),
                )
              else
                Icon(
                  Icons.logout_rounded,
                  color: AppColors.error.withValues(alpha: 0.8),
                  size: 20,
                ),
              const SizedBox(width: 10),
              Text(
                _isLoggingOut ? 'Saindo...' : 'Sair da conta',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Ações ─────────────────────────────────────────────────────────────────

  void _setTheme(ThemeMode mode) {
    themeNotifier.setThemeMode(mode);
    final prefs = Injection.instance.prefs;
    prefs.setString('theme_mode', ThemeNotifier.toBackendString(mode));
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Tema claro';
      case ThemeMode.dark:
        return 'Tema escuro';
      default:
        return 'Automático (sistema)';
    }
  }

  Future<void> _handleLogout() async {
    // Confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sair da conta',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Tem certeza que deseja sair? Você precisará fazer login novamente.',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sair',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);

    try {
      await Injection.instance.authRepository.logout();
    } catch (_) {
      // Ignora erros — limpa tokens locais de qualquer forma
    }

    if (!mounted) return;

    // Navega para login e limpa a pilha
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature estará disponível em breve!'),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.darkAccent, AppColors.darkPrimary]
                      : [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'F',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Fyna',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seu assistente financeiro pessoal com inteligência artificial.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            _buildAboutRow('Versão', '1.0.0'),
            _buildAboutRow('Plataforma', 'Flutter'),
            _buildAboutRow('Licença', 'Proprietária'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Fechar',
              style: TextStyle(
                color: isDark ? AppColors.darkAccent : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
