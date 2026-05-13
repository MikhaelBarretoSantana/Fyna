/// Entidade de previsão de gasto — espelha `SpendingPredictionResponse` do backend.
class SpendingPredictionEntity {
  final String id;
  final String? categoryId;
  final String? categoryName;
  final DateTime predictionDate;
  final double predictedAmount;
  final double? actualAmount;
  final double? confidenceLower;
  final double? confidenceUpper;
  final String? modelVersion;
  final DateTime? generatedAt;

  const SpendingPredictionEntity({
    required this.id,
    this.categoryId,
    this.categoryName,
    required this.predictionDate,
    required this.predictedAmount,
    this.actualAmount,
    this.confidenceLower,
    this.confidenceUpper,
    this.modelVersion,
    this.generatedAt,
  });

  /// Percentual de acurácia se houver valor real.
  double? get accuracyPercent {
    if (actualAmount == null || predictedAmount == 0) return null;
    final diff = (actualAmount! - predictedAmount).abs();
    return ((1 - (diff / predictedAmount)) * 100).clamp(0, 100);
  }

  factory SpendingPredictionEntity.fromJson(Map<String, dynamic> json) {
    return SpendingPredictionEntity(
      id: json['id'].toString(),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName'] as String?,
      predictionDate: json['predictionDate'] != null
          ? DateTime.parse(json['predictionDate'] as String)
          : DateTime.now(),
      predictedAmount:
          (json['predictedAmount'] as num?)?.toDouble() ?? 0.0,
      actualAmount: (json['actualAmount'] as num?)?.toDouble(),
      confidenceLower: (json['confidenceLower'] as num?)?.toDouble(),
      confidenceUpper: (json['confidenceUpper'] as num?)?.toDouble(),
      modelVersion: json['modelVersion'] as String?,
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : null,
    );
  }
}