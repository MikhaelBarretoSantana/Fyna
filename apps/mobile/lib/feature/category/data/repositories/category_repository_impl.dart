import 'package:fyna/feature/category/data/datasource/category_remote_datasource.dart';
import 'package:fyna/feature/category/domain/entities/category_entity.dart';
import 'package:fyna/feature/category/domain/repositories/category_repository.dart';

/// Implementação concreta do [CategoryRepository].
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDatasource _datasource;

  CategoryRepositoryImpl({required CategoryRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<List<CategoryEntity>> getCategories({String? type}) {
    return _datasource.getCategories(type: type);
  }

  @override
  Future<List<CategoryEntity>> getSystemCategories() {
    return _datasource.getSystemCategories();
  }

  @override
  Future<CategoryEntity> getCategory(String id) {
    return _datasource.getCategory(id);
  }

  @override
  Future<CategoryEntity> createCategory({
    required String name,
    required String type,
    String? parentId,
    String? icon,
    String? color,
    int? displayOrder,
  }) {
    final body = <String, dynamic>{
      'name': name,
      'type': type,
      if (parentId != null) 'parentId': parentId,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (displayOrder != null) 'displayOrder': displayOrder,
    };
    return _datasource.createCategory(body);
  }

  @override
  Future<CategoryEntity> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
    int? displayOrder,
    bool? isActive,
  }) {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (displayOrder != null) 'displayOrder': displayOrder,
      if (isActive != null) 'isActive': isActive,
    };
    return _datasource.updateCategory(id, body);
  }

  @override
  Future<void> deleteCategory(String id) {
    return _datasource.deleteCategory(id);
  }
}
