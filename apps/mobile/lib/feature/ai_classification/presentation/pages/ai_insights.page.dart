import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/enums/category_type.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_pill_tabs.dart';
import 'package:fyna/core/widgets/category_picker_sheet.dart';
import 'package:fyna/core/widgets/hero_gradient_card.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
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

class _AIInsightsPageState extends State<AIInsightsPage> {
  int _selectedTab = 0; // 0=Padrões, 1=Previsões, 2=Classif., 3=Invest.

  // ─── Data ───
  List<SpendingPatternEntity> _patterns = [];
  List<SpendingPredictionEntity> _predictions = [];
  List<AIClassificationEntity> _pendingClassifications = [];
  List<InvestmentRecommendationEntity> _recommendations = [];
  List<CategoryEntity> _categories = [];

  // ─── Loading ───
  bool _isLoadingPatterns = true;
  bool _isLoadingPredictions = true;
  bool _isLoadingClassifications = true;
  bool _isLoadingRecommendations = true;

  // ─── Errors ───
  String? _patternsError;
  String? _predictionsError;
  String? _classificationsError;
  String? _recommendationsError;

  // ─── Action state ───
  bool _isAnalyzing = false;
  final Set<String> _confirmingIds = {};
  final Map<String, TransactionType> _txTypeByClassification = {};

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _triggerAnalysisInBackground();
  }

  Future<void> _triggerAnalysisInBackground() async {
    try {
      await Injection.instance.aiInsightsRepository.triggerAnalysis();
    } catch (_) {}
  }

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
      _showSnack('Análise atualizada', isError: false);
    } catch (_) {
      _showSnack('Erro ao atualizar análise');
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
    } catch (_) {}
  }

  // ─── Classifications actions ───

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
        _showSnack(
          wasCorrected
              ? 'Corrigido para "$catName" — a IA vai aprender'
              : 'Classificado como "$catName"',
          isError: false,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _confirmingIds.remove(classification.id));
        _showSnack('Erro ao confirmar classificação');
      }
    }
  }

  /// Busca o tipo da transação vinculada à classificação (com cache).
  Future<TransactionType?> _fetchTransactionType(
    AIClassificationEntity classification,
  ) async {
    final cached = _txTypeByClassification[classification.id];
    if (cached != null) return cached;
    final txId = classification.transactionId;
    if (txId == null || txId.isEmpty) return null;
    try {
      final tx = await Injection.instance.transactionRepository
          .getTransaction(txId);
      _txTypeByClassification[classification.id] = tx.type;
      return tx.type;
    } catch (_) {
      return null;
    }
  }

  CategoryType _categoryTypeFor(TransactionType tx) {
    switch (tx) {
      case TransactionType.income:
        return CategoryType.income;
      case TransactionType.expense:
        return CategoryType.expense;
      case TransactionType.transfer:
        return CategoryType.transfer;
    }
  }

  Future<void> _showCategorySelectorSheet(
      AIClassificationEntity classification) async {
    // Fix prévio: filtra por tipo da transação para impedir incompatibilidade
    // (TRANSFER em INCOME, etc.). Mantido aqui.
    final txType = await _fetchTransactionType(classification);
    if (!mounted) return;
    final CategoryType? allowedType =
        txType != null ? _categoryTypeFor(txType) : null;
    final available = allowedType == null
        ? _categories
        : _categories.where((c) => c.type == allowedType).toList();

    final result = await showCategoryPickerSheet(
      context,
      categories: available,
      highlightId: classification.suggestedCategoryId,
      title: 'Escolha a categoria correta',
      subtitle: allowedType != null
          ? 'Apenas categorias de ${allowedType.label.toLowerCase()} são compatíveis com esta transação.'
          : null,
      // Não faz sentido escolher "Sem categoria" ao corrigir uma classificação:
      // o objetivo é exatamente atribuir uma. A IA aprende com a correção.
      allowNoCategory: false,
    );
    if (result?.category != null) {
      HapticFeedback.mediumImpact();
      _confirmClassification(classification, result!.category!.id);
    }
  }

  // ─── Recommendations actions ───

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
    } catch (_) {}
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
        _showSnack('Recomendação marcada como seguida', isError: false);
      }
    } catch (_) {
      _showSnack('Erro ao atualizar recomendação');
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    final tc = ThemeColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? tc.neoNegative : tc.neoPositive,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _fmtCurrency(double v) {
    final f = v.abs().toStringAsFixed(2).replaceAll('.', ',');
    final p = f.split(',');
    final i = p[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $i,${p[1]}';
  }

  String _monthLabel(DateTime d) {
    return toBeginningOfSentenceCase(DateFormat('MMMM', 'pt_BR').format(d)) ??
        '';
  }

  // ═══════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: tc.neoBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(tc),
            const SizedBox(height: 4),
            AppPillTabs(
              labels: const ['Padrões', 'Previsões', 'Classif.', 'Invest.'],
              selectedIndex: _selectedTab,
              onChanged: (i) => setState(() => _selectedTab = i),
              badges: [
                _patterns.length,
                _predictions.length,
                _pendingClassifications.length,
                _recommendations.length,
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAllData,
                color: tc.neoTeal,
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    _buildPatternsTab(tc),
                    _buildPredictionsTab(tc),
                    _buildClassificationsTab(tc),
                    _buildRecommendationsTab(tc),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SquareIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
              const Spacer(),
              _PillBadgeButton(
                icon: Icons.auto_awesome_rounded,
                tone: 'ai',
                count: _pendingClassifications.length,
                onTap: () => setState(() => _selectedTab = 2),
              ),
              const SizedBox(width: 8),
              _SquareIconButton(
                icon: _isAnalyzing
                    ? Icons.hourglass_top_rounded
                    : Icons.refresh_rounded,
                onTap: _isAnalyzing ? () {} : _triggerAndRefresh,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'AI Insights',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: tc.neoText,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tc.neoText,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'v1.2',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: tc.neoBackground,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Inteligência artificial aplicada às suas finanças',
            style: TextStyle(
              fontSize: 13.5,
              color: tc.neoTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab: Padrões ───

  Widget _buildPatternsTab(ThemeColors tc) {
    if (_isLoadingPatterns) return _buildTabLoading(tc);
    if (_patternsError != null) {
      return _buildTabError(tc, _patternsError!, _loadPatterns);
    }
    if (_patterns.isEmpty) {
      return _buildTabEmpty(
        tc,
        icon: Icons.insights_rounded,
        title: 'Nenhum padrão detectado',
        subtitle: 'A IA precisa de mais transações para identificar padrões.',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        _patternsSummary(tc),
        const SizedBox(height: 12),
        for (final p in _patterns) ...[
          _PatternCard(pattern: p),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _patternsSummary(ThemeColors tc) {
    return Material(
      color: tc.neoCard,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            IconBadge(
              icon: Icons.auto_awesome_rounded,
              tone: 'ai',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_patterns.length} ${_patterns.length == 1 ? 'padrão detectado' : 'padrões detectados'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tc.neoText,
                    ),
                  ),
                  if (_patterns.first.detectedAt != null)
                    Text(
                      'Última análise: ${DateFormat('dd/MM HH:mm', 'pt_BR').format(_patterns.first.detectedAt!)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: tc.neoTextMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (_patterns.first.modelVersion != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tc.badge('neutral').bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _patterns.first.modelVersion!,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: tc.neoTextMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Tab: Previsões ───

  Widget _buildPredictionsTab(ThemeColors tc) {
    if (_isLoadingPredictions) return _buildTabLoading(tc);
    if (_predictionsError != null) {
      return _buildTabError(tc, _predictionsError!, _loadPredictions);
    }
    if (_predictions.isEmpty) {
      return _buildTabEmpty(
        tc,
        icon: Icons.auto_graph_rounded,
        title: 'Nenhuma previsão',
        subtitle: 'A IA gera previsões com base no seu histórico.',
      );
    }

    final totalPredicted =
        _predictions.fold<double>(0, (s, p) => s + p.predictedAmount);
    final totalInterval = _predictions.fold<double>(
      0,
      (s, p) => s +
          ((p.confidenceUpper ?? p.predictedAmount) -
                  (p.confidenceLower ?? p.predictedAmount))
              .abs() /
              2,
    );
    final avgAccuracy = _avgAccuracy();
    final firstDate = _predictions.first.predictionDate;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        HeroGradientCard(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PREVISÃO ${_monthLabel(firstDate).toUpperCase()}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmtCurrency(totalPredicted),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '± ${_fmtCurrency(totalInterval)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 14, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Text(
                    'Acurácia média: ${avgAccuracy != null ? '${avgAccuracy.toStringAsFixed(0)}%' : '—'} · 90% intervalo confiança',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final p in _predictions) ...[
          _PredictionCard(prediction: p),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  double? _avgAccuracy() {
    final withAcc = _predictions
        .map((p) => p.accuracyPercent)
        .where((a) => a != null)
        .cast<double>()
        .toList();
    if (withAcc.isEmpty) return null;
    return withAcc.reduce((a, b) => a + b) / withAcc.length;
  }

  // ─── Tab: Classificações ───

  Widget _buildClassificationsTab(ThemeColors tc) {
    if (_isLoadingClassifications) return _buildTabLoading(tc);
    if (_classificationsError != null) {
      return _buildTabError(tc, _classificationsError!, _loadClassifications);
    }
    if (_pendingClassifications.isEmpty) {
      return _buildTabEmpty(
        tc,
        icon: Icons.check_circle_rounded,
        title: 'Tudo em dia!',
        subtitle: 'Nenhuma transação aguardando confirmação.',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Material(
          color: tc.badge('ai').bg,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: [
                IconBadge(
                  icon: Icons.auto_awesome_rounded,
                  tone: 'ai',
                  background: Colors.white.withValues(
                    alpha: tc.isDark ? 0.06 : 0.6,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_pendingClassifications.length} ${_pendingClassifications.length == 1 ? 'transação aguardando' : 'transações aguardando'} confirmação',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: tc.neoText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Confirme ou corrija — a IA aprende com cada correção.',
                        style: TextStyle(
                          fontSize: 12,
                          color: tc.neoTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final c in _pendingClassifications) ...[
          _ClassificationCard(
            classification: c,
            confirming: _confirmingIds.contains(c.id),
            onConfirm: c.suggestedCategoryId != null
                ? () => _confirmClassification(c, c.suggestedCategoryId!)
                : null,
            onCorrect: () => _showCategorySelectorSheet(c),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  // ─── Tab: Investimentos ───

  Widget _buildRecommendationsTab(ThemeColors tc) {
    if (_isLoadingRecommendations) return _buildTabLoading(tc);
    if (_recommendationsError != null) {
      return _buildTabError(tc, _recommendationsError!, _loadRecommendations);
    }
    if (_recommendations.isEmpty) {
      return _buildTabEmpty(
        tc,
        icon: Icons.trending_up_rounded,
        title: 'Nenhuma recomendação ainda',
        subtitle:
            'A IA gera sugestões com base no seu perfil e saldo disponível.',
      );
    }

    final dominantRisk = _dominantRiskLevel();
    final dominantType = _dominantRecommendationType();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        _RiskProfileCard(
          recommendationType: dominantType,
          riskScore: dominantRisk,
        ),
        const SizedBox(height: 14),
        for (final r in _recommendations) ...[
          _RecommendationCard(
            recommendation: r,
            onKnowMore: () {
              if (!r.wasViewed) _markRecommendationViewed(r);
            },
            onMarkAsFollowed: () => _markRecommendationFollowed(r),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  double? _dominantRiskLevel() {
    final withRisk = _recommendations
        .map((r) => r.riskLevel)
        .where((r) => r != null)
        .cast<double>()
        .toList();
    if (withRisk.isEmpty) return null;
    return withRisk.reduce((a, b) => a + b) / withRisk.length;
  }

  String _dominantRecommendationType() {
    final counts = <String, int>{};
    for (final r in _recommendations) {
      counts[r.recommendationType] = (counts[r.recommendationType] ?? 0) + 1;
    }
    if (counts.isEmpty) return 'MODERATE';
    return counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  // ─── Tab states ───

  Widget _buildTabLoading(ThemeColors tc) {
    return Center(child: CircularProgressIndicator(color: tc.neoTeal));
  }

  Widget _buildTabError(
      ThemeColors tc, String message, Future<void> Function() onRetry) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconBadge(
                    icon: Icons.error_outline_rounded,
                    tone: 'danger',
                    size: 56,
                    iconSize: 26,
                    radius: 16,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: tc.neoTextMuted),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => onRetry(),
                    style: TextButton.styleFrom(foregroundColor: tc.neoTeal),
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

  Widget _buildTabEmpty(
    ThemeColors tc, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconBadge(
                    icon: icon,
                    tone: 'neutral',
                    size: 64,
                    iconSize: 28,
                    radius: 18,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: tc.neoTextMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: tc.neoTextFaint),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
//  Pequenos widgets reutilizáveis
// ═══════════════════════════════════════════════

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Material(
      color: tc.neoCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tc.neoCardBorder),
          ),
          child: Icon(icon, size: 16, color: tc.neoText),
        ),
      ),
    );
  }
}

class _PillBadgeButton extends StatelessWidget {
  final IconData icon;
  final String tone;
  final int count;
  final VoidCallback onTap;

  const _PillBadgeButton({
    required this.icon,
    required this.tone,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final pair = tc.badge(tone);
    return Material(
      color: pair.bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: pair.fg, size: 16),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: pair.fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pattern card ───

class _PatternCard extends StatelessWidget {
  final SpendingPatternEntity pattern;
  const _PatternCard({required this.pattern});

  ({String label, String labelEn, Color color, IconData icon, String tone})
      _config(String type, ThemeColors tc) {
    switch (type) {
      case 'INCREASING':
        return (
          label: 'CRESCENTE',
          labelEn: 'INCREASING',
          color: tc.neoNegative,
          icon: Icons.trending_up_rounded,
          tone: 'danger',
        );
      case 'DECREASING':
        return (
          label: 'EM QUEDA',
          labelEn: 'DECREASING',
          color: tc.neoPositive,
          icon: Icons.trending_down_rounded,
          tone: 'success',
        );
      case 'RECURRING':
        return (
          label: 'RECORRENTE',
          labelEn: 'RECURRING',
          color: const Color(0xFF3D77D6),
          icon: Icons.repeat_rounded,
          tone: 'info',
        );
      case 'ANOMALY':
        return (
          label: 'ANOMALIA',
          labelEn: 'ANOMALY',
          color: tc.neoAttention,
          icon: Icons.warning_amber_rounded,
          tone: 'warning',
        );
      case 'SEASONAL':
        return (
          label: 'SAZONAL',
          labelEn: 'SEASONAL',
          color: tc.neoAi,
          icon: Icons.wb_sunny_rounded,
          tone: 'ai',
        );
      default:
        return (
          label: type,
          labelEn: type,
          color: tc.neoTextMuted,
          icon: Icons.insights_rounded,
          tone: 'neutral',
        );
    }
  }

  String _periodLabel() {
    if (pattern.detectedFrom == null && pattern.detectedTo == null) return '';
    final fmt = DateFormat('dd MMM', 'pt_BR');
    if (pattern.detectedFrom != null && pattern.detectedTo != null) {
      return '${fmt.format(pattern.detectedFrom!)} – ${fmt.format(pattern.detectedTo!)}';
    }
    final d = pattern.detectedFrom ?? pattern.detectedTo!;
    return fmt.format(d);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final cfg = _config(pattern.patternType, tc);
    final score = pattern.significanceScore.clamp(0.0, 1.0);
    final percent = (score * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: tc.neoCard,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: cfg.icon, tone: cfg.tone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cfg.label} · ${cfg.labelEn}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: cfg.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pattern.description,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tc.neoText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Significância',
                style: TextStyle(
                  fontSize: 11,
                  color: tc.neoTextMuted,
                ),
              ),
              const Spacer(),
              Text(
                _periodLabel(),
                style: TextStyle(
                  fontSize: 11,
                  color: tc.neoTextFaint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: score,
                  minHeight: 5,
                  backgroundColor: cfg.color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(cfg.color),
                ),
              ),
              Positioned(
                right: 0,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 0),
                  child: Text(
                    '$percent',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cfg.color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Prediction card ───

class _PredictionCard extends StatelessWidget {
  final SpendingPredictionEntity prediction;
  const _PredictionCard({required this.prediction});

  Color _accuracyColor(double? acc, ThemeColors tc) {
    if (acc == null) return tc.neoTextMuted;
    if (acc >= 85) return tc.neoPositive;
    if (acc >= 70) return tc.neoAttention;
    return tc.neoNegative;
  }

  String _fmtAmount(double v) {
    final f = v.toStringAsFixed(2).replaceAll('.', ',');
    final p = f.split(',');
    final i = p[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $i,${p[1]}';
  }

  String _toneFromName(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('aliment')) return 'food';
    if (n.contains('transp')) return 'transport';
    if (n.contains('lazer')) return 'entertainment';
    if (n.contains('compras')) return 'shopping';
    if (n.contains('saúde') || n.contains('saude')) return 'health';
    if (n.contains('contas') || n.contains('aluguel')) return 'bills';
    return 'neutral';
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final acc = prediction.accuracyPercent;
    final accColor = _accuracyColor(acc, tc);
    final lower = prediction.confidenceLower ?? prediction.predictedAmount;
    final upper = prediction.confidenceUpper ?? prediction.predictedAmount;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: tc.neoCard,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: Icons.label_rounded,
                tone: _toneFromName(prediction.categoryName),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prediction.categoryName ?? 'Sem categoria',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tc.neoText,
                  ),
                ),
              ),
              if (acc != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${acc.toStringAsFixed(0)}% acc',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: 0.55,
                  minHeight: 6,
                  backgroundColor: tc.neoTeal.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(tc.neoTeal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _fmtAmount(lower),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tc.neoTextMuted,
                ),
              ),
              const Spacer(),
              Text(
                '${_fmtAmount(prediction.predictedAmount)} prev.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tc.neoTeal,
                ),
              ),
              const Spacer(),
              Text(
                _fmtAmount(upper),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tc.neoTextMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Classification card ───

class _ClassificationCard extends StatelessWidget {
  final AIClassificationEntity classification;
  final bool confirming;
  final VoidCallback? onConfirm;
  final VoidCallback onCorrect;

  const _ClassificationCard({
    required this.classification,
    required this.confirming,
    required this.onConfirm,
    required this.onCorrect,
  });

  String _toneFromName(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('aliment')) return 'food';
    if (n.contains('transp')) return 'transport';
    if (n.contains('lazer')) return 'entertainment';
    if (n.contains('compras')) return 'shopping';
    if (n.contains('saúde') || n.contains('saude')) return 'health';
    if (n.contains('contas') || n.contains('aluguel')) return 'bills';
    if (n.contains('transfer')) return 'transfer';
    if (n.contains('salár') || n.contains('salario')) return 'salary';
    return 'neutral';
  }

  IconData _iconFromName(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('aliment')) return Icons.restaurant_rounded;
    if (n.contains('transp') || n.contains('uber')) {
      return Icons.directions_car_rounded;
    }
    if (n.contains('lazer')) return Icons.sports_esports_rounded;
    if (n.contains('compras') || n.contains('shopping')) {
      return Icons.shopping_cart_rounded;
    }
    if (n.contains('saúde') || n.contains('saude')) {
      return Icons.medical_services_rounded;
    }
    if (n.contains('transfer')) return Icons.swap_horiz_rounded;
    return Icons.label_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final confidence = (classification.confidenceScore * 100).round();
    final confidenceColor = confidence >= 90
        ? tc.neoPositive
        : confidence >= 70
            ? tc.neoAttention
            : tc.neoNegative;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: tc.neoCard,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: tx description + suggested category
          Row(
            children: [
              IconBadge(
                icon: Icons.receipt_long_rounded,
                tone: 'neutral',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classification.originalText ??
                          'Transação sem descrição',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: tc.neoText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (classification.classifiedAt != null)
                      Text(
                        DateFormat('dd/MM · HH:mm', 'pt_BR')
                            .format(classification.classifiedAt!),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: tc.neoTextMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: tc.badge('ai').bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconBadge(
                  icon:
                      _iconFromName(classification.suggestedCategoryName),
                  tone: _toneFromName(
                      classification.suggestedCategoryName),
                  size: 34,
                  iconSize: 16,
                  radius: 10,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUGESTÃO DA IA',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: tc.neoAi,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        classification.suggestedCategoryName ?? '—',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: tc.neoText,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$confidence%',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: confidenceColor,
                      ),
                    ),
                    Text(
                      'CONFIANÇA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: tc.neoTextFaint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: confirming ? null : onCorrect,
                  icon: Icon(Icons.edit_outlined,
                      size: 16, color: tc.neoText),
                  label: Text(
                    'Corrigir',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tc.neoText,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: tc.neoCardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(0, 42),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: confirming ? null : onConfirm,
                  icon: confirming
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white),
                  label: Text(
                    confirming ? 'Salvando...' : 'Confirmar',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tc.neoTeal,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Investment cards ───

class _RiskProfileCard extends StatelessWidget {
  final String recommendationType;
  final double? riskScore;
  const _RiskProfileCard({
    required this.recommendationType,
    required this.riskScore,
  });

  String _profileLabel() {
    switch (recommendationType.toUpperCase()) {
      case 'CONSERVATIVE':
        return 'Conservador';
      case 'MODERATE':
        return 'Moderado';
      case 'AGGRESSIVE':
        return 'Arrojado';
      default:
        return 'Personalizado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final score = (riskScore ?? 3.0).clamp(0.0, 10.0);
    final dots = score.round();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: tc.neoCard,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SEU PERFIL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: tc.neoTextFaint,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tc.neoAttention.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'RISCO ${score.toStringAsFixed(0)}/10',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: tc.neoAttention,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _profileLabel(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: tc.neoText,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(10, (i) {
              final filled = i < dots;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 9 ? 4 : 0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: filled
                          ? tc.neoAttention
                          : tc.neoTextFaint.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final InvestmentRecommendationEntity recommendation;
  final VoidCallback onKnowMore;
  final VoidCallback onMarkAsFollowed;

  const _RecommendationCard({
    required this.recommendation,
    required this.onKnowMore,
    required this.onMarkAsFollowed,
  });

  ({String label, Color color}) _typeConfig(String type, ThemeColors tc) {
    switch (type.toUpperCase()) {
      case 'CONSERVATIVE':
        return (label: 'CONSERVADOR', color: tc.neoPositive);
      case 'MODERATE':
        return (label: 'MODERADO', color: tc.neoAi);
      case 'AGGRESSIVE':
        return (label: 'ARROJADO', color: tc.neoNegative);
      default:
        return (label: 'PERSONALIZADO', color: tc.neoTeal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final cfg = _typeConfig(recommendation.recommendationType, tc);
    final risk = (recommendation.riskLevel ?? 0).clamp(0.0, 10.0);
    final ret = recommendation.potentialReturn;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: tc.neoCard,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cfg.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cfg.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: cfg.color,
                  ),
                ),
              ),
              if (recommendation.allocationSuggestion != null) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    recommendation.allocationSuggestion!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: tc.neoTextMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (!recommendation.wasViewed)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: tc.neoAi,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: tc.neoText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            recommendation.description,
            style: TextStyle(
              fontSize: 13,
              color: tc.neoTextMuted,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RETORNO POTENCIAL',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: tc.neoTextFaint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ret != null
                          ? '+${ret.toStringAsFixed(1)}% a.a.'
                          : '—',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: tc.neoPositive,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RISCO',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: tc.neoTextFaint,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: risk / 10.0,
                              minHeight: 5,
                              backgroundColor: tc.neoTextFaint
                                  .withValues(alpha: 0.18),
                              valueColor:
                                  AlwaysStoppedAnimation(tc.neoAttention),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          risk.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: tc.neoText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onKnowMore,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: tc.neoCardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(0, 42),
                  ),
                  child: Text(
                    'Saber mais',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tc.neoText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: recommendation.wasFollowed == true
                      ? null
                      : onMarkAsFollowed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tc.neoTeal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(
                    recommendation.wasFollowed == true
                        ? 'Seguindo ✓'
                        : 'Marcar como seguida',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
