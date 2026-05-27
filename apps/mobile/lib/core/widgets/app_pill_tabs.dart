import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/core/themes/theme_colors.dart';

/// Barra horizontal de "pills" (Todas, Receitas, Despesas...).
///
/// Pill ativa recebe gradiente teal; inativas ficam com fundo neutro.
/// Faz scroll horizontal automaticamente.
class AppPillTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final EdgeInsetsGeometry padding;
  final List<int>? badges;

  const AppPillTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.badges,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isActive = index == selectedIndex;
          final badge = badges != null && index < badges!.length
              ? badges![index]
              : null;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                gradient: isActive ? tc.pillActiveGradient : null,
                color: isActive ? null : tc.pillInactiveBg,
                borderRadius: BorderRadius.circular(22),
                border: isActive
                    ? null
                    : Border.all(color: tc.pillInactiveBorder),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: tc.neoTeal.withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : tc.neoText,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.22)
                            : tc.neoText.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$badge',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : tc.neoTextMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
