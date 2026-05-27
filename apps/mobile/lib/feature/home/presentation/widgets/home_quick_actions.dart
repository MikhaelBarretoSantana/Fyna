import 'package:flutter/material.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/icon_badge.dart';

/// Atalhos rápidos: Receita / Despesa / Transferir / Conta.
///
/// 4 cards brancos lado a lado com badge pastel + ícone + label embaixo.
class HomeQuickActions extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onAddExpense;
  final VoidCallback? onAddIncome;
  final VoidCallback? onAddTransfer;
  final VoidCallback? onAddAccount;

  const HomeQuickActions({
    super.key,
    required this.isDark,
    this.onAddExpense,
    this.onAddIncome,
    this.onAddTransfer,
    this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.south_rounded,
              label: 'Receita',
              tone: 'success',
              onTap: onAddIncome,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionCard(
              icon: Icons.north_rounded,
              label: 'Despesa',
              tone: 'danger',
              onTap: onAddExpense,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionCard(
              icon: Icons.swap_horiz_rounded,
              label: 'Transferir',
              tone: 'info',
              onTap: onAddTransfer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionCard(
              icon: Icons.account_balance_rounded,
              label: 'Conta',
              tone: 'transfer',
              onTap: onAddAccount,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tone;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.tone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Material(
      color: tc.neoCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tc.neoCardBorder),
            boxShadow: [
              BoxShadow(
                color: tc.neoCardShadow,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconBadge(
                icon: icon,
                tone: tone,
                size: 38,
                iconSize: 18,
                radius: 12,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tc.neoText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
