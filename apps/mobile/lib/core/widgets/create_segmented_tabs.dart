import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/core/themes/theme_colors.dart';

/// Segmented tabs em pill branca usado nas telas de criação para alternar
/// entre tipos (Despesa/Receita/Transferência, Semanal/Mensal/Anual, etc.).
///
/// O label ativo recebe a cor [activeColor] (em vez do gradiente teal padrão
/// das `AppPillTabs`), permitindo coloração por contexto (vermelho para
/// despesa, verde para receita, etc.).
class CreateSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Cor do label ativo. Quando null, usa neoTeal.
  final Color? activeColor;

  const CreateSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final active = activeColor ?? tc.neoTeal;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tc.neoCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.neoCardBorder),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(i);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? active.withValues(alpha: tc.isDark ? 0.16 : 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? active : tc.neoTextMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
