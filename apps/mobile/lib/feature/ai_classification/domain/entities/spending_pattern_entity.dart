/// Entidade de padrão de gasto — espelha `SpendingPatternResponse` do backend.
class SpendingPatternEntity {
  final String id;
  final String patternType; // SEASONAL, RECURRING, INCREASING, DECREASING, ANOMALY
  final String description;
  final String? patternData;
  final double significanceScore;
  final DateTime? detectedFrom;
  final DateTime? detectedTo;
  final bool isActive;
  final String? modelVersion;
  final DateTime? detectedAt;

  const SpendingPatternEntity({
    required this.id,
    required this.patternType,
    required this.description,
    this.patternData,
    required this.significanceScore,
    this.detectedFrom,
    this.detectedTo,
    required this.isActive,
    this.modelVersion,
    this.detectedAt,
  });

  factory SpendingPatternEntity.fromJson(Map<String, dynamic> json) {
    return SpendingPatternEntity(
      id: json['id'].toString(),
      patternType: json['patternType'] as String? ?? 'ANOMALY',
      description: json['description'] as String? ?? '',
      patternData: json['patternData'] as String?,
      significanceScore:
          (json['significanceScore'] as num?)?.toDouble() ?? 0.0,
      detectedFrom: json['detectedFrom'] != null
          ? DateTime.parse(json['detectedFrom'] as String)
          : null,
      detectedTo: json['detectedTo'] != null
          ? DateTime.parse(json['detectedTo'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      modelVersion: json['modelVersion'] as String?,
      detectedAt: json['detectedAt'] != null
          ? DateTime.parse(json['detectedAt'] as String)
          : null,
    );
  }
}