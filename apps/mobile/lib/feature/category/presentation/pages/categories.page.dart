import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/enums/category_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/category/domain/entities/category_entity.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  late TabController _tabController;

  // ─── Dados da API ───
  List<CategoryEntity> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ─── Cores disponíveis para criar/editar ───
  static const List<Map<String, dynamic>> _colorOptions = [
    {'hex': '#1A7B8C', 'color': Color(0xFF1A7B8C)},
    {'hex': '#0D4F6E', 'color': Color(0xFF0D4F6E)},
    {'hex': '#2BA3A8', 'color': Color(0xFF2BA3A8)},
    {'hex': '#00D4AA', 'color': Color(0xFF00D4AA)},
    {'hex': '#FF6B6B', 'color': Color(0xFFFF6B6B)},
    {'hex': '#FFB300', 'color': Color(0xFFFFB300)},
    {'hex': '#7C83FD', 'color': Color(0xFF7C83FD)},
    {'hex': '#FF9800', 'color': Color(0xFFFF9800)},
    {'hex': '#E91E63', 'color': Color(0xFFE91E63)},
    {'hex': '#4CAF50', 'color': Color(0xFF4CAF50)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Carregamento ───
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories =
          await Injection.instance.categoryRepository.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } on NetworkException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sem conexão com a internet';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar categorias';
          _isLoading = false;
        });
      }
    }
  }

  // ─── Filtro por tipo ───
  List<CategoryEntity> _filteredByType(CategoryType type) {
    final list = _categories.where((c) => c.type == type).toList();
    // Sistema primeiro, depois customizadas, ordenadas por displayOrder
    list.sort((a, b) {
      if (a.isSystem && !b.isSystem) return -1;
      if (!a.isSystem && b.isSystem) return 1;
      return a.displayOrder.compareTo(b.displayOrder);
    });
    return list;
  }

  CategoryType get _currentType {
    switch (_tabController.index) {
      case 1:
        return CategoryType.income;
      case 2:
        return CategoryType.transfer;
      default:
        return CategoryType.expense;
    }
  }

  // ─── Ações ───
  Future<void> _createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    try {
      final created =
          await Injection.instance.categoryRepository.createCategory(
        name: name,
        type: type,
        icon: icon,
        color: color,
      );
      if (mounted) {
        setState(() => _categories.add(created));
        _showSnackBar('Categoria "$name" criada', isError: false);
      }
    } on ServerException catch (e) {
      _showSnackBar(e.message);
    } on NetworkException {
      _showSnackBar('Sem conexão com a internet');
    } catch (_) {
      _showSnackBar('Erro ao criar categoria');
    }
  }

  Future<void> _updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    try {
      final updated =
          await Injection.instance.categoryRepository.updateCategory(
        id: id,
        name: name,
        icon: icon,
        color: color,
      );
      if (mounted) {
        setState(() {
          final idx = _categories.indexWhere((c) => c.id == id);
          if (idx != -1) _categories[idx] = updated;
        });
        _showSnackBar('Categoria atualizada', isError: false);
      }
    } on ServerException catch (e) {
      _showSnackBar(e.message);
    } catch (_) {
      _showSnackBar('Erro ao atualizar categoria');
    }
  }

  Future<void> _deleteCategory(CategoryEntity category) async {
    final confirmed = await _showDeleteConfirmation(category);
    if (confirmed != true) return;

    try {
      await Injection.instance.categoryRepository.deleteCategory(category.id);
      if (mounted) {
        setState(() => _categories.removeWhere((c) => c.id == category.id));
        _showSnackBar('Categoria "${category.name}" excluída', isError: false);
      }
    } on ServerException catch (e) {
      _showSnackBar(e.message);
    } on NetworkException {
      _showSnackBar('Sem conexão com a internet');
    } catch (_) {
      _showSnackBar('Erro ao excluir categoria');
    }
  }

  Future<bool?> _showDeleteConfirmation(CategoryEntity category) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: AppColors.error, size: 28),
        ),
        title: Text(
          'Excluir categoria?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'A categoria "${category.name}" será desativada. '
          'Transações vinculadas não serão afetadas.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white60 : AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                )),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Excluir',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  BOTTOM SHEETS
  // ═══════════════════════════════════════════════

  void _showCreateSheet() {
    HapticFeedback.mediumImpact();
    final nameController = TextEditingController();
    String selectedColor = '#1A7B8C';
    String selectedIcon = 'category';
    final type = _currentType;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20,
                    14,
                    20,
                    MediaQuery.of(ctx).padding.bottom > 0 ? 12 : 28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14142A) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nova categoria',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Tipo: ${_typeLabel(type)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Preview
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _parseColor(selectedColor)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getCategoryIcon(selectedIcon),
                          color: _parseColor(selectedColor),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Nome
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nome da categoria',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1C1C2E)
                            : const Color(0xFFF5F5F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cor
                    Text(
                      'Cor',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _colorOptions.map((opt) {
                        final hex = opt['hex'] as String;
                        final color = opt['color'] as Color;
                        final isSelected = selectedColor == hex;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedColor = hex),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2.5)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      )
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Ícone
                    Text(
                      'Ícone',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildIconSelector(
                      selectedIcon: selectedIcon,
                      selectedColor: selectedColor,
                      onChanged: (icon) =>
                          setSheetState(() => selectedIcon = icon),
                    ),
                    const SizedBox(height: 24),
                    // Botão criar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            _showSnackBar('Informe o nome da categoria');
                            return;
                          }
                          Navigator.pop(ctx);
                          _createCategory(
                            name: name,
                            type: type.toJson(),
                            icon: selectedIcon,
                            color: selectedColor,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkAccent
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Criar categoria',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditSheet(CategoryEntity category) {
    HapticFeedback.mediumImpact();
    final nameController = TextEditingController(text: category.name);
    String selectedColor = category.color ?? '#1A7B8C';
    String selectedIcon = category.icon ?? 'category';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20,
                    14,
                    20,
                    MediaQuery.of(ctx).padding.bottom > 0 ? 12 : 28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14142A) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Editar categoria',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _parseColor(selectedColor)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getCategoryIcon(selectedIcon),
                          color: _parseColor(selectedColor),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nome da categoria',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1C1C2E)
                            : const Color(0xFFF5F5F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Cor',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black54,
                        )),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _colorOptions.map((opt) {
                        final hex = opt['hex'] as String;
                        final color = opt['color'] as Color;
                        final isSelected = selectedColor == hex;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedColor = hex),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2.5)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                          color: color.withValues(alpha: 0.4),
                                          blurRadius: 8)
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Ícone',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black54,
                        )),
                    const SizedBox(height: 8),
                    _buildIconSelector(
                      selectedIcon: selectedIcon,
                      selectedColor: selectedColor,
                      onChanged: (icon) =>
                          setSheetState(() => selectedIcon = icon),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            _showSnackBar('Informe o nome da categoria');
                            return;
                          }
                          Navigator.pop(ctx);
                          _updateCategory(
                            id: category.id,
                            name: name,
                            icon: selectedIcon,
                            color: selectedColor,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkAccent
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Salvar',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Ações na categoria (long press) ───
  void _showCategoryActions(CategoryEntity category) {
    if (category.isSystem) return; // Sistema não tem ações
    HapticFeedback.mediumImpact();
    final catColor = _parseColor(category.color);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return Container(
          padding:
              EdgeInsets.fromLTRB(20, 14, 20, bottomPadding > 0 ? 12 : 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14142A) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getCategoryIcon(category.icon),
                        color: catColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildActionTile(
                icon: Icons.edit_rounded,
                label: 'Editar categoria',
                color: isDark ? AppColors.darkAccent : AppColors.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditSheet(category);
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Excluir categoria',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteCategory(category);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.06 : 0.03),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: color.withValues(alpha: isDark ? 0.15 : 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    )),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: isDark ? Colors.white24 : Colors.black26, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F5F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            // Resumo
            if (!_isLoading) _buildSummaryRow(),
            if (!_isLoading) const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 4),
            if (_errorMessage != null && !_isLoading) _buildErrorBanner(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryList(CategoryType.expense),
                  _buildCategoryList(CategoryType.income),
                  _buildCategoryList(CategoryType.transfer),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1C2E)
                    : const Color(0xFFEEEEF2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categorias',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (!_isLoading)
                  Text(
                    '${_categories.length} categorias · ${_categories.where((c) => c.isSystem).length} do sistema',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showCreateSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkAccent : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text('Nova',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Resumo por tipo ───
  Widget _buildSummaryRow() {
    final expense = _categories.where((c) => c.type == CategoryType.expense).length;
    final income = _categories.where((c) => c.type == CategoryType.income).length;
    final transfer = _categories.where((c) => c.type == CategoryType.transfer).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
              child: _buildSummaryChip('Despesas', expense, AppColors.error)),
          const SizedBox(width: 8),
          Expanded(
              child:
                  _buildSummaryChip('Receitas', income, AppColors.success)),
          const SizedBox(width: 8),
          Expanded(
              child:
                  _buildSummaryChip('Transf.', transfer, AppColors.info)),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14142A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab bar ───
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : const Color(0xFFEEEEF2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? AppColors.darkAccent : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white38 : Colors.black45,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        padding: const EdgeInsets.all(3),
        tabs: const [
          Tab(text: 'Despesas', height: 38),
          Tab(text: 'Receitas', height: 38),
          Tab(text: 'Transf.', height: 38),
        ],
      ),
    );
  }

  // ─── Error ───
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                )),
          ),
          GestureDetector(
            onTap: _loadCategories,
            child: const Icon(Icons.refresh_rounded,
                color: AppColors.error, size: 18),
          ),
        ],
      ),
    );
  }

  // ─── Lista de categorias ───
  Widget _buildCategoryList(CategoryType type) {
    if (_isLoading) return _buildListShimmer();

    final filtered = _filteredByType(type);

    if (filtered.isEmpty) return _buildEmptyState(type);

    // Separar sistema e custom
    final system = filtered.where((c) => c.isSystem).toList();
    final custom = filtered.where((c) => !c.isSystem).toList();

    return RefreshIndicator(
      onRefresh: _loadCategories,
      color: isDark ? AppColors.darkAccent : AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          if (custom.isNotEmpty) ...[
            _buildSectionLabel(
                'Minhas categorias', '${custom.length}'),
            const SizedBox(height: 8),
            ...custom.map((c) => _buildCategoryCard(c)),
            const SizedBox(height: 20),
          ],
          if (system.isNotEmpty) ...[
            _buildSectionLabel(
                'Categorias do sistema', '${system.length}'),
            const SizedBox(height: 8),
            ...system.map((c) => _buildCategoryCard(c)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, String count) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            count,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white30 : Colors.black38,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(CategoryEntity category) {
    final color = _parseColor(category.color);

    return GestureDetector(
      onLongPress: () => _showCategoryActions(category),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14142A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEF2),
          ),
        ),
        child: Row(
          children: [
            // Ícone
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(category.icon),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Nome + label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (category.parentId != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Subcategoria',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Badges
            if (category.isSystem)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sistema',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => _showEditSheet(category),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit_rounded,
                      size: 16,
                      color: isDark ? Colors.white24 : Colors.black26),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Shimmer ───
  Widget _buildListShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: List.generate(6, (i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 70,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF14142A)
                  : const Color(0xFFEEEEF2),
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }),
      ),
    );
  }

  // ─── Empty ───
  Widget _buildEmptyState(CategoryType type) {
    final label = _typeLabel(type);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1C2E)
                    : const Color(0xFFEEEEF2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.category_rounded,
                  size: 32,
                  color: isDark ? Colors.white12 : Colors.black12),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma categoria de $label',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Crie categorias customizadas\npara organizar melhor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black26,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _showCreateSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkAccent.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        size: 18,
                        color:
                            isDark ? AppColors.darkAccent : AppColors.primary),
                    const SizedBox(width: 6),
                    Text('Criar categoria',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkAccent
                              : AppColors.primary,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Icon selector grid ───
  Widget _buildIconSelector({
    required String selectedIcon,
    required String selectedColor,
    required ValueChanged<String> onChanged,
  }) {
    const icons = [
      {'key': 'food', 'icon': Icons.restaurant_rounded},
      {'key': 'transport', 'icon': Icons.directions_car_rounded},
      {'key': 'entertainment', 'icon': Icons.movie_rounded},
      {'key': 'health', 'icon': Icons.favorite_rounded},
      {'key': 'shopping', 'icon': Icons.shopping_bag_rounded},
      {'key': 'bills', 'icon': Icons.receipt_rounded},
      {'key': 'education', 'icon': Icons.school_rounded},
      {'key': 'travel', 'icon': Icons.flight_rounded},
      {'key': 'investment', 'icon': Icons.trending_up_rounded},
      {'key': 'salary', 'icon': Icons.account_balance_rounded},
      {'key': 'home', 'icon': Icons.home_rounded},
      {'key': 'pets', 'icon': Icons.pets_rounded},
      {'key': 'gifts', 'icon': Icons.card_giftcard_rounded},
      {'key': 'sports', 'icon': Icons.fitness_center_rounded},
      {'key': 'category', 'icon': Icons.category_rounded},
    ];

    final color = _parseColor(selectedColor);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: icons.map((item) {
        final key = item['key'] as String;
        final icon = item['icon'] as IconData;
        final isSelected = selectedIcon == key;
        return GestureDetector(
          onTap: () => onChanged(key),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: color.withValues(alpha: 0.5), width: 1.5)
                  : null,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected
                  ? color
                  : (isDark ? Colors.white30 : Colors.black38),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Utils ───
  String _typeLabel(CategoryType type) {
    switch (type) {
      case CategoryType.expense:
        return 'despesa';
      case CategoryType.income:
        return 'receita';
      case CategoryType.transfer:
        return 'transferência';
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return AppColors.primary;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return AppColors.primary;
    return Color(0xFF000000 | value);
  }

  IconData _getCategoryIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) return Icons.category_rounded;
    switch (iconName.toLowerCase()) {
      case 'food':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'transport':
      case 'car':
        return Icons.directions_car_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'salary':
        return Icons.account_balance_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'gifts':
        return Icons.card_giftcard_rounded;
      case 'sports':
        return Icons.fitness_center_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}