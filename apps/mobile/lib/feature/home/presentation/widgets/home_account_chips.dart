import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/feature/account/domain/entities/account_entity.dart';

/// Chips horizontais de contas exibidos abaixo da top bar.
///
/// Conta selecionada fica com fundo preenchido na cor da conta (texto branco);
/// não selecionadas ficam brancas com um "dot" colorido + nome.
class HomeAccountChips extends StatelessWidget {
  final List<AccountEntity> accounts;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const HomeAccountChips({
    super.key,
    required this.accounts,
    required this.selectedIndex,
    required this.onChanged,
  });

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF1A6F82);
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return const Color(0xFF1A6F82);
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return const Color(0xFF1A6F82);
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          return _Chip(
            label: accounts[i].name,
            color: _parseColor(accounts[i].color),
            selected: i == selectedIndex,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(i);
            },
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : tc.neoCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? color : tc.neoCardBorder,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: selected ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : tc.neoText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
