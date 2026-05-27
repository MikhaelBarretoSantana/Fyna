import 'package:flutter/material.dart';
import 'package:fyna/core/themes/theme_colors.dart';

/// Linha de formulário usada nas telas de criação.
///
/// Composição: ícone à esquerda (pequeno, monocromático) + label em
/// uppercase pequeno + valor selecionado + chevron à direita.
///
/// Para um TextField inline, use [CreateInlineTextField] em vez disso.
class CreateFormFieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? hint;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isError;

  const CreateFormFieldTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.hint,
    this.trailing,
    this.onTap,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final hasValue = value != null && value!.isNotEmpty;
    final borderColor =
        isError ? tc.neoNegative.withValues(alpha: 0.5) : tc.neoCardBorder;

    return Material(
      color: tc.neoCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: tc.neoTextMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: tc.neoTextFaint,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasValue ? value! : (hint ?? '—'),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: hasValue ? tc.neoText : tc.neoTextFaint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
              if (onTap != null && trailing == null)
                Icon(Icons.chevron_right_rounded,
                    color: tc.neoTextFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Variante com TextField embutido — útil para Descrição, Nome, etc.
class CreateInlineTextField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int maxLines;
  final String? Function(String?)? validator;
  final bool autofocus;

  const CreateInlineTextField({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: tc.neoCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.neoCardBorder),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
            child: Icon(icon, size: 18, color: tc.neoTextMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: tc.neoTextFaint,
                  ),
                ),
                const SizedBox(height: 2),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLength: maxLength,
                  maxLines: maxLines,
                  validator: validator,
                  autofocus: autofocus,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: tc.neoText,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: tc.neoTextFaint,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    counterText: '',
                    errorStyle: TextStyle(
                      color: tc.neoNegative,
                      fontSize: 11.5,
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
}
