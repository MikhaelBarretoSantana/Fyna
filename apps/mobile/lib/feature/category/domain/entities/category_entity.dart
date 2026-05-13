import 'package:fyna/core/enums/category_type.dart';

/// Entidade de domínio de categoria — espelha `CategoryResponse` do backend.
class CategoryEntity {
  final String id;
  final String? parentId;
  final String name;
  final String? icon;
  final String? color;
  final CategoryType type;
  final bool isSystem;
  final bool isActive;
  final int displayOrder;

  const CategoryEntity({
    required this.id,
    this.parentId,
    required this.name,
    this.icon,
    this.color,
    required this.type,
    required this.isSystem,
    required this.isActive,
    required this.displayOrder,
  });

  factory CategoryEntity.fromJson(Map<String, dynamic> json) {
    return CategoryEntity(
      id: json['id'].toString(),
      parentId: json['parentId']?.toString(),
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      type: CategoryType.fromJson(json['type'] as String? ?? 'EXPENSE'),
      isSystem: json['isSystem'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type.toJson(),
      'isSystem': isSystem,
      'isActive': isActive,
      'displayOrder': displayOrder,
    };
  }
}
