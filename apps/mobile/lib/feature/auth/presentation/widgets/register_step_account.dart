import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/themes/theme_colors.dart';

class RegisterStepAccount extends StatefulWidget {
  final TextEditingController fullNameController;
  final TextEditingController loginController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;

  const RegisterStepAccount({
    super.key,
    required this.fullNameController,
    required this.loginController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.formKey,
  });

  @override
  State<RegisterStepAccount> createState() => _RegisterStepAccountState();
}

class _RegisterStepAccountState extends State<RegisterStepAccount> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    widget.passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final password = widget.passwordController.text;
    double strength = 0;

    if (password.length >= 6) strength += 0.2;
    if (password.length >= 10) strength += 0.1;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.1;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,\.<>\?/\\|`~]')
        .hasMatch(password)) {
      strength += 0.2;
    }

    String label;
    Color color;

    if (password.isEmpty) {
      label = '';
      color = Colors.transparent;
    } else if (strength <= 0.3) {
      label = 'Fraca';
      color = AppColors.error;
    } else if (strength <= 0.6) {
      label = 'Média';
      color = AppColors.warning;
    } else if (strength <= 0.8) {
      label = 'Forte';
      color = AppColors.accent;
    } else {
      label = 'Muito forte';
      color = AppColors.success;
    }

    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);
      _passwordStrengthLabel = label;
      _passwordStrengthColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title
          _buildStepTitle(),

          const SizedBox(height: 24),

          // Full Name
          _buildGlassTextField(
            controller: widget.fullNameController,
            hintText: 'Nome completo',
            prefixIcon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe seu nome';
              }
              if (value.trim().split(' ').length < 2) {
                return 'Informe nome e sobrenome';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Login (username)
          _buildGlassTextField(
            controller: widget.loginController,
            hintText: 'Nome de usuário',
            prefixIcon: Icons.alternate_email_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe um nome de usuário';
              }
              if (value.trim().length < 3) {
                return 'Mínimo de 3 caracteres';
              }
              if (value.trim().length > 50) {
                return 'Máximo de 50 caracteres';
              }
              if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value.trim())) {
                return 'Apenas letras, números, ".", "_" e "-"';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Email
          _buildGlassTextField(
            controller: widget.emailController,
            hintText: 'E-mail',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe seu e-mail';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Informe um e-mail válido';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Password
          _buildGlassTextField(
            controller: widget.passwordController,
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

          // Password strength indicator
          if (widget.passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildPasswordStrengthIndicator(),
          ],

          const SizedBox(height: 16),

          // Confirm Password
          _buildGlassTextField(
            controller: widget.confirmPasswordController,
            hintText: 'Confirmar senha',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirmPassword,
            suffixIcon: GestureDetector(
              onTap: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              child: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: ThemeColors.of(context).textTertiary,
                size: 22,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirme sua senha';
              }
              if (value != widget.passwordController.text) {
                return 'As senhas não coincidem';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle() {
    final tc = ThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dados da conta',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: tc.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Informações básicas para criar sua conta.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: tc.textTertiary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final tc = ThemeColors.of(context);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: _passwordStrength,
              backgroundColor: tc.stepInactive,
              valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _passwordStrengthLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _passwordStrengthColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
          textCapitalization: textCapitalization,
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
}
