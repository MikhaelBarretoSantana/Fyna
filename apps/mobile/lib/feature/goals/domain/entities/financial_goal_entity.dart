import 'package:fyna/core/enums/goal_priority.dart';
import 'package:fyna/core/enums/goal_status.dart';

class FinancialGoalEntity {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final double targetAmount;
  final double currentAmount;
  final double progressPercent;
  final DateTime? targetDate;
  final GoalStatus status;
  final GoalPriority? priority;
  final DateTime? completedAt;
  final DateTime createdAt;

  const FinancialGoalEntity({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.targetAmount,
    required this.currentAmount,
    required this.progressPercent,
    this.targetDate,
    required this.status,
    this.priority,
    this.completedAt,
    required this.createdAt,
  });

  factory FinancialGoalEntity.fromJson(Map<String, dynamic> json) {
    return FinancialGoalEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      progressPercent: (json['progressPercent'] as num).toDouble(),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      status: GoalStatus.fromJson(json['status'] as String),
      priority: json['priority'] != null
          ? GoalPriority.fromJson(json['priority'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'progressPercent': progressPercent,
        'targetDate': targetDate?.toIso8601String().split('T').first,
        'status': status.toJson(),
        'priority': priority?.toJson(),
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  FinancialGoalEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    double? targetAmount,
    double? currentAmount,
    double? progressPercent,
    DateTime? targetDate,
    GoalStatus? status,
    GoalPriority? priority,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return FinancialGoalEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      progressPercent: progressPercent ?? this.progressPercent,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
