import 'package:fyna/feature/category/domain/entities/category_entity.dart';

/// Contrato do repositório de categorias.
abstract class CategoryRepository {
  /// Lista todas as categorias do usuário (inclui as de sistema).
  Future<List<CategoryEntity>> getCategories({String? type});

  /// Lista apenas categorias de sistema.
  Future<List<CategoryEntity>> getSystemCategories();

  /// Busca uma categoria pelo ID.
  Future<CategoryEntity> getCategory(String id);

  /// Cria uma nova categoria customizada.
  Future<CategoryEntity> createCategory({
    required String name,
    required String type,
    String? parentId,
    String? icon,
    String? color,
    int? displayOrder,
  });

  /// Atualiza uma categoria existente.
  Future<CategoryEntity> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
    int? displayOrder,
    bool? isActive,
  });

  /// Exclui uma categoria.
  Future<void> deleteCategory(String id);
}
