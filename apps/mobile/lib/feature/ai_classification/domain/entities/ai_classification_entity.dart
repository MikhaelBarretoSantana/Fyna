/// Entidade de classificação de IA — espelha `AIClassificationResponse` do backend.
class AIClassificationEntity {
  final String id;
  final String? transactionId;
  final String? suggestedCategoryId;
  final String? suggestedCategoryName;
  final String? confirmedCategoryId;
  final String? confirmedCategoryName;
  final double confidenceScore;
  final String? originalText;
  final String? modelVersion;
  final bool wasConfirmed;
  final bool wasCorrected;
  final DateTime? classifiedAt;
  final DateTime? confirmedAt;

  const AIClassificationEntity({
    required this.id,
    this.transactionId,
    this.suggestedCategoryId,
    this.suggestedCategoryName,
    this.confirmedCategoryId,
    this.confirmedCategoryName,
    required this.confidenceScore,
    this.originalText,
    this.modelVersion,
    required this.wasConfirmed,
    required this.wasCorrected,
    this.classifiedAt,
    this.confirmedAt,
  });

  factory AIClassificationEntity.fromJson(Map<String, dynamic> json) {
    return AIClassificationEntity(
      id: json['id'].toString(),
      transactionId: json['transactionId']?.toString(),
      suggestedCategoryId: json['suggestedCategoryId']?.toString(),
      suggestedCategoryName: json['suggestedCategoryName'] as String?,
      confirmedCategoryId: json['confirmedCategoryId']?.toString(),
      confirmedCategoryName: json['confirmedCategoryName'] as String?,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      originalText: json['originalText'] as String?,
      modelVersion: json['modelVersion'] as String?,
      wasConfirmed: json['wasConfirmed'] as bool? ?? false,
      wasCorrected: json['wasCorrected'] as bool? ?? false,
      classifiedAt: json['classifiedAt'] != null
          ? DateTime.parse(json['classifiedAt'] as String)
          : null,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
    );
  }
}