import 'package:flutter/material.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_list_item.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
import 'package:fyna/feature/transaction/domain/entities/transaction_entity.dart';

/// Seção "Atividade recente" da Home.
///
/// Lista as transações mais recentes (preview 5), com link "Ver tudo".
class HomeTransactionsSection extends StatelessWidget {
  final bool isDark;
  final List<TransactionEntity> transactions;
  final bool isLoading;
  final String? accountName;
  final VoidCallback? onSeeAll;

  const HomeTransactionsSection({
    super.key,
    required this.isDark,
    this.transactions = const [],
    this.isLoading = false,
    this.accountName,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final preview = transactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          label: 'Atividade recente',
          trailing: GestureDetector(
            onTap: onSeeAll ?? () => _showAll(context),
            child: Text(
              'Ver tudo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tc.neoTeal,
              ),
            ),
          ),
        ),
        if (isLoading) ..._loadingTiles(tc),
        if (!isLoading && preview.isEmpty) _emptyState(tc),
        if (!isLoading && preview.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (final tx in preview) ...[
                  _TransactionTile(tx: tx),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  List<Widget> _loadingTiles(ThemeColors tc) {
    return List.generate(
      3,
      (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: tc.neoCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tc.neoCardBorder),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: tc.neoCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tc.neoCardBorder),
        ),
        child: Column(
          children: [
            IconBadge(
              icon: Icons.receipt_long_rounded,
              tone: 'neutral',
              size: 48,
              iconSize: 22,
              radius: 14,
            ),
            const SizedBox(height: 10),
            Text(
              'Nenhuma transação',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tc.neoTextMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              accountName != null
                  ? 'Sem movimentações em $accountName'
                  : 'Adicione sua primeira transação',
              style: TextStyle(fontSize: 12, color: tc.neoTextFaint),
            ),
          ],
        ),
      ),
    );
  }

  void _showAll(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllTransactionsSheet(
        transactions: transactions,
        accountName: accountName,
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionEntity tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final isIncome = tx.type == TransactionType.income;
    final isTransfer = tx.type == TransactionType.transfer;

    final amountColor = isIncome
        ? tc.neoPositive
        : isTransfer
            ? tc.neoTeal
            : tc.neoNegative;

    final sign = isIncome ? '+' : isTransfer ? '' : '-';

    return AppListItem(
      leading: IconBadge(
        icon: _iconFor(tx),
        tone: _toneFor(tx),
      ),
      title: tx.description,
      subtitle: _subtitle(tx),
      trailing: Text(
        '${sign}R\$ ${_formatAmount(tx.amount)}',
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: amountColor,
        ),
      ),
    );
  }

  String _subtitle(TransactionEntity tx) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(
      tx.transactionDate.year,
      tx.transactionDate.month,
      tx.transactionDate.day,
    );

    String dayLabel;
    if (txDay == today) {
      dayLabel = 'Hoje';
    } else if (txDay == today.subtract(const Duration(days: 1))) {
      dayLabel = 'Ontem';
    } else {
      dayLabel =
          '${txDay.day.toString().padLeft(2, '0')}/${txDay.month.toString().padLeft(2, '0')}';
    }

    // Só exibe HH:mm quando temos hora confiável — `createdAt` no mesmo dia
    // da `transactionDate`. Para lançamentos backdatados (Ontem etc.) só
    // exibimos o dia, evitando mostrar "00:00".
    final dt = tx.displayDateTime;
    final createdAt = tx.createdAt;
    final hasReliableTime = createdAt != null &&
        createdAt.year == txDay.year &&
        createdAt.month == txDay.month &&
        createdAt.day == txDay.day;

    if (!hasReliableTime) return dayLabel;

    final timeLabel =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$dayLabel · $timeLabel';
  }

  String _toneFor(TransactionEntity tx) {
    if (tx.type == TransactionType.transfer) return 'transfer';
    final cat = (tx.categoryName ?? '').toLowerCase();
    if (cat.contains('aliment') ||
        cat.contains('comida') ||
        cat.contains('delivery') ||
        cat.contains('ifood') ||
        cat.contains('restaur')) {
      return 'food';
    }
    if (cat.contains('transp') || cat.contains('uber') || cat.contains('99')) {
      return 'transport';
    }
    if (cat.contains('mercado') ||
        cat.contains('compras') ||
        cat.contains('shopping')) {
      return 'shopping';
    }
    if (cat.contains('saúde') ||
        cat.contains('saude') ||
        cat.contains('médic')) {
      return 'health';
    }
    if (cat.contains('lazer') || cat.contains('entreten')) {
      return 'entertainment';
    }
    if (cat.contains('contas') ||
        cat.contains('aluguel') ||
        cat.contains('condomín')) {
      return 'bills';
    }
    if (cat.contains('salár') || cat.contains('salario')) return 'salary';
    return tx.type == TransactionType.income ? 'success' : 'neutral';
  }

  IconData _iconFor(TransactionEntity tx) {
    if (tx.type == TransactionType.transfer) return Icons.swap_horiz_rounded;
    final cat = (tx.categoryName ?? '').toLowerCase();
    if (cat.contains('delivery') || cat.contains('ifood')) {
      return Icons.delivery_dining_rounded;
    }
    if (cat.contains('mercado') || cat.contains('compras')) {
      return Icons.shopping_cart_rounded;
    }
    if (cat.contains('aliment') || cat.contains('restaur')) {
      return Icons.restaurant_rounded;
    }
    if (cat.contains('transp') || cat.contains('uber') || cat.contains('99')) {
      return Icons.directions_car_rounded;
    }
    if (cat.contains('salár') || cat.contains('salario')) {
      return Icons.flash_on_rounded;
    }
    if (cat.contains('saúde') || cat.contains('saude')) {
      return Icons.medical_services_rounded;
    }
    if (cat.contains('lazer')) return Icons.sports_esports_rounded;
    if (cat.contains('aluguel') || cat.contains('moradia')) {
      return Icons.home_rounded;
    }
    if (cat.contains('contas')) return Icons.receipt_long_rounded;
    return tx.type == TransactionType.income
        ? Icons.south_rounded
        : Icons.north_rounded;
  }

  String _formatAmount(double value) {
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$intPart,${parts[1]}';
  }
}

class _AllTransactionsSheet extends StatelessWidget {
  final List<TransactionEntity> transactions;
  final String? accountName;

  const _AllTransactionsSheet({
    required this.transactions,
    this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, controller) {
        return Container(
          decoration: BoxDecoration(
            color: tc.neoCardElevated,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: tc.neoTextFaint.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Todas as transações',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: tc.neoText,
                                ),
                              ),
                              if (accountName != null)
                                Text(
                                  '$accountName · ${transactions.length} lançamentos',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tc.neoTextMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close_rounded, color: tc.neoTextMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _TransactionTile(tx: transactions[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
