import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/ai_classification/domain/entities/ai_classification_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/spending_pattern_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/spending_prediction_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/investment_recommendation_entity.dart';
import 'package:fyna/feature/category/domain/entities/category_entity.dart';
import 'package:intl/intl.dart';

class AIInsightsPage extends StatefulWidget {
  const AIInsightsPage({super.key});

  @override
  State<AIInsightsPage> createState() => _AIInsightsPageState();
}

class _AIInsightsPageState extends State<AIInsightsPage>
    with SingleTickerProviderStateMixin {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  late TabController _tabController;

  // ─── Data ───
  List<SpendingPatternEntity> _patterns = [];
  List<SpendingPredictionEntity> _predictions = [];
  List<AIClassificationEntity> _pendingClassifications = [];
  List<InvestmentRecommendationEntity> _recommendations = [];
  List<CategoryEntity> _categories = [];

  // ─── Loading states ───
  bool _isLoadingPatterns = true;
  bool _isLoadingPredictions = true;
  bool _isLoadingClassifications = true;
  bool _isLoadingRecommendations = true;

  // ─── Error states ───
  String? _patternsError;
  String? _predictionsError;
  String? _classificationsError;
  String? _recommendationsError;

  // ─── Action states ───
  bool _isAnalyzing = false;
  final Set<String> _confirmingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadAllData();
    _triggerAnalysisInBackground();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Dispara análise no Python em background (fire-and-forget ao abrir a tela).
  Future<void> _triggerAnalysisInBackground() async {
    try {
      await Injection.instance.aiInsightsRepository.triggerAnalysis();
    } catch (_) {}
  }

  /// Dispara análise e recarrega todos os dados (botão manual).
  Future<void> _triggerAndRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _isAnalyzing = true);
    try {
      await Injection.instance.aiInsightsRepository.triggerAnalysis();
      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        _isLoadingPatterns = true;
        _isLoadingPredictions = true;
        _isLoadingClassifications = true;
        _isLoadingRecommendations = true;
      });
      await _loadAllData();
      _showSnackBar('Análise atualizada com sucesso', isError: false);
    } catch (_) {
      _showSnackBar('Erro ao atualizar análise');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadPatterns(),
      _loadPredictions(),
      _loadClassifications(),
      _loadRecommendations(),
      _loadCategories(),
    ]);
  }

  Future<void> _loadPatterns() async {
    try {
      final patterns =
          await Injection.instance.aiInsightsRepository.getActivePatterns();
      if (mounted) {
        setState(() {
          _patterns = patterns;
          _isLoadingPatterns = false;
          _patternsError = null;
        });
      }
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _patternsError = e.message;
          _isLoadingPatterns = false;
        });
      }
    } on NetworkException {
      if (mounted) {
        setState(() {
          _patternsError = 'Sem conexão';
          _isLoadingPatterns = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _patternsError = 'Erro ao carregar padrões';
          _isLoadingPatterns = false;
        });
      }
    }
  }

  Future<void> _loadPredictions() async {
    try {
      final predictions =
          await Injection.instance.aiInsightsRepository.getPredictions();
      if (mounted) {
        setState(() {
          _predictions = predictions;
          _isLoadingPredictions = false;
          _predictionsError = null;
        });
      }
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _predictionsError = e.message;
          _isLoadingPredictions = false;
        });
      }
    } on NetworkException {
      if (mounted) {
        setState(() {
          _predictionsError = 'Sem conexão';
          _isLoadingPredictions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _predictionsError = 'Erro ao carregar previsões';
          _isLoadingPredictions = false;
        });
      }
    }
  }

  Future<void> _loadClassifications() async {
    try {
      final classifications = await Injection
          .instance.aiInsightsRepository
          .getPendingClassifications();
      if (mounted) {
        setState(() {
          _pendingClassifications = classifications;
          _isLoadingClassifications = false;
          _classificationsError = null;
        });
      }
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _classificationsError = e.message;
          _isLoadingClassifications = false;
        });
      }
    } on NetworkException {
      if (mounted) {
        setState(() {
          _classificationsError = 'Sem conexão';
          _isLoadingClassifications = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _classificationsError = 'Erro ao carregar classificações';
          _isLoadingClassifications = false;
        });
      }
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final recommendations =
          await Injection.instance.aiInsightsRepository.getRecommendations();
      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoadingRecommendations = false;
          _recommendationsError = null;
        });
      }
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _recommendationsError = e.message;
          _isLoadingRecommendations = false;
        });
      }
    } on NetworkException {
      if (mounted) {
        setState(() {
          _recommendationsError = 'Sem conexão';
          _isLoadingRecommendations = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _recommendationsError = 'Erro ao carregar recomendações';
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await Injection.instance.categoryRepository.getCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (_) {
      // Categorias são auxiliares — não bloqueia a tela
    }
  }

  // ─── Ações ───

  Future<void> _confirmClassification(
      AIClassificationEntity classification, String categoryId) async {
    if (_confirmingIds.contains(classification.id)) return;
    setState(() => _confirmingIds.add(classification.id));

    try {
      final result = await Injection.instance.aiInsightsRepository
          .confirmClassification(classification.id, categoryId);

      if (mounted) {
        final catName = _categories
                .where((c) => c.id == categoryId)
                .map((c) => c.name)
                .firstOrNull ??
            result.confirmedCategoryName ??
            'categoria selecionada';

        final wasCorrected =
            categoryId != classification.suggestedCategoryId;

        setState(() {
          _pendingClassifications
              .removeWhere((c) => c.id == classification.id);
          _confirmingIds.remove(classification.id);
        });

        _showSnackBar(
          wasCorrected
              ? 'Corrigido para "$catName" — a IA vai aprender'
              : 'Classificado como "$catName"',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _confirmingIds.remove(classification.id));
        _showSnackBar('Erro ao confirmar classificação');
      }
    }
  }

  Future<void> _markRecommendationViewed(
      InvestmentRecommendationEntity rec) async {
    try {
      await Injection.instance.aiInsightsRepository.markAsViewed(rec.id);
      if (mounted) {
        setState(() {
          final idx = _recommendations.indexWhere((r) => r.id == rec.id);
          if (idx != -1) {
            _recommendations[idx] = InvestmentRecommendationEntity(
              id: rec.id,
              recommendationType: rec.recommendationType,
              title: rec.title,
              description: rec.description,
              allocationSuggestion: rec.allocationSuggestion,
              potentialReturn: rec.potentialReturn,
              riskLevel: rec.riskLevel,
              wasViewed: true,
              wasFollowed: rec.wasFollowed,
              modelVersion: rec.modelVersion,
              generatedAt: rec.generatedAt,
              viewedAt: DateTime.now(),
            );
          }
        });
      }
    } catch (_) {
      // Falha silenciosa — não impacta UX
    }
  }

  Future<void> _markRecommendationFollowed(
      InvestmentRecommendationEntity rec) async {
    try {
      await Injection.instance.aiInsightsRepository.markAsFollowed(rec.id);
      if (mounted) {
        setState(() {
          final idx = _recommendations.indexWhere((r) => r.id == rec.id);
          if (idx != -1) {
            _recommendations[idx] = InvestmentRecommendationEntity(
              id: rec.id,
              recommendationType: rec.recommendationType,
              title: rec.title,
              description: rec.description,
              allocationSuggestion: rec.allocationSuggestion,
              potentialReturn: rec.potentialReturn,
              riskLevel: rec.riskLevel,
              wasViewed: true,
              wasFollowed: true,
              modelVersion: rec.modelVersion,
              generatedAt: rec.generatedAt,
              viewedAt: rec.viewedAt ?? DateTime.now(),
            );
          }
        });
        _showSnackBar('Recomendação marcada como seguida', isError: false);
      }
    } catch (_) {
      _showSnackBar('Erro ao atualizar recomendação');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F5F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildTabBar(),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPatternsTab(),
                  _buildPredictionsTab(),
                  _buildClassificationsTab(),
                  _buildRecommendationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1C2E)
                    : const Color(0xFFEEEEF2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insights',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Inteligência artificial aplicada às suas finanças',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          // Badge de pendentes
          if (_pendingClassifications.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C5CFC).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_fix_high_rounded,
                      size: 14, color: Color(0xFF7C5CFC)),
                  const SizedBox(width: 4),
                  Text(
                    '${_pendingClassifications.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7C5CFC),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          // Botão de atualizar análise
          GestureDetector(
            onTap: _isAnalyzing ? null : _triggerAndRefresh,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1C2E)
                    : const Color(0xFFEEEEF2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isAnalyzing
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? AppColors.darkAccent : AppColors.primary,
                      ),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab Bar ───
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : const Color(0xFFEEEEF2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? AppColors.darkAccent : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white38 : Colors.black45,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
        padding: const EdgeInsets.all(3),
        tabs: [
          _buildTab('Padrões', _patterns.length, _isLoadingPatterns),
          _buildTab('Previsões', _predictions.length, _isLoadingPredictions),
          _buildTab('Classif.', _pendingClassifications.length,
              _isLoadingClassifications),
          _buildTab(
              'Invest.', _recommendations.length, _isLoadingRecommendations),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int count, bool isLoading) {
    return Tab(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (!isLoading && count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  PADRÕES DE GASTO
  // ═══════════════════════════════════════

  Widget _buildPatternsTab() {
    return RefreshIndicator(
      onRefresh: _loadPatterns,
      color: isDark ? AppColors.darkAccent : AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_patternsError != null) _buildErrorCard(_patternsError!),
            _buildSectionTitle('Padrões Detectados'),
            if (_isLoadingPatterns)
              ..._buildShimmerCards(3)
            else if (_patterns.isEmpty)
              _buildEmptyCard(
                icon: Icons.psychology_rounded,
                title: 'Nenhum padrão detectado',
                subtitle:
                    'Continue registrando transações — a IA identificará padrões de gasto automaticamente.',
              )
            else
              ..._patterns.map(_buildPatternCard),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternCard(SpendingPatternEntity pattern) {
    final typeConfig = _patternTypeConfig(pattern.patternType);
    final confidence = (pattern.significanceScore * 100).round();
    final dateRange = _formatPatternDateRange(pattern);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeConfig.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeConfig.icon, color: typeConfig.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeConfig.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeConfig.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: typeConfig.color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Confidence bar
                        _buildConfidenceIndicator(confidence),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pattern.description,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (dateRange != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.date_range_rounded,
                    size: 14,
                    color: isDark ? Colors.white24 : Colors.black26),
                const SizedBox(width: 6),
                Text(
                  dateRange,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(int percent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(
                percent >= 80
                    ? AppColors.success
                    : percent >= 50
                        ? AppColors.warning
                        : AppColors.error,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$percent%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  _PatternTypeConfig _patternTypeConfig(String type) {
    switch (type) {
      case 'RECURRING':
        return _PatternTypeConfig('Recorrente', Icons.replay_rounded,
            const Color(0xFF3CADE8));
      case 'INCREASING':
        return _PatternTypeConfig('Em alta', Icons.trending_up_rounded,
            AppColors.warning);
      case 'DECREASING':
        return _PatternTypeConfig('Em queda', Icons.trending_down_rounded,
            AppColors.success);
      case 'SEASONAL':
        return _PatternTypeConfig('Sazonal', Icons.wb_sunny_rounded,
            const Color(0xFFE8893C));
      case 'ANOMALY':
        return _PatternTypeConfig(
            'Anomalia', Icons.warning_amber_rounded, AppColors.error);
      default:
        return _PatternTypeConfig(
            type, Icons.insights_rounded, const Color(0xFF7C5CFC));
    }
  }

  String? _formatPatternDateRange(SpendingPatternEntity pattern) {
    if (pattern.detectedFrom == null && pattern.detectedTo == null) return null;
    final fmt = DateFormat("dd MMM yyyy", 'pt_BR');
    final from =
        pattern.detectedFrom != null ? fmt.format(pattern.detectedFrom!) : '?';
    final to =
        pattern.detectedTo != null ? fmt.format(pattern.detectedTo!) : 'agora';
    return '$from — $to';
  }

  // ═══════════════════════════════════════
  //  PREVISÕES DE GASTO
  // ═══════════════════════════════════════

  Widget _buildPredictionsTab() {
    return RefreshIndicator(
      onRefresh: _loadPredictions,
      color: isDark ? AppColors.darkAccent : AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_predictionsError != null)
              _buildErrorCard(_predictionsError!),
            _buildSectionTitle('Previsão por Categoria'),
            if (_isLoadingPredictions)
              ..._buildShimmerCards(3)
            else if (_predictions.isEmpty)
              _buildEmptyCard(
                icon: Icons.auto_graph_rounded,
                title: 'Nenhuma previsão disponível',
                subtitle:
                    'A IA precisa de mais dados para gerar previsões de gasto.',
              )
            else ...[
              if (_predictions.length >= 3) _buildPredictionChart(),
              const SizedBox(height: 16),
              ..._predictions.map(_buildPredictionCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionChart() {
    // Agrupa previsões por categoria e mostra barras previsto vs real
    final displayItems = _predictions.take(6).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
      decoration: _cardDecoration(),
      child: BarChart(
        BarChartData(
          barGroups: displayItems.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: p.predictedAmount,
                  color: isDark ? AppColors.darkAccent : AppColors.primary,
                  width: 14,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                if (p.actualAmount != null)
                  BarChartRodData(
                    toY: p.actualAmount!,
                    color: p.actualAmount! > p.predictedAmount
                        ? AppColors.error.withValues(alpha: 0.7)
                        : AppColors.success.withValues(alpha: 0.7),
                    width: 14,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
              ],
            );
          }).toList(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _chartInterval(displayItems),
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= 0 && i < displayItems.length) {
                    final name = displayItems[i].categoryName ?? '?';
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        name.length > 6
                            ? '${name.substring(0, 5)}.'
                            : name,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white30 : Colors.black38,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  double _chartInterval(List<SpendingPredictionEntity> items) {
    if (items.isEmpty) return 1000;
    double max = 0;
    for (final p in items) {
      if (p.predictedAmount > max) max = p.predictedAmount;
      if (p.actualAmount != null && p.actualAmount! > max) {
        max = p.actualAmount!;
      }
    }
    if (max <= 0) return 1000;
    return (max / 4).ceilToDouble();
  }

  Widget _buildPredictionCard(SpendingPredictionEntity prediction) {
    final hasActual = prediction.actualAmount != null;
    final accuracy = prediction.accuracyPercent;
    final isOver =
        hasActual && prediction.actualAmount! > prediction.predictedAmount;
    final dateStr = DateFormat("MMM yyyy", 'pt_BR')
        .format(prediction.predictionDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkAccent : AppColors.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_graph_rounded,
                  color: isDark ? AppColors.darkAccent : AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.categoryName ?? 'Categoria',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white30 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              if (accuracy != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (accuracy >= 80
                            ? AppColors.success
                            : accuracy >= 50
                                ? AppColors.warning
                                : AppColors.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${accuracy.toStringAsFixed(0)}% precisa',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accuracy >= 80
                          ? AppColors.success
                          : accuracy >= 50
                              ? AppColors.warning
                              : AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Valores
          Row(
            children: [
              Expanded(
                child: _buildValueLabel(
                  label: 'Previsto',
                  value: _formatCurrency(prediction.predictedAmount),
                  color: isDark ? AppColors.darkAccent : AppColors.primary,
                ),
              ),
              if (hasActual)
                Expanded(
                  child: _buildValueLabel(
                    label: 'Real',
                    value: _formatCurrency(prediction.actualAmount!),
                    color: isOver ? AppColors.error : AppColors.success,
                  ),
                ),
              if (prediction.confidenceLower != null &&
                  prediction.confidenceUpper != null)
                Expanded(
                  child: _buildValueLabel(
                    label: 'Intervalo',
                    value:
                        '${_formatCurrencyShort(prediction.confidenceLower!)} — ${_formatCurrencyShort(prediction.confidenceUpper!)}',
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueLabel({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  //  CLASSIFICAÇÕES
  // ═══════════════════════════════════════

  Widget _buildClassificationsTab() {
    return RefreshIndicator(
      onRefresh: _loadClassifications,
      color: isDark ? AppColors.darkAccent : AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_classificationsError != null)
              _buildErrorCard(_classificationsError!),
            _buildSectionTitle('Pendentes de Confirmação'),
            if (_isLoadingClassifications)
              ..._buildShimmerCards(3)
            else if (_pendingClassifications.isEmpty)
              _buildEmptyCard(
                icon: Icons.auto_fix_high_rounded,
                title: 'Tudo classificado',
                subtitle:
                    'Não há classificações pendentes. A IA classificará novas transações automaticamente.',
              )
            else
              ..._pendingClassifications.map(_buildClassificationCard),
            const SizedBox(height: 24),
            _buildSectionTitle('Como funciona'),
            _buildHowItWorksCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassificationCard(AIClassificationEntity classification) {
    final confidence = (classification.confidenceScore * 100).round();
    final isConfirming = _confirmingIds.contains(classification.id);

    return AnimatedOpacity(
      opacity: isConfirming ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C5CFC).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_fix_high_rounded,
                    color: Color(0xFF7C5CFC), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classification.originalText ?? 'Transação',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Sugestão: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white30 : Colors.black38,
                          ),
                        ),
                        Text(
                          classification.suggestedCategoryName ?? '—',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C5CFC),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildConfidenceIndicator(confidence),
            ],
          ),
          const SizedBox(height: 14),
          // Botões de ação
          if (isConfirming)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? AppColors.darkAccent : AppColors.primary,
                  ),
                ),
              ),
            )
          else
          Row(
            children: [
              // Confirmar sugestão
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (classification.suggestedCategoryId != null) {
                      HapticFeedback.mediumImpact();
                      _confirmClassification(
                          classification, classification.suggestedCategoryId!);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded,
                            size: 16, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text(
                          'Confirmar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Corrigir categoria
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCategorySelectorSheet(classification),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_rounded,
                            size: 16,
                            color: isDark ? Colors.white54 : Colors.black45),
                        const SizedBox(width: 6),
                        Text(
                          'Corrigir',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
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

  void _showCategorySelectorSheet(AIClassificationEntity classification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.55,
          ),
          padding:
              EdgeInsets.fromLTRB(20, 14, 20, bottomPadding > 0 ? 12 : 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14142A) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Escolha a categoria correta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected =
                        cat.id == classification.suggestedCategoryId;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          HapticFeedback.mediumImpact();
                          _confirmClassification(classification, cat.id);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF7C5CFC)
                                    .withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF7C5CFC)
                                      .withValues(alpha: 0.2)
                                  : (isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.06)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                const Icon(Icons.auto_fix_high_rounded,
                                    size: 16, color: Color(0xFF7C5CFC)),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildHowItWorksCard() {
    final steps = [
      (Icons.receipt_rounded, 'Transação criada', 'Sem categoria definida'),
      (Icons.smart_toy_rounded, 'IA classifica', 'Sugere a mais provável'),
      (Icons.check_circle_rounded, 'Você confirma', 'Aceite ou corrija'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final (icon, title, desc) = entry.value;
          final isLast = entry.key == steps.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (isDark
                              ? AppColors.darkAccent
                              : AppColors.primary)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon,
                        color:
                            isDark ? AppColors.darkAccent : AppColors.primary,
                        size: 18),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 20,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          )),
                      Text(desc,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white30 : Colors.black38,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════
  //  RECOMENDAÇÕES DE INVESTIMENTO
  // ═══════════════════════════════════════

  Widget _buildRecommendationsTab() {
    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      color: isDark ? AppColors.darkAccent : AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_recommendationsError != null)
              _buildErrorCard(_recommendationsError!),
            _buildSectionTitle('Recomendações de Investimento'),
            if (_isLoadingRecommendations)
              ..._buildShimmerCards(3)
            else if (_recommendations.isEmpty)
              _buildEmptyCard(
                icon: Icons.lightbulb_rounded,
                title: 'Nenhuma recomendação',
                subtitle:
                    'Baseado no seu perfil, a IA sugerirá investimentos adequados conforme analisar seus dados.',
              )
            else
              ..._recommendations.map(_buildRecommendationCard),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(InvestmentRecommendationEntity rec) {
    final riskConfig = _riskConfig(rec.riskLevel ?? 0.5);

    return GestureDetector(
      onTap: () {
        if (!rec.wasViewed) _markRecommendationViewed(rec);
        _showRecommendationDetail(rec);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14142A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: !rec.wasViewed
                ? const Color(0xFF7C5CFC).withValues(alpha: 0.3)
                : (isDark
                    ? const Color(0xFF252540)
                    : const Color(0xFFEEEEF2)),
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
                    color: riskConfig.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(riskConfig.icon, color: riskConfig.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: riskConfig.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rec.typeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: riskConfig.color,
                              ),
                            ),
                          ),
                          if (!rec.wasViewed) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C5CFC),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          if (rec.wasFollowed == true) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle_rounded,
                                size: 14, color: AppColors.success),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (rec.potentialReturn != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${rec.potentialReturn!.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        'retorno est.',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white30 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              rec.description,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showRecommendationDetail(InvestmentRecommendationEntity rec) {
    final riskConfig = _riskConfig(rec.riskLevel ?? 0.5);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return Container(
          padding:
              EdgeInsets.fromLTRB(20, 14, 20, bottomPadding > 0 ? 12 : 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14142A) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: riskConfig.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(riskConfig.icon,
                        color: riskConfig.color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      rec.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                rec.description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              if (rec.allocationSuggestion != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sugestão de alocação',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec.allocationSuggestion!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Ação: marcar como seguida
              if (rec.wasFollowed != true)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _markRecommendationFollowed(rec);
                    },
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text('Seguir recomendação',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.darkAccent : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  _RiskConfig _riskConfig(double riskLevel) {
    if (riskLevel <= 0.3) {
      return _RiskConfig(
          'Baixo', Icons.shield_rounded, AppColors.success);
    } else if (riskLevel <= 0.6) {
      return _RiskConfig('Médio', Icons.speed_rounded, AppColors.warning);
    } else {
      return _RiskConfig(
          'Alto', Icons.local_fire_department_rounded, AppColors.error);
    }
  }

  // ═══════════════════════════════════════
  //  WIDGETS COMPARTILHADOS
  // ═══════════════════════════════════════

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C1C2E)
                  : const Color(0xFFEEEEF2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon,
                size: 28, color: isDark ? Colors.white12 : Colors.black12),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black26,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildShimmerCards(int count) {
    return List.generate(count, (i) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 90,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14142A) : const Color(0xFFEEEEF2),
          borderRadius: BorderRadius.circular(18),
        ),
      );
    });
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: isDark ? const Color(0xFF14142A) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEF2),
      ),
    );
  }

  // ─── Utils ───

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }

  String _formatCurrencyShort(double value) {
    if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(1)}k';
    }
    return _formatCurrency(value);
  }
}

// ─── Config classes ───

class _PatternTypeConfig {
  final String label;
  final IconData icon;
  final Color color;
  const _PatternTypeConfig(this.label, this.icon, this.color);
}

class _RiskConfig {
  final String label;
  final IconData icon;
  final Color color;
  const _RiskConfig(this.label, this.icon, this.color);
}