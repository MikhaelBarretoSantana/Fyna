import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';

/// Tela de login otimizada para usuários que já entraram antes.
/// Mostra avatar, nome, email mascarado e pede apenas a senha
/// (ou autentica via biometria automaticamente, se ativada).
class QuickLoginPage extends StatefulWidget {
  const QuickLoginPage({super.key});

  @override
  State<QuickLoginPage> createState() => _QuickLoginPageState();
}

class _QuickLoginPageState extends State<QuickLoginPage>
    with SingleTickerProviderStateMixin {
  /// Flag de sessão — biometria só dispara automaticamente uma vez por sessão.
  /// Reseta quando o app é morto e reaberto (variável em memória).
  static bool _biometricAttemptedThisSession = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Dados do usuário (vindo das prefs)
  String _userLogin = '';
  String _userFullName = '';
  String _userEmail = '';

  // Biometria
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
    _loadUserAndBiometric();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final bio = Injection.instance.biometricService;
    final available = await bio.isAvailable();
    final enabled = await bio.isBiometricEnabled();

    if (!mounted) return;
    setState(() {
      _userLogin = prefs.getString('user_login') ?? '';
      _userFullName = prefs.getString('user_full_name') ?? '';
      _userEmail = prefs.getString('user_email') ?? '';
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });

    // Dispara biometria automaticamente uma única vez por sessão
    if (enabled && !_biometricAttemptedThisSession) {
      _biometricAttemptedThisSession = true;
      // Aguarda animação inicial antes de disparar para evitar flicker
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _handleBiometricLogin();
    }
  }

  Future<void> _handleBiometricLogin() async {
    final bio = Injection.instance.biometricService;
    final authenticated = await bio.authenticate();
    if (!authenticated || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final refreshToken = await bio.getSecureRefreshToken();
      if (refreshToken == null) {
        await bio.setBiometricEnabled(enabled: false);
        if (mounted) setState(() => _biometricEnabled = false);
        return;
      }
      // O backend rotaciona o refresh token — o antigo é invalidado.
      // Precisamos salvar o novo refresh token na secure storage para
      // que a próxima autenticação biométrica funcione.
      final auth = await Injection.instance.authRepository
          .refresh(refreshToken: refreshToken);
      await bio.setBiometricEnabled(
        enabled: true,
        login: _userLogin,
        refreshToken: auth.refreshToken,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Sessão expirada. Faça login com sua senha.', isError: true);
      await bio.setBiometricEnabled(enabled: false);
      if (mounted) setState(() => _biometricEnabled = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePasswordLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      final auth = await Injection.instance.authRepository.login(
        login: _userLogin,
        password: _passwordController.text,
      );

      // Atualiza credenciais biométricas se estavam ativadas
      if (_biometricEnabled) {
        await Injection.instance.biometricService.setBiometricEnabled(
          enabled: true,
          login: _userLogin,
          refreshToken: auth.refreshToken,
        );
      } else if (_biometricAvailable) {
        await _offerBiometricSetup(refreshToken: auth.refreshToken);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on ServerException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } on NetworkException {
      if (!mounted) return;
      _showSnack('Sem conexão com a internet', isError: true);
    } on TimeoutException {
      if (!mounted) return;
      _showSnack('Servidor demorou para responder.', isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Erro inesperado. Tente novamente.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _offerBiometricSetup({required String refreshToken}) async {
    if (!mounted) return;
    final tc = ThemeColors.of(context);
    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tc.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.fingerprint_rounded, color: tc.accentLight),
            const SizedBox(width: 8),
            Text('Ativar biometria',
                style: TextStyle(
                    color: tc.isDark ? Colors.white : Colors.black87)),
          ],
        ),
        content: Text(
          'Deseja entrar com biometria nas próximas vezes?',
          style: TextStyle(
              color: tc.isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Agora não',
                style: TextStyle(color: tc.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Ativar',
                style: TextStyle(
                    color: tc.accentLight, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (enable == true) {
      await Injection.instance.biometricService.setBiometricEnabled(
        enabled: true,
        login: _userLogin,
        refreshToken: refreshToken,
      );
    }
  }

  Future<void> _switchAccount() async {
    // Limpa dados do usuário atual mas mantém biometria desativada
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('user_full_name'),
      prefs.remove('user_email'),
      prefs.remove('user_login'),
      prefs.remove('user_id'),
    ]);
    await Injection.instance.biometricService.clearAll();
    await Injection.instance.tokenStorage.clearTokens();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade600 : Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return email;
    final parts = email.split('@');
    final user = parts[0];
    final domain = parts[1];
    if (user.length <= 2) return '${user[0]}***@$domain';
    return '${user.substring(0, 2)}***@$domain';
  }

  String _getInitials() {
    if (_userFullName.isEmpty) {
      return _userLogin.isNotEmpty ? _userLogin[0].toUpperCase() : '?';
    }
    final words =
        _userFullName.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          _buildGlassEffects(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      _buildLogo(),
                      const SizedBox(height: 48),
                      _buildUserCard(),
                      const SizedBox(height: 32),
                      _buildPasswordForm(),
                      const SizedBox(height: 24),
                      _buildLoginButton(),
                      const SizedBox(height: 16),
                      if (_biometricEnabled && _biometricAvailable)
                        _buildBiometricButton(),
                      const Spacer(),
                      _buildSwitchAccount(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    final tc = ThemeColors.of(context);
    return Container(decoration: BoxDecoration(gradient: tc.backgroundGradient));
  }

  Widget _buildGlassEffects() {
    final tc = ThemeColors.of(context);
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  tc.decorCircleLight,
                  tc.decorCircleLight.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [tc.decorCircleDark, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        width: 100,
        height: 100,
        child: Image.asset(
          'lib/core/images/fyna-logo-white.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    final tc = ThemeColors.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: tc.glass,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tc.glassBorder, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          tc.accent.withValues(alpha: 0.7),
                          tc.accentLight,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _userFullName.isNotEmpty
                              ? _userFullName
                              : _userLogin,
                          style: TextStyle(
                            color: tc.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _maskEmail(_userEmail),
                          style: TextStyle(
                            color: tc.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    final tc = ThemeColors.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofocus: !_biometricEnabled,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe sua senha';
                  if (v.length < 6) return 'Mínimo de 6 caracteres';
                  return null;
                },
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                cursorColor: tc.accentLight,
                decoration: InputDecoration(
                  hintText: 'Senha',
                  hintStyle: TextStyle(color: tc.textMuted, fontSize: 16),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(Icons.lock_outline_rounded,
                        color: tc.textTertiary, size: 22),
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: tc.textTertiary,
                        size: 22,
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: tc.glass,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  border: _border(tc.glassBorder),
                  enabledBorder: _border(tc.glassBorder),
                  focusedBorder: _border(
                      tc.textPrimary.withValues(alpha: 0.5),
                      width: 1.5),
                  errorBorder: _border(tc.error),
                  focusedErrorBorder: _border(tc.error, width: 1.5),
                  errorStyle: TextStyle(color: tc.accentLight, fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _buildLoginButton() {
    final tc = ThemeColors.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: _isLoading ? null : _handlePasswordLogin,
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              color: tc.primaryButtonBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: tc.primaryButtonShadow,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            tc.primaryButtonText),
                      ),
                    )
                  : Text(
                      'Entrar',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: tc.primaryButtonText,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    final tc = ThemeColors.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _isLoading ? null : _handleBiometricLogin,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tc.glass,
            border: Border.all(color: tc.glassBorder, width: 1.5),
          ),
          child: Icon(Icons.fingerprint_rounded,
              size: 36, color: tc.accentLight),
        ),
      ),
    );
  }

  Widget _buildSwitchAccount() {
    final tc = ThemeColors.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: TextButton(
        onPressed: _switchAccount,
        child: Text(
          'Trocar de conta',
          style: TextStyle(
            color: tc.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
            decorationColor: tc.textSecondary,
          ),
        ),
      ),
    );
  }
}
