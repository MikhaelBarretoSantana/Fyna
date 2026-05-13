import 'package:fyna/feature/ai_classification/domain/entities/ai_classification_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/spending_pattern_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/spending_prediction_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/investment_recommendation_entity.dart';

/// Contrato do repositório de AI Insights.
abstract class AIInsightsRepository {
  /// Dispara análise completa (patterns + predictions + recommendations).
  Future<void> triggerAnalysis();

  /// Verifica se o motor de IA está rodando.
  Future<bool> isAIHealthy();

  /// Padrões de gasto ativos.
  Future<List<SpendingPatternEntity>> getActivePatterns({String? type});

  /// Previsões de gasto.
  Future<List<SpendingPredictionEntity>> getPredictions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  });

  /// Classificações pendentes de confirmação.
  Future<List<AIClassificationEntity>> getPendingClassifications();

  /// Confirma ou corrige uma classificação.
  Future<AIClassificationEntity> confirmClassification(
    String id,
    String confirmedCategoryId,
  );

  /// Recomendações de investimento (paginadas).
  Future<List<InvestmentRecommendationEntity>> getRecommendations({
    int page = 0,
    int size = 10,
  });

  /// Recomendações não visualizadas.
  Future<List<InvestmentRecommendationEntity>> getUnviewedRecommendations();

  /// Marca recomendação como visualizada.
  Future<InvestmentRecommendationEntity> markAsViewed(String id);

  /// Marca recomendação como seguida.
  Future<InvestmentRecommendationEntity> markAsFollowed(String id);
}