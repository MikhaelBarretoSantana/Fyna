import 'package:fyna/feature/ai_classification/data/datasource/ai_insights_remote_datasource.dart';
import 'package:fyna/feature/ai_classification/domain/entities/ai_classification_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/spending_pattern_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/spending_prediction_entity.dart';
import 'package:fyna/feature/ai_classification/domain/entities/investment_recommendation_entity.dart';
import 'package:fyna/feature/ai_classification/domain/repositories/ai_insights_repository.dart';

/// Implementação concreta do [AIInsightsRepository].
class AIInsightsRepositoryImpl implements AIInsightsRepository {
  final AIInsightsRemoteDatasource _datasource;

  AIInsightsRepositoryImpl({required AIInsightsRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<void> triggerAnalysis() {
    return _datasource.triggerAnalysis();
  }

  @override
  Future<bool> isAIHealthy() {
    return _datasource.isAIHealthy();
  }

  @override
  Future<List<SpendingPatternEntity>> getActivePatterns({String? type}) {
    return _datasource.getActivePatterns(type: type);
  }

  @override
  Future<List<SpendingPredictionEntity>> getPredictions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) {
    return _datasource.getPredictions(
      startDate: startDate != null ? _formatDate(startDate) : null,
      endDate: endDate != null ? _formatDate(endDate) : null,
      categoryId: categoryId,
    );
  }

  @override
  Future<List<AIClassificationEntity>> getPendingClassifications() {
    return _datasource.getPendingClassifications();
  }

  @override
  Future<AIClassificationEntity> confirmClassification(
    String id,
    String confirmedCategoryId,
  ) {
    return _datasource.confirmClassification(id, confirmedCategoryId);
  }

  @override
  Future<List<InvestmentRecommendationEntity>> getRecommendations({
    int page = 0,
    int size = 10,
  }) {
    return _datasource.getRecommendations(page: page, size: size);
  }

  @override
  Future<List<InvestmentRecommendationEntity>> getUnviewedRecommendations() {
    return _datasource.getUnviewedRecommendations();
  }

  @override
  Future<InvestmentRecommendationEntity> markAsViewed(String id) {
    return _datasource.markAsViewed(id);
  }

  @override
  Future<InvestmentRecommendationEntity> markAsFollowed(String id) {
    return _datasource.markAsFollowed(id);
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}