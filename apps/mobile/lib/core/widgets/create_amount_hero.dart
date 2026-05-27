import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/core/themes/theme_colors.dart';

/// Card "hero" usado no topo das telas de criação (Nova despesa, Novo
/// orçamento, etc.) — mostra um label curto em uppercase + valor monetário
/// grande em fundo gradiente.
///
/// Pode operar em modo somente-leitura ([editable] false) ou como input
/// (TextField controlado).
class CreateAmountHero extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final LinearGradient? gradient;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final EdgeInsetsGeometry padding;

  const CreateAmountHero({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    this.gradient,
    this.onChanged,
    this.autofocus = false,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient ?? tc.heroGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: tc.isDark ? 0.35 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'R\$ ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: autofocus,
                      onChanged: onChanged,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [_BrlMoneyInputFormatter()],
                      cursorColor: Colors.white,
                      textAlignVertical: TextAlignVertical.bottom,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: '0,00',
                        hintStyle: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Glow decorativo canto superior direito
        Positioned(
          right: -20,
          top: -20,
          child: IgnorePointer(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Formatter que mantém o input como moeda BRL "X.XXX,XX".
/// Aceita só dígitos do usuário e formata como decimal de 2 casas.
class _BrlMoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    // Limita a 12 dígitos (até R$ 9.999.999.999,99)
    if (digits.length > 12) digits = digits.substring(0, 12);

    final padded = digits.padLeft(3, '0');
    final intPart = padded.substring(0, padded.length - 2);
    final decPart = padded.substring(padded.length - 2);

    final intFormatted = intPart.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    // Remove leading zeros excedentes (mantém pelo menos "0" antes do separador)
    final intClean =
        intFormatted.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    final formatted = '${intClean.isEmpty ? '0' : intClean},$decPart';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Helper para converter o texto formatado de volta para double.
/// Aceita "1.234,56" / "1234,56" / "1234.56" / "1234".
double? parseBrlAmount(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  final normalized = trimmed
      .replaceAll(RegExp(r'[^\d,.\-]'), '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  return double.tryParse(normalized);
}
