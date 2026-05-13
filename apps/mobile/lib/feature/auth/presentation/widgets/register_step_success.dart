import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fyna/core/themes/theme_colors.dart';

/// Step final de cadastro — tela de sucesso com contagem regressiva.
class RegisterStepSuccess extends StatefulWidget {
  final String userName;
  final int countdownSeconds;
  final VoidCallback onCountdownFinished;

  const RegisterStepSuccess({
    super.key,
    required this.userName,
    this.countdownSeconds = 5,
    required this.onCountdownFinished,
  });

  @override
  State<RegisterStepSuccess> createState() => _RegisterStepSuccessState();
}

class _RegisterStepSuccessState extends State<RegisterStepSuccess>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  late AnimationController _checkController;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _remaining = widget.countdownSeconds;

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: Curves.elasticOut,
      ),
    );

    // Inicia a animação do check
    _checkController.forward();

    // Inicia a contagem regressiva
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        timer.cancel();
        widget.onCountdownFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),

        // Ícone de sucesso animado
        ScaleTransition(
          scale: _checkScale,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 56,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Título
        Text(
          'Cadastro concluído!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: tc.textPrimary,
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 12),

        // Mensagem de boas-vindas
        Text(
          'Bem-vindo(a), ${widget.userName}!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: tc.textSecondary,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Sua conta foi criada com sucesso.\nVocê será redirecionado em instantes.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: tc.textTertiary,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 40),

        // Contador regressivo
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tc.glass,
            border: Border.all(
              color: tc.glassBorder,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '$_remaining',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: tc.textPrimary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Redirecionando para o login...',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: tc.textMuted,
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
