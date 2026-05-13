import 'package:flutter/material.dart';

/// Seção do saldo principal + info da conta.
class HomeBalanceSection extends StatelessWidget {
  final double balance;
  final String currencyCode;
  final bool isDark;
  final bool isLoading;
  final String? accountType;
  final String? institution;
  final String? accountColor;

  const HomeBalanceSection({
    super.key,
    required this.balance,
    required this.currencyCode,
    required this.isDark,
    this.isLoading = false,
    this.accountType,
    this.institution,
    this.accountColor,
  });

  /// Converte hex string (ex: '#1A7B8C') para Color.
  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF0D4F6E);
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return const Color(0xFF0D4F6E);
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return const Color(0xFF0D4F6E);
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    // Lê o tema dinamicamente para reagir a mudanças de tema em tempo real
    // (o param isDark do construtor é ignorado intencionalmente).
    // ignore: shadow_local_variables
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  HSLColor.fromColor(_parseColor(accountColor))
                      .withLightness(0.18)
                      .toColor(),
                  HSLColor.fromColor(_parseColor(accountColor))
                      .withLightness(0.10)
                      .toColor(),
                ]
              : [
                  _parseColor(accountColor),
                  HSLColor.fromColor(_parseColor(accountColor))
                      .withLightness(
                        (HSLColor.fromColor(_parseColor(accountColor)).lightness - 0.1)
                            .clamp(0.0, 1.0),
                      )
                      .toColor(),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : _parseColor(accountColor).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label do saldo
        Text(
          'Saldo atual',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),

        // Saldo principal
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _formatBalance(),
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Info da conta
        Row(
          children: [
            if (accountType != null) ...[
              _buildInfoChip(
                icon: Icons.account_balance_rounded,
                label: accountType!,
              ),
              const SizedBox(width: 10),
            ],
            if (institution != null && institution!.isNotEmpty)
              _buildInfoChip(
                icon: Icons.business_rounded,
                label: institution!,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white60, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBalance() {
    final formatted = balance.toStringAsFixed(2).replaceAll('.', ',');
    // Adiciona separador de milhar
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }
}
