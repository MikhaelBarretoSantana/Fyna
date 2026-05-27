import 'package:flutter/material.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/hero_gradient_card.dart';

/// Card principal do saldo + receitas/despesas do mês.
///
/// Usa o gradiente teal hero do design system.
class HomeBalanceSection extends StatefulWidget {
  final double balance;
  final String currencyCode;
  final bool isDark;
  final bool isLoading;
  final String? accountType;
  final String? institution;
  final String? accountColor;
  final double? monthIncome;
  final double? monthExpense;

  const HomeBalanceSection({
    super.key,
    required this.balance,
    required this.currencyCode,
    required this.isDark,
    this.isLoading = false,
    this.accountType,
    this.institution,
    this.accountColor,
    this.monthIncome,
    this.monthExpense,
  });

  @override
  State<HomeBalanceSection> createState() => _HomeBalanceSectionState();
}

class _HomeBalanceSectionState extends State<HomeBalanceSection> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: HeroGradientCard(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: widget.isLoading ? _buildLoading() : _buildContent(tc),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 160,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: 220,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _miniLoading()),
            const SizedBox(width: 10),
            Expanded(child: _miniLoading()),
          ],
        ),
      ],
    );
  }

  Widget _miniLoading() => Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
      );

  Widget _buildContent(ThemeColors tc) {
    final label = (widget.accountType ?? 'Saldo')
        .toUpperCase()
        .replaceAll('_', ' ');
    final balanceText = _hidden ? 'R\$ ••••••••' : _formatMoney(widget.balance);

    final parts = balanceText.split(',');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'SALDO · $label',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _hidden = !_hidden),
              child: Icon(
                _hidden
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                height: 1.1,
              ),
              children: [
                TextSpan(text: intPart, style: const TextStyle(fontSize: 38)),
                TextSpan(
                  text: ',$decPart',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                icon: Icons.south_rounded,
                label: 'Receitas',
                value: _hidden
                    ? '••••'
                    : _formatMoney(widget.monthIncome ?? 0),
                accent: const Color(0xFF6BE3B0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                icon: Icons.north_rounded,
                label: 'Despesas',
                value: _hidden
                    ? '••••'
                    : _formatMoney(widget.monthExpense ?? 0),
                accent: const Color(0xFFFF8585),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatMoney(double value) {
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
