import 'package:flutter/material.dart';
import 'package:fyna/core/services/bank_notification_service.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:intl/intl.dart';

/// Dialog exibido quando uma notificação bancária é detectada.
/// Permite ao usuário confirmar ou descartar o registro da transação.
class BankTransactionDialog extends StatelessWidget {
  final ParsedBankTransaction transaction;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  const BankTransactionDialog({
    super.key,
    required this.transaction,
    required this.onConfirm,
    required this.onDismiss,
  });

  static Future<bool?> show(
    BuildContext context,
    ParsedBankTransaction transaction,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BankTransactionDialog(
        transaction: transaction,
        onConfirm: () => Navigator.pop(ctx, true),
        onDismiss: () => Navigator.pop(ctx, false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final isExpense = transaction.type == 'expense';
    final isInvestment = transaction.type == 'investment';

    final typeColor = isInvestment
        ? const Color(0xFF00C9A7)
        : isExpense
            ? const Color(0xFFFF6B6B)
            : const Color(0xFF00C853);

    final typeLabel = isInvestment
        ? 'Investimento'
        : isExpense
            ? 'Despesa'
            : 'Receita';

    final typeIcon = isInvestment
        ? Icons.trending_up_rounded
        : isExpense
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;

    return Container(
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: tc.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Ícone e banco
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notificação detectada',
                      style: TextStyle(
                          color: tc.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      transaction.bankName,
                      style: TextStyle(
                          color: tc.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                      color: typeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Valor
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tc.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  currency.format(transaction.amount),
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  transaction.description,
                  style: TextStyle(color: tc.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Deseja registrar essa transação no Fyna?',
            style: TextStyle(color: tc.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tc.textSecondary,
                    side: BorderSide(color: tc.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ignorar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: typeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Registrar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
