import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          _buildBackground(),

          // Glassmorphism overlay effects
          _buildGlassEffects(),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Back button
                      _buildHeader(),

                      const Spacer(flex: 1),

                      // Logo
                      _buildLogo(),

                      const SizedBox(height: 32),

                      // Title
                      _buildTitle(),

                      const SizedBox(height: 40),

                      // Form
                      _buildForm(),

                      const SizedBox(height: 16),

                      // Forgot password
                      _buildForgotPassword(),

                      const SizedBox(height: 32),

                      // Buttons
                      _buildButtons(),

                      const Spacer(flex: 2),

                      // Footer
                      _buildFooter(),

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
    return Container(
      decoration: BoxDecoration(
        gradient: tc.backgroundGradient,
      ),
    );
  }

  Widget _buildGlassEffects() {
    final tc = ThemeColors.of(context);
    return Stack(
      children: [
        // Top right blur circle
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

        // Bottom left blur circle
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  tc.decorCircleDark,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Glass effect overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final canPop = Navigator.canPop(context);
    final tc = ThemeColors.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Row(
          children: [
            if (canPop)
              _buildGlassButton(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: tc.textPrimary,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tc.glass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tc.glassBorder,
                width: 1,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Image.asset(
            'lib/core/images/fyna-logo-white.png',
            fit: BoxFit.contain,
            semanticLabel: 'Fyna Logo',
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final tc = ThemeColors.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [tc.textPrimary, tc.accentLight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                'Bem-vindo\nde volta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: tc.textPrimary,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Acesse sua conta para continuar gerenciando\nsuas finanças com inteligência.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: tc.textSecondary,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Login field
              _buildGlassTextField(
                controller: _loginController,
                hintText: 'Login',
                prefixIcon: Icons.person_outline_rounded,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe seu login';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Password field
              _buildGlassTextField(
                controller: _passwordController,
                hintText: 'Senha',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: ThemeColors.of(context).textTertiary,
                    size: 22,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe sua senha';
                  }
                  if (value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final tc = ThemeColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: TextStyle(
            color: tc.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          cursorColor: tc.accentLight,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: tc.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(
                prefixIcon,
                color: tc.textTertiary,
                size: 22,
              ),
            ),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: suffixIcon,
                  )
                : null,
            filled: true,
            fillColor: tc.glass,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: tc.glassBorder,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: tc.glassBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: tc.textPrimary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: tc.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: tc.error,
                width: 1.5,
              ),
            ),
            errorStyle: TextStyle(
              color: tc.accentLight,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return const SizedBox.shrink();
  }

  Future<void> _offerBiometricSetup({
    required String login,
    required String refreshToken,
  }) async {
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
            Text('Ativar biometria', style: TextStyle(color: tc.textPrimary)),
          ],
        ),
        content: Text(
          'Deseja usar impressão digital ou Face ID nas próximas vezes que acessar o Fyna?',
          style: TextStyle(color: tc.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Agora não', style: TextStyle(color: tc.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Ativar', style: TextStyle(color: tc.accentLight, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (enable == true) {
      await Injection.instance.biometricService.setBiometricEnabled(
        enabled: true,
        login: login,
        refreshToken: refreshToken,
      );
    }
  }


  Widget _buildButtons() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Primary Button - Login
            _buildPrimaryButton(
              text: 'Entrar',
              isLoading: _isLoading,
              onTap: _handleLogin,
            ),

            const SizedBox(height: 16),

            // Secondary Button - Register
            _buildSecondaryButton(
              text: 'Criar uma conta',
              onTap: () {
                Navigator.pushReplacementNamed(context, '/register');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final authEntity = await Injection.instance.authRepository.login(
        login: _loginController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      debugPrint('Login bem-sucedido: ${authEntity.user.fullName}');

      // Oferece ativar biometria após primeiro login (será usada na próxima
      // vez que abrir o app, via QuickLoginPage)
      final bio = Injection.instance.biometricService;
      final available = await bio.isAvailable();
      final alreadyEnabled = await bio.isBiometricEnabled();
      if (available && !alreadyEnabled) {
        await _offerBiometricSetup(
          login: _loginController.text.trim(),
          refreshToken: authEntity.refreshToken,
        );
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on ServerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } on NetworkException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sem conexão com a internet'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Servidor demorou para responder. Tente novamente.'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Erro no login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro inesperado. Tente novamente.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: isLoading ? null : onTap,
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
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      tc.primaryButtonText,
                    ),
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: tc.primaryButtonText,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback onTap,
  }) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tc.glassBorder, width: 1.5),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: tc.textPrimary.withValues(alpha: 0.95),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // Login social (Google/Apple) oculto até estar implementado
  Widget _buildFooter() => const SizedBox.shrink();
}
