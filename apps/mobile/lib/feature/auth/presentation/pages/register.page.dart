import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/feature/auth/data/models/register_request_model.dart';
import 'package:fyna/feature/auth/presentation/widgets/register_step_account.dart';
import 'package:fyna/feature/auth/presentation/widgets/register_step_personal.dart';
import 'package:fyna/feature/auth/presentation/widgets/register_step_preferences.dart';
import 'package:fyna/feature/auth/presentation/widgets/register_step_success.dart';
import 'package:fyna/main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Step management
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 4;
  static const int _lastFormStep = 2; // index do último step de formulário

  // Dados pós-registro
  String _registeredUserName = '';

  // Step 1 - Account controllers
  final _step1FormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _loginController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 2 - Personal controllers
  final _step2FormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  DateTime? _selectedBirthDate;

  // Step 3 - Preferences state
  String _selectedCurrency = 'BRL';
  String _selectedLocale = 'pt-BR';
  String _selectedTheme = 'SYSTEM';
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _budgetAlerts = true;
  bool _weeklySummary = true;
  bool _aiSuggestions = true;

  // Terms & loading
  bool _acceptedTerms = false;
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
    _pageController.dispose();
    _fullNameController.dispose();
    _loginController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!(_step1FormKey.currentState?.validate() ?? false)) return;
    } else if (_currentStep == 1) {
      if (!(_step2FormKey.currentState?.validate() ?? false)) return;
    }

    if (_currentStep < _lastFormStep) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  RegisterRequestModel _buildRegisterModel() {
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return RegisterRequestModel(
      fullName: _fullNameController.text.trim(),
      login: _loginController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: phone.isNotEmpty ? phone : null,
      birthDate: _selectedBirthDate,
      currency: _selectedCurrency,
      locale: _selectedLocale,
      timeZone: 'America/Sao_Paulo',
      theme: _selectedTheme,
      pushNotifications: _pushNotifications,
      emailNotifications: _emailNotifications,
      budgetAlerts: _budgetAlerts,
      weeklySummary: _weeklySummary,
      aiSuggestions: _aiSuggestions,
    );
  }

  void _handleRegister() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aceite os termos para continuar'),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final registerModel = _buildRegisterModel();

    try {
      final authEntity = await Injection.instance.authRepository.register(
        login: registerModel.login,
        email: registerModel.email,
        password: registerModel.password,
        fullName: registerModel.fullName,
        phone: registerModel.phone,
        birthDate: registerModel.birthDate,
      );

      if (!mounted) return;

      debugPrint('Registro bem-sucedido: ${authEntity.user.fullName}');

      // Aplica o tema escolhido no Step 3
      themeNotifier.setFromString(registerModel.theme);

      // Avança para o step de sucesso
      setState(() {
        _registeredUserName = authEntity.user.fullName;
        _currentStep = 3;
      });
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

  String get _stepTitle {
    switch (_currentStep) {
      case 0:
        return 'Crie sua conta';
      case 1:
        return 'Sobre você';
      case 2:
        return 'Personalize';
      case 3:
        return '';
      default:
        return '';
    }
  }

  String get _stepSubtitle {
    switch (_currentStep) {
      case 0:
        return 'Comece a gerenciar suas finanças com\ninteligência artificial agora mesmo.';
      case 1:
        return 'Conte-nos um pouco mais sobre você\npara personalizar sua experiência.';
      case 2:
        return 'Ajuste as configurações do app\ndo seu jeito.';
      case 3:
        return '';
      default:
        return '';
    }
  }

  bool get _isSuccessStep => _currentStep == 3;

  String get _primaryButtonText {
    if (_currentStep < _lastFormStep) return 'Continuar';
    return 'Criar conta';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          _buildGlassEffects(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildHeader(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        if (!_isSuccessStep) ...[
                          _buildLogo(),
                          const SizedBox(height: 24),
                          _buildTitle(),
                          const SizedBox(height: 32),
                          _buildStepIndicator(),
                          const SizedBox(height: 32),
                        ],
                        _buildStepContent(),
                        const SizedBox(height: 24),
                        if (_currentStep == _lastFormStep) ...[
                          _buildTermsCheckbox(),
                          const SizedBox(height: 28),
                        ],
                        if (!_isSuccessStep) ...[
                          _buildButtons(),
                          const SizedBox(height: 32),
                          if (_currentStep == 0) _buildFooter(),
                          const SizedBox(height: 32),
                        ],
                      ],
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
                colors: [
                  tc.decorCircleDark,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          right: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  tc.decorCircleAccent,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
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
    final tc = ThemeColors.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Row(
          children: [
            _buildGlassButton(
              onTap: () {
                if (_currentStep > 0) {
                  _previousStep();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: tc.textPrimary,
                size: 20,
              ),
            ),
            const Spacer(),
            Text(
              _isSuccessStep ? '' : 'Passo ${_currentStep + 1} de ${_totalSteps - 1}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: tc.textTertiary,
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
          width: 80,
          height: 80,
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(_currentStep),
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [tc.textPrimary, tc.accentLight],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  _stepTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: tc.textPrimary,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _stepSubtitle,
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
      ),
    );
  }

  Widget _buildStepIndicator() {
    final tc = ThemeColors.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalSteps - 1, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 32 : 10,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: isActive
                  ? tc.stepActive
                  : isCompleted
                      ? tc.stepCompleted
                      : tc.stepInactive,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: tc.stepGlow,
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return RegisterStepAccount(
          fullNameController: _fullNameController,
          loginController: _loginController,
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          formKey: _step1FormKey,
        );
      case 1:
        return RegisterStepPersonal(
          phoneController: _phoneController,
          formKey: _step2FormKey,
          selectedBirthDate: _selectedBirthDate,
          onBirthDateChanged: (date) {
            setState(() => _selectedBirthDate = date);
          },
        );
      case 2:
        return RegisterStepPreferences(
          selectedCurrency: _selectedCurrency,
          selectedLocale: _selectedLocale,
          selectedTheme: _selectedTheme,
          pushNotifications: _pushNotifications,
          emailNotifications: _emailNotifications,
          budgetAlerts: _budgetAlerts,
          weeklySummary: _weeklySummary,
          aiSuggestions: _aiSuggestions,
          onCurrencyChanged: (val) =>
              setState(() => _selectedCurrency = val),
          onLocaleChanged: (val) =>
              setState(() => _selectedLocale = val),
          onThemeChanged: (val) {
            setState(() => _selectedTheme = val);
            // Aplica o tema dinamicamente no app inteiro
            themeNotifier.setFromString(val);
          },
          onPushNotificationsChanged: (val) =>
              setState(() => _pushNotifications = val),
          onEmailNotificationsChanged: (val) =>
              setState(() => _emailNotifications = val),
          onBudgetAlertsChanged: (val) =>
              setState(() => _budgetAlerts = val),
          onWeeklySummaryChanged: (val) =>
              setState(() => _weeklySummary = val),
          onAiSuggestionsChanged: (val) =>
              setState(() => _aiSuggestions = val),
        );
      case 3:
        return RegisterStepSuccess(
          userName: _registeredUserName,
          countdownSeconds: 5,
          onCountdownFinished: () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTermsCheckbox() {
    final tc = ThemeColors.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _acceptedTerms = !_acceptedTerms;
          });
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color:
                    _acceptedTerms ? tc.accent : Colors.transparent,
                border: Border.all(
                  color: _acceptedTerms
                      ? tc.accent
                      : tc.glassBorder,
                  width: 1.5,
                ),
              ),
              child: _acceptedTerms
                  ? Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: tc.primaryButtonText,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: tc.textTertiary,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Concordo com os '),
                    TextSpan(
                      text: 'Termos de Uso',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: tc.textPrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' e a '),
                    TextSpan(
                      text: 'Política de Privacidade',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: tc.textPrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' do Fyna.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Primary Button - Next / Register
            _buildPrimaryButton(
              text: _primaryButtonText,
              isLoading: _isLoading,
              onTap: () {
                if (_currentStep < _lastFormStep) {
                  _nextStep();
                } else {
                  _handleRegister();
                }
              },
            ),

            const SizedBox(height: 16),

            // Secondary Button
            if (_currentStep == 0)
              _buildSecondaryButton(
                text: 'Já tenho uma conta',
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),

            if (_currentStep == 1)
              _buildSecondaryButton(
                text: 'Pular esta etapa',
                onTap: _nextStep,
              ),
          ],
        ),
      ),
    );
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: tc.primaryButtonText,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (_currentStep < _lastFormStep) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: tc.primaryButtonText,
                        size: 20,
                      ),
                    ],
                  ],
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

  Widget _buildFooter() {
    final tc = ThemeColors.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 1,
                width: 40,
                color: tc.textPrimary.withValues(alpha: 0.2),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'ou cadastre-se com',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: tc.textMuted,
                  ),
                ),
              ),
              Container(
                height: 1,
                width: 40,
                color: tc.textPrimary.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                icon: Icons.g_mobiledata_rounded,
                label: 'Google',
                onTap: () {
                  // TODO: Login com Google
                },
              ),
              const SizedBox(width: 16),
              _buildSocialButton(
                icon: Icons.apple_rounded,
                label: 'Apple',
                onTap: () {
                  // TODO: Login com Apple
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 140,
            height: 54,
            decoration: BoxDecoration(
              color: tc.glass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: tc.glassBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: tc.textPrimary,
                  size: icon == Icons.g_mobiledata_rounded ? 28 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: tc.textPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
