import 'package:flutter/material.dart';
import 'package:fyna/core/constants/app_colors.dart';

/// Botões de ação rápida: Despesa, Receita, Transferência, Conta.
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
    // ignore: shadow_local_variables
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.arrow_downward_rounded,
              label: 'Despesa',
              onTap: onAddExpense ?? () {},
              accentColor: const Color(0xFFFF5252),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.arrow_upward_rounded,
              label: 'Receita',
              onTap: onAddIncome ?? () {},
              accentColor: const Color(0xFF00C853),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.swap_horiz_rounded,
              label: 'Transferir',
              onTap: onAddTransfer ?? () {},
              accentColor: const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.account_balance_rounded,
              label: 'Conta',
              onTap: onAddAccount ?? () {},
              accentColor: isDark ? AppColors.darkAccent : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? accentColor.withValues(alpha: 0.15)
                : accentColor.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.08 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withValues(alpha: 0.15),
                    accentColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
