import 'package:flutter/material.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/feature/budget/domain/entities/budget_entity.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // TODO: Substituir por dados da API
  final List<BudgetEntity> _budgets = [];
  bool _isLoading = false;

  double get _totalLimit =>
      _budgets.fold(0.0, (sum, b) => sum + b.amountLimit);
  double get _totalSpent =>
      _budgets.fold(0.0, (sum, b) => sum + b.amountSpent);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F5F8),
      appBar: AppBar(
        title: const Text('Orçamentos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.createBudget),
            icon: Icon(
              Icons.add_rounded,
              color: isDark ? AppColors.darkAccent : AppColors.primary,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            // Resumo geral
            _buildOverviewCard(),
            const SizedBox(height: 20),
            // Lista de orçamentos
            if (_isLoading)
              _buildLoadingState()
            else if (_budgets.isEmpty)
              _buildEmptyState()
            else
              ..._budgets.map((b) => _buildBudgetCard(b)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final percent =
        _totalLimit > 0 ? (_totalSpent / _totalLimit).clamp(0.0, 1.0) : 0.0;
    final remaining = _totalLimit - _totalSpent;
    Color progressColor;
    if (percent < 0.5) {
      progressColor = AppColors.success;
    } else if (percent < 0.8) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.error;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A2A3E), const Color(0xFF0F1B2D)]
              : [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primaryDark)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo do mês',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gasto',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                    Text(
                      _formatCurrency(_totalSpent),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Disponível',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                    Text(
                      _formatCurrency(remaining),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: remaining >= 0
                            ? AppColors.accentLight
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(percent * 100).toStringAsFixed(0)}% utilizado de ${_formatCurrency(_totalLimit)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BudgetEntity budget) {
    final percent = budget.percentUsed / 100;
    Color progressColor;
    if (percent < 0.5) {
      progressColor = AppColors.success;
    } else if (percent < 0.8) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.error;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14142A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pie_chart_rounded,
                  color: progressColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (budget.categoryName != null)
                      Text(
                        budget.categoryName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white30 : Colors.black38,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${budget.percentUsed.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatCurrency(budget.amountSpent)} de ${_formatCurrency(budget.amountLimit)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Text(
                'Resta ${_formatCurrency(budget.remainingAmount)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: budget.remainingAmount >= 0
                      ? (isDark ? AppColors.darkAccent : AppColors.success)
                      : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 56,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum orçamento definido',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie orçamentos para controlar seus gastos',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.createBudget),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Criar orçamento'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.darkAccent : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: CircularProgressIndicator(
          color: isDark ? AppColors.darkAccent : AppColors.primary,
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    final formatted = value.abs().toStringAsFixed(2).replaceAll('.', ',');
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    final prefix = value < 0 ? '-' : '';
    return '${prefix}R\$ $intPart,${parts[1]}';
  }
}
