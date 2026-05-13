/// Entidade de recomendação de investimento — espelha `InvestmentRecommendationResponse`.
class InvestmentRecommendationEntity {
  final String id;
  final String recommendationType; // CONSERVATIVE, MODERATE, AGGRESSIVE, CUSTOM
  final String title;
  final String description;
  final String? allocationSuggestion;
  final double? potentialReturn;
  final double? riskLevel;
  final bool wasViewed;
  final bool? wasFollowed;
  final String? modelVersion;
  final DateTime? generatedAt;
  final DateTime? viewedAt;

  const InvestmentRecommendationEntity({
    required this.id,
    required this.recommendationType,
    required this.title,
    required this.description,
    this.allocationSuggestion,
    this.potentialReturn,
    this.riskLevel,
    required this.wasViewed,
    this.wasFollowed,
    this.modelVersion,
    this.generatedAt,
    this.viewedAt,
  });

  /// Retorna label do tipo de recomendação.
  String get typeLabel {
    switch (recommendationType) {
      case 'CONSERVATIVE':
        return 'Conservador';
      case 'MODERATE':
        return 'Moderado';
      case 'AGGRESSIVE':
        return 'Agressivo';
      case 'CUSTOM':
        return 'Personalizado';
      default:
        return recommendationType;
    }
  }

  factory InvestmentRecommendationEntity.fromJson(Map<String, dynamic> json) {
    return InvestmentRecommendationEntity(
      id: json['id'].toString(),
      recommendationType:
          json['recommendationType'] as String? ?? 'MODERATE',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      allocationSuggestion: json['allocationSuggestion'] as String?,
      potentialReturn: (json['potentialReturn'] as num?)?.toDouble(),
      riskLevel: (json['riskLevel'] as num?)?.toDouble(),
      wasViewed: json['wasViewed'] as bool? ?? false,
      wasFollowed: json['wasFollowed'] as bool?,
      modelVersion: json['modelVersion'] as String?,
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : null,
      viewedAt: json['viewedAt'] != null
          ? DateTime.parse(json['viewedAt'] as String)
          : null,
    );
  }
}