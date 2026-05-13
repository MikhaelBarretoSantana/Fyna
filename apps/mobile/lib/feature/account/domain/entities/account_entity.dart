import 'package:fyna/core/enums/account_types.dart';

/// Entidade de domínio de conta — espelha `AccountResponse` do backend.
class AccountEntity {
  final String id;
  final String name;
  final AccountTypes type;
  final String? institution;
  final String? color;
  final String? icon;
  final double initialBalance;
  final double currentBalance;
  final bool isActive;
  final bool includeInTotal;

  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    this.institution,
    this.color,
    this.icon,
    required this.initialBalance,
    required this.currentBalance,
    required this.isActive,
    required this.includeInTotal,
  });

  factory AccountEntity.fromJson(Map<String, dynamic> json) {
    return AccountEntity(
      id: json['id'].toString(),
      name: json['name'] as String,
      type: AccountTypes.fromJson(json['type'] as String? ?? 'OTHER'),
      institution: json['institution'] as String?,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      includeInTotal: json['includeInTotal'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toJson(),
      'institution': institution,
      'color': color,
      'icon': icon,
      'initialBalance': initialBalance,
      'currentBalance': currentBalance,
      'isActive': isActive,
      'includeInTotal': includeInTotal,
    };
  }
}
