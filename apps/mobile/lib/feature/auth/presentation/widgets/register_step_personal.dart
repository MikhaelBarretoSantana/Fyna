import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/themes/theme_colors.dart';

class RegisterStepPersonal extends StatefulWidget {
  final TextEditingController phoneController;
  final GlobalKey<FormState> formKey;
  final DateTime? selectedBirthDate;
  final ValueChanged<DateTime?> onBirthDateChanged;

  const RegisterStepPersonal({
    super.key,
    required this.phoneController,
    required this.formKey,
    required this.selectedBirthDate,
    required this.onBirthDateChanged,
  });

  @override
  State<RegisterStepPersonal> createState() => _RegisterStepPersonalState();
}

class _RegisterStepPersonalState extends State<RegisterStepPersonal> {
  final _birthDateDisplayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.selectedBirthDate != null) {
      _birthDateDisplayController.text =
          _formatDate(widget.selectedBirthDate!);
    }
  }

  @override
  void dispose() {
    _birthDateDisplayController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final initialDate = widget.selectedBirthDate ??
        DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: Color(0xFF1A3A4A),
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDateDisplayController.text = _formatDate(picked);
      });
      widget.onBirthDateChanged(picked);
    }
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

          const SizedBox(height: 8),

          // Optional badge
          _buildOptionalBadge(),

          const SizedBox(height: 24),

          // Phone
          _buildGlassTextField(
            controller: widget.phoneController,
            hintText: '(00) 00000-0000',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              _PhoneInputFormatter(),
            ],
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final digits = value.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10 || digits.length > 11) {
                  return 'Informe um telefone válido';
                }
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Birth date — validação espelha o backend: idade >= 18.
          _buildGlassTextField(
            controller: _birthDateDisplayController,
            hintText: 'Data de nascimento',
            prefixIcon: Icons.cake_outlined,
            readOnly: true,
            onTap: _selectBirthDate,
            suffixIcon: Icon(
              Icons.calendar_today_outlined,
              color: ThemeColors.of(context).textTertiary,
              size: 20,
            ),
            validator: (_) {
              final birth = widget.selectedBirthDate;
              if (birth == null) return null; // opcional
              final today = DateTime.now();
              if (birth.isAfter(today)) {
                return 'Data não pode estar no futuro';
              }
              var years = today.year - birth.year;
              if (today.month < birth.month ||
                  (today.month == birth.month && today.day < birth.day)) {
                years--;
              }
              if (years < 18) {
                return 'É necessário ter pelo menos 18 anos';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          // Illustration / hint
          _buildInfoCard(),
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
          'Dados pessoais',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: tc.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Complete seu perfil com informações adicionais.',
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

  Widget _buildOptionalBadge() {
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tc.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tc.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: tc.accentLight,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            'Todos os campos são opcionais',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tc.accentLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final tc = ThemeColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: tc.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: tc.glassBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tc.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: tc.accentLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seus dados estão seguros',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tc.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Suas informações pessoais são criptografadas e nunca serão compartilhadas.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: tc.textMuted,
                        height: 1.4,
                      ),
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

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
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
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          inputFormatters: inputFormatters,
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

/// Formatter para telefone brasileiro: (00) 00000-0000 ou (00) 0000-0000
class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extrai apenas dígitos do novo valor
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limita a 11 dígitos (DDD + celular)
    final digits = digitsOnly.length > 11
        ? digitsOnly.substring(0, 11)
        : digitsOnly;

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final buffer = StringBuffer();
    final isCellPhone = digits.length > 10;

    for (int i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      buffer.write(digits[i]);
      if (i == 1 && digits.length > 2) buffer.write(') ');
      // Celular: (XX) XXXXX-XXXX → traço após o 7º dígito (index 6)
      if (isCellPhone && i == 6 && i < digits.length - 1) buffer.write('-');
      // Fixo: (XX) XXXX-XXXX → traço após o 6º dígito (index 5)
      if (!isCellPhone && i == 5 && digits.length > 6) buffer.write('-');
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
