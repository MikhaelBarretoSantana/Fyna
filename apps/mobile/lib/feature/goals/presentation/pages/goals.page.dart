import 'package:flutter/material.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/enums/goal_status.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/goals/domain/entities/financial_goal_entity.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  List<FinancialGoalEntity> _goals = [];
  bool _isLoading = true;
  String? _errorMessage;
  GoalStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    if (!_isLoading) setState(() => _isLoading = true);
    setState(() => _errorMessage = null);

    try {
      final goals = await Injection.instance.goalRepository.getGoals();
      if (mounted) {
        setState(() {
          _goals = goals;
          _isLoading = false;
        });
      }
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } on NetworkException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sem conexão com a internet';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar metas';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteGoal(FinancialGoalEntity goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index == -1) return;
    setState(() => _goals.removeAt(index));

    try {
      await Injection.instance.goalRepository.deleteGoal(goal.id);
    } catch (_) {
      if (mounted) {
        setState(() => _goals.insert(index, goal));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao excluir meta'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F5F8),
      appBar: AppBar(
        title: const Text('Metas Financeiras'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        actions: [
          IconButton(
            onPressed: () async {
              final created =
                  await Navigator.pushNamed(context, AppRoutes.createGoal);
              if (created == true) _loadGoals();
            },
            icon: Icon(
              Icons.add_rounded,
              color: isDark ? AppColors.darkAccent : AppColors.primary,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadGoals,
        color: isDark ? AppColors.darkAccent : AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? AppColors.darkAccent : AppColors.primary,
        ),
      );
    }
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    return Column(
      children: [
        _buildOverview(),
        const SizedBox(height: 16),
        _buildStatusFilter(),
        const SizedBox(height: 12),
        Expanded(
          child: _goals.isEmpty
              ? _buildEmptyState()
              : _buildGoalsList(),
        ),
      ],
    );
  }

  Widget _buildOverview() {
    final active =
        _goals.where((g) => g.status == GoalStatus.IN_PROGRESS).length;
    final completed =
        _goals.where((g) => g.status == GoalStatus.COMPLETED).length;
    final totalTarget = _goals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final totalCurrent = _goals.fold(0.0, (sum, g) => sum + g.currentAmount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A2A3E), const Color(0xFF0F1B2D)]
              : [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildOverviewStat('$active', 'Em andamento', Icons.flag_rounded),
          const SizedBox(width: 20),
          _buildOverviewStat(
              '$completed', 'Concluídas', Icons.check_circle_rounded),
          const SizedBox(width: 20),
          _buildOverviewStat(
            '${totalTarget > 0 ? ((totalCurrent / totalTarget) * 100).toStringAsFixed(0) : 0}%',
            'Progresso geral',
            Icons.trending_up_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = [null, ...GoalStatus.values];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = _filterStatus == status;
          final label = status == null ? 'Todas' : status.label;
          return GestureDetector(
            onTap: () => setState(() => _filterStatus = status),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.darkAccent : AppColors.primary)
                    : (isDark
                        ? const Color(0xFF1C1C2E)
                        : const Color(0xFFEEEEF2)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white38 : Colors.black45),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalsList() {
    final filtered = _filterStatus == null
        ? _goals
        : _goals.where((g) => g.status == _filterStatus).toList();

    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Nenhuma meta com esse status',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildGoalCard(filtered[index]),
    );
  }

  Widget _buildGoalCard(FinancialGoalEntity goal) {
    final progress = goal.progressPercent / 100;
    final goalColor = _parseColor(goal.color);
    final daysLeft =
        goal.targetDate?.difference(DateTime.now()).inDays;

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      onDismissed: (_) => _deleteGoal(goal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14142A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? const Color(0xFF252540)
                : const Color(0xFFEEEEF2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.flag_rounded, color: goalColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (daysLeft != null && daysLeft > 0)
                        Text(
                          '$daysLeft dias restantes',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white30 : Colors.black38,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(goal.status),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                valueColor: AlwaysStoppedAnimation(goalColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatCurrency(goal.currentAmount),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'de ${_formatCurrency(goal.targetAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(GoalStatus status) {
    Color color;
    switch (status) {
      case GoalStatus.IN_PROGRESS:
        color = AppColors.info;
        break;
      case GoalStatus.COMPLETED:
        color = AppColors.success;
        break;
      case GoalStatus.CANCELLED:
        color = AppColors.error;
        break;
      case GoalStatus.PAUSED:
        color = AppColors.warning;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flag_rounded,
                  size: 56,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma meta definida',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Defina metas para alcançar seus sonhos',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final created = await Navigator.pushNamed(
                        context, AppRoutes.createGoal);
                    if (created == true) _loadGoals();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Criar meta'),
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
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: AppColors.error.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? 'Erro inesperado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loadGoals,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return isDark ? AppColors.darkAccent : AppColors.primary;
    }
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) {
      return isDark ? AppColors.darkAccent : AppColors.primary;
    }
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) {
      return isDark ? AppColors.darkAccent : AppColors.primary;
    }
    return Color(0xFF000000 | value);
  }

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }
}
