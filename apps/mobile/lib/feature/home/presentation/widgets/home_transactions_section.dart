import 'package:flutter/material.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/feature/transaction/domain/entities/transaction_entity.dart';

/// Seção de transações recentes — filtra por conta selecionada.
/// Suporta modo expandido via "Ver tudo" com DraggableScrollableSheet.
class HomeTransactionsSection extends StatelessWidget {
  final bool isDark;
  final List<TransactionEntity> transactions;
  final bool isLoading;
  final String? accountName;

  const HomeTransactionsSection({
    super.key,
    required this.isDark,
    this.transactions = const [],
    this.isLoading = false,
    this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: shadow_local_variables
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Mostra apenas as 5 mais recentes na home
    final preview = transactions.take(5).toList();
    final hasMore = transactions.length > 5;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12121E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transações',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (accountName != null && accountName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          accountName!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: isDark ? Colors.white30 : Colors.black38,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!isLoading && transactions.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showAllTransactions(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkAccent.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ver tudo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkAccent
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.darkAccent
                                : AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (isLoading) _buildLoadingState(),

          if (!isLoading && transactions.isEmpty) _buildEmptyState(),

          if (!isLoading && preview.isNotEmpty) _buildTransactionsList(preview),

          // Indicador de mais transações
          if (!isLoading && hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Center(
                child: Text(
                  '+ ${transactions.length - 5} transações',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
            ),

          SizedBox(height: hasMore ? 16 : 24),
        ],
      ),
    );
  }

  void _showAllTransactions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AllTransactionsSheet(
        isDark: isDark,
        transactions: transactions,
        accountName: accountName,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1C2E)
                        : const Color(0xFFF0F0F4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1C2E)
                              : const Color(0xFFF0F0F4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1C2E)
                              : const Color(0xFFF0F0F4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1C2E)
                    : const Color(0xFFF0F0F4),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 32,
                color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black12,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Nenhuma transação',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              accountName != null
                  ? 'Sem movimentações em $accountName'
                  : 'Adicione sua primeira transação',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<TransactionEntity> items) {
    final grouped = _groupByDate(items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(entry.key),
            ...entry.value.map(
              (tx) => _TransactionTile(tx: tx, isDark: isDark),
            ),
          ],
        );
      }).toList(),
    );
  }

  Map<String, List<TransactionEntity>> _groupByDate(
    List<TransactionEntity> items,
  ) {
    final grouped = <String, List<TransactionEntity>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final tx in items) {
      final txDate = DateTime(
        tx.transactionDate.year,
        tx.transactionDate.month,
        tx.transactionDate.day,
      );

      String label;
      if (txDate == today) {
        label = 'Hoje';
      } else if (txDate == yesterday) {
        label = 'Ontem';
      } else {
        label =
            '${txDate.day.toString().padLeft(2, '0')}/${txDate.month.toString().padLeft(2, '0')}/${txDate.year}';
      }

      grouped.putIfAbsent(label, () => []).add(tx);
    }
    return grouped;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white30 : Colors.black38,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Tile individual de transação ─────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final TransactionEntity tx;
  final bool isDark;

  const _TransactionTile({required this.tx, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // ignore: shadow_local_variables
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = tx.type == TransactionType.income;
    final isTransfer = tx.type == TransactionType.transfer;

    final typeColor = isTransfer
        ? AppColors.info
        : isIncome
            ? AppColors.success
            : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2C) : const Color(0xFFF8F8FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF252540)
                : const Color(0xFFEEEEF2),
          ),
        ),
        child: Row(
          children: [
            // Ícone
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                _getTransactionIcon(tx),
                color: typeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Descrição + categoria
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.categoryName ?? tx.type.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white30 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),

            // Valor
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : isTransfer ? '' : '-'} ${_formatAmount(tx.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isIncome
                        ? AppColors.success
                        : isTransfer
                            ? (isDark ? Colors.white70 : AppColors.info)
                            : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tx.type.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(TransactionEntity tx) {
    if (tx.type == TransactionType.transfer) {
      return Icons.swap_horiz_rounded;
    }

    final category = (tx.categoryName ?? '').toLowerCase();

    if (category.contains('transporte') ||
        category.contains('uber') ||
        category.contains('99')) {
      return Icons.directions_car_rounded;
    }
    if (category.contains('alimenta') ||
        category.contains('restaurante') ||
        category.contains('comida')) {
      return Icons.restaurant_rounded;
    }
    if (category.contains('mercado') || category.contains('supermer')) {
      return Icons.shopping_cart_rounded;
    }
    if (category.contains('delivery') || category.contains('ifood')) {
      return Icons.delivery_dining_rounded;
    }
    if (category.contains('salário') ||
        category.contains('salario') ||
        category.contains('renda')) {
      return Icons.payments_rounded;
    }
    if (category.contains('saúde') ||
        category.contains('saude') ||
        category.contains('médico')) {
      return Icons.medical_services_rounded;
    }
    if (category.contains('educação') ||
        category.contains('educacao') ||
        category.contains('curso')) {
      return Icons.school_rounded;
    }
    if (category.contains('lazer') || category.contains('entretenimento')) {
      return Icons.sports_esports_rounded;
    }
    if (category.contains('moradia') ||
        category.contains('aluguel') ||
        category.contains('casa')) {
      return Icons.home_rounded;
    }

    if (tx.type == TransactionType.income) {
      return Icons.arrow_downward_rounded;
    }
    return Icons.arrow_upward_rounded;
  }

  String _formatAmount(double value) {
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }
}

// ─── Bottom Sheet "Ver tudo" com todas as transações da conta ─────────────────
class _AllTransactionsSheet extends StatelessWidget {
  final bool isDark;
  final List<TransactionEntity> transactions;
  final String? accountName;

  const _AllTransactionsSheet({
    required this.isDark,
    required this.transactions,
    this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: shadow_local_variables
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        final grouped = _groupByDate(transactions);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF12121E) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle + header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Todas as transações',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (accountName != null)
                              Text(
                                '$accountName · ${transactions.length} transações',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white30
                                      : Colors.black38,
                                ),
                              ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1C1C2E)
                                  : const Color(0xFFF0F0F4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color:
                                  isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF252540)
                          : const Color(0xFFEEEEF2),
                    ),
                  ],
                ),
              ),

              // Lista scrollável
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 32),
                  itemCount: grouped.length,
                  itemBuilder: (ctx, groupIndex) {
                    final entry = grouped.entries.elementAt(groupIndex);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? Colors.white30 : Colors.black38,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        ...entry.value.map(
                          (tx) => _TransactionTile(tx: tx, isDark: isDark),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, List<TransactionEntity>> _groupByDate(
    List<TransactionEntity> items,
  ) {
    final grouped = <String, List<TransactionEntity>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final tx in items) {
      final txDate = DateTime(
        tx.transactionDate.year,
        tx.transactionDate.month,
        tx.transactionDate.day,
      );

      String label;
      if (txDate == today) {
        label = 'Hoje';
      } else if (txDate == yesterday) {
        label = 'Ontem';
      } else {
        label =
            '${txDate.day.toString().padLeft(2, '0')}/${txDate.month.toString().padLeft(2, '0')}/${txDate.year}';
      }

      grouped.putIfAbsent(label, () => []).add(tx);
    }
    return grouped;
  }
}
