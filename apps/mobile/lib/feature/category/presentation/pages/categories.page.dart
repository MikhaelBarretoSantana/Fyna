import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/enums/category_type.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_list_item.dart';
import 'package:fyna/core/widgets/app_pill_tabs.dart';
import 'package:fyna/core/widgets/app_screen_header.dart';
import 'package:fyna/core/widgets/hero_gradient_card.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
import 'package:fyna/feature/category/domain/entities/category_entity.dart';
import 'package:fyna/feature/transaction/domain/entities/transaction_entity.dart';
import 'package:intl/intl.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  int _selectedFilter = 0; // 0=Receitas, 1=Despesas, 2=Transferências

  List<CategoryEntity> _categories = [];
  List<TransactionEntity> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const List<String> _colorOptions = [
    '#1A6F82',
    '#0E3D4A',
    '#2BA3A8',
    '#12A892',
    '#E85D4A',
    '#E89A2E',
    '#7C5CFC',
    '#FF9800',
    '#E91E63',
    '#4CAF50',
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        Injection.instance.categoryRepository.getCategories(),
        Injection.instance.transactionRepository.getTransactions(
          page: 0,
          size: 200,
          startDate: DateTime(now.year, now.month, 1),
          endDate: DateTime(now.year, now.month + 1, 0),
        ),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0] as List<CategoryEntity>;
          _transactions =
              (results[1] as dynamic).content as List<TransactionEntity>;
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

  CategoryType get _currentType {
    // Ordem visual da pill: Receita (0), Despesa (1), Transferência (2).
    switch (_selectedFilter) {
      case 0:
        return CategoryType.income;
      case 2:
        return CategoryType.transfer;
      case 1:
      default:
        return CategoryType.expense;
    }
  }

  TransactionType get _matchingTransactionType {
    switch (_currentType) {
      case CategoryType.income:
        return TransactionType.income;
      case CategoryType.transfer:
        return TransactionType.transfer;
      case CategoryType.expense:
        return TransactionType.expense;
    }
  }

  /// Categorias raiz (sem parentId) do tipo selecionado.
  List<CategoryEntity> get _rootCategories {
    final list = _categories
        .where((c) => c.type == _currentType && c.parentId == null)
        .toList();
    list.sort((a, b) {
      if (a.isSystem && !b.isSystem) return -1;
      if (!a.isSystem && b.isSystem) return 1;
      return a.displayOrder.compareTo(b.displayOrder);
    });
    return list;
  }

  int _subCount(String parentId) {
    return _categories.where((c) => c.parentId == parentId).length;
  }

  double _totalForCategory(String categoryId) {
    return _transactions
        .where((t) =>
            t.type == _matchingTransactionType &&
            (t.categoryId == categoryId))
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get _totalSpent {
    return _transactions
        .where((t) => t.type == _matchingTransactionType)
        .fold(0.0, (s, t) => s + t.amount);
  }

  int get _activeCount =>
      _categories.where((c) => c.type == _currentType).length;

  int get _subCountTotal => _categories
      .where((c) => c.type == _currentType && c.parentId != null)
      .length;

  String get _monthLabel {
    return toBeginningOfSentenceCase(
            DateFormat('MMMM', 'pt_BR').format(DateTime.now())) ??
        'Mês';
  }

  String _fmtCurrency(double v) {
    final f = v.abs().toStringAsFixed(2).replaceAll('.', ',');
    final p = f.split(',');
    final i = p[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $i,${p[1]}';
  }

  String _fmtShort(double v) {
    if (v.abs() >= 1000000) {
      return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (v.abs() >= 1000) {
      return 'R\$ ${(v / 1000).toStringAsFixed(1)}K';
    }
    return _fmtCurrency(v);
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    final tc = ThemeColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? tc.neoNegative : tc.neoPositive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteCategory(CategoryEntity category) async {
    final confirmed = await _confirmDelete(category);
    if (confirmed != true) return;
    try {
      await Injection.instance.categoryRepository.deleteCategory(category.id);
      if (mounted) {
        setState(() => _categories.removeWhere((c) => c.id == category.id));
        _showSnackBar('Categoria "${category.name}" excluída', isError: false);
      }
    } on ServerException catch (e) {
      _showSnackBar(e.message);
    } catch (_) {
      _showSnackBar('Erro ao excluir categoria');
    }
  }

  Future<bool?> _confirmDelete(CategoryEntity category) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        return AlertDialog(
          backgroundColor: tc.neoCardElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: IconBadge(
            icon: Icons.delete_outline_rounded,
            tone: 'danger',
            size: 56,
            iconSize: 26,
            radius: 16,
          ),
          title: Text(
            'Excluir categoria?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tc.neoText,
            ),
          ),
          content: Text(
            'A categoria "${category.name}" será desativada. '
            'Transações vinculadas não serão afetadas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: tc.neoTextMuted,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: tc.neoTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: tc.neoNegative,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Excluir',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _showCreateSheet({CategoryEntity? editing}) {
    HapticFeedback.mediumImpact();
    final nameController = TextEditingController(text: editing?.name ?? '');
    String selectedColor = editing?.color ?? _colorOptions.first;
    final typeJson = editing != null ? editing.type.toJson() : _currentType.toJson();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final tc = ThemeColors.of(ctx);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: tc.neoCardElevated,
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
                          color: tc.neoTextFaint.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      editing != null ? 'Editar categoria' : 'Nova categoria',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tc.neoText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nome',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: tc.neoTextFaint,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      autofocus: editing == null,
                      decoration: InputDecoration(
                        hintText: 'Ex.: Mercado',
                        filled: true,
                        fillColor: tc.neoCard,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: tc.neoCardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: tc.neoCardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: tc.neoTeal, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cor',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: tc.neoTextFaint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _colorOptions.map((hex) {
                        final color = _hexToColor(hex);
                        final selected = hex == selectedColor;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedColor = hex),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(12),
                              border: selected
                                  ? Border.all(
                                      color: tc.neoText, width: 2.5)
                                  : null,
                            ),
                            child: selected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            _showSnackBar('Informe um nome');
                            return;
                          }
                          Navigator.pop(ctx);
                          if (editing != null) {
                            await _update(
                              id: editing.id,
                              name: name,
                              color: selectedColor,
                            );
                          } else {
                            await _create(
                              name: name,
                              type: typeJson,
                              color: selectedColor,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tc.neoTeal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(editing != null ? 'Salvar' : 'Criar'),
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

  Future<void> _create({
    required String name,
    required String type,
    required String color,
  }) async {
    try {
      final created =
          await Injection.instance.categoryRepository.createCategory(
        name: name,
        type: type,
        color: color,
      );
      if (mounted) {
        setState(() => _categories.add(created));
        _showSnackBar('Categoria "$name" criada', isError: false);
      }
    } on ServerException catch (e) {
      _showSnackBar(e.message);
    } catch (_) {
      _showSnackBar('Erro ao criar categoria');
    }
  }

  Future<void> _update({
    required String id,
    String? name,
    String? color,
  }) async {
    try {
      final updated =
          await Injection.instance.categoryRepository.updateCategory(
        id: id,
        name: name,
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

  void _showActions(CategoryEntity category) {
    if (category.isSystem) return;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              color: tc.neoCardElevated,
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
                    color: tc.neoTextFaint.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                AppListItem(
                  leading: const IconBadge(
                    icon: Icons.edit_rounded,
                    tone: 'info',
                  ),
                  title: 'Editar',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCreateSheet(editing: category);
                  },
                ),
                const SizedBox(height: 8),
                AppListItem(
                  leading: const IconBadge(
                    icon: Icons.delete_outline_rounded,
                    tone: 'danger',
                  ),
                  title: 'Excluir',
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteCategory(category);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return const Color(0xFF1A6F82);
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return const Color(0xFF1A6F82);
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final roots = _rootCategories;

    return Scaffold(
      backgroundColor: tc.neoBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: 'Categorias',
              subtitle:
                  '$_activeCount ${_activeCount == 1 ? 'ativa' : 'ativas'} · $_subCountTotal subcategorias',
              actions: [
                HeaderActionButton(
                  icon: Icons.add_rounded,
                  onTap: () => _showCreateSheet(),
                  tooltip: 'Nova categoria',
                ),
              ],
            ),
            AppPillTabs(
              labels: const ['Receitas', 'Despesas', 'Transferências'],
              selectedIndex: _selectedFilter,
              onChanged: (i) => setState(() => _selectedFilter = i),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAll,
                color: tc.neoTeal,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: tc.neoTeal),
                      )
                    : _errorMessage != null
                        ? _buildError(tc)
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHero(tc, roots),
                                const SizedBox(height: 16),
                                if (roots.isEmpty)
                                  _buildEmpty(tc)
                                else
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 1.05,
                                    ),
                                    itemCount: roots.length,
                                    itemBuilder: (_, i) {
                                      final c = roots[i];
                                      return _CategoryGridCard(
                                        category: c,
                                        subCount: _subCount(c.id),
                                        amount: _totalForCategory(c.id),
                                        onTap: () => _showActions(c),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(ThemeColors tc, List<CategoryEntity> roots) {
    // Top 3 categorias por gasto, ordenadas
    final entries = roots
        .map((c) => MapEntry(c, _totalForCategory(c.id)))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = entries.take(3).toList();

    return HeroGradientCard(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _monthLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${roots.length} categorias',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _fmtShort(_totalSpent),
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.2,
                height: 1.1,
              ),
            ),
          ),
          if (top3.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final e in top3) ...[
              _heroLegendRow(
                color: _legendColor(top3.indexOf(e)),
                label: e.key.name,
                percent: _totalSpent > 0
                    ? (e.value / _totalSpent * 100).round()
                    : 0,
              ),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }

  Color _legendColor(int i) {
    const palette = [
      Color(0xFF6BE3B0),
      Color(0xFFFF8585),
      Color(0xFFA48BFF),
    ];
    return palette[i % palette.length];
  }

  Widget _heroLegendRow({
    required Color color,
    required String label,
    required int percent,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$percent%',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          IconBadge(
            icon: Icons.category_rounded,
            tone: 'neutral',
            size: 64,
            iconSize: 28,
            radius: 18,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma categoria',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: tc.neoTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Crie sua primeira categoria.',
            style: TextStyle(fontSize: 13, color: tc.neoTextFaint),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: () => _showCreateSheet(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Criar categoria'),
            style: ElevatedButton.styleFrom(
              backgroundColor: tc.neoTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              minimumSize: const Size(220, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeColors tc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconBadge(
              icon: Icons.error_outline_rounded,
              tone: 'danger',
              size: 56,
              iconSize: 26,
              radius: 16,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Erro inesperado',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: tc.neoTextMuted),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadAll,
              style: TextButton.styleFrom(foregroundColor: tc.neoTeal),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  final CategoryEntity category;
  final int subCount;
  final double amount;
  final VoidCallback onTap;

  const _CategoryGridCard({
    required this.category,
    required this.subCount,
    required this.amount,
    required this.onTap,
  });

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return fallback;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return fallback;
    return Color(0xFF000000 | value);
  }

  String _toneFromName(String name) {
    final n = name.toLowerCase();
    if (n.contains('aliment')) return 'food';
    if (n.contains('transp')) return 'transport';
    if (n.contains('lazer') || n.contains('entret')) return 'entertainment';
    if (n.contains('compras')) return 'shopping';
    if (n.contains('saúde') || n.contains('saude')) return 'health';
    if (n.contains('contas') || n.contains('moradia') || n.contains('aluguel')) {
      return 'bills';
    }
    if (n.contains('salário') || n.contains('salario')) return 'salary';
    return 'neutral';
  }

  IconData _iconFromName(String name) {
    final n = name.toLowerCase();
    if (n.contains('aliment')) return Icons.restaurant_rounded;
    if (n.contains('transp')) return Icons.directions_car_rounded;
    if (n.contains('lazer') || n.contains('entret')) {
      return Icons.sports_esports_rounded;
    }
    if (n.contains('compras')) return Icons.shopping_cart_rounded;
    if (n.contains('saúde') || n.contains('saude')) {
      return Icons.medical_services_rounded;
    }
    if (n.contains('contas')) return Icons.receipt_long_rounded;
    if (n.contains('moradia') || n.contains('aluguel')) {
      return Icons.home_rounded;
    }
    if (n.contains('educa')) return Icons.school_rounded;
    if (n.contains('viagem')) return Icons.flight_rounded;
    if (n.contains('salár') || n.contains('salario')) {
      return Icons.flash_on_rounded;
    }
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final color = _parseColor(category.color, tc.neoTeal);

    return Material(
      color: tc.neoCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tc.neoCardBorder),
            boxShadow: [
              BoxShadow(
                color: tc.neoCardShadow,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(
                icon: _iconFromName(category.name),
                tone: _toneFromName(category.name),
                background:
                    color.withValues(alpha: tc.isDark ? 0.22 : 0.18),
                foreground: color,
                size: 40,
                iconSize: 18,
                radius: 12,
              ),
              const Spacer(),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tc.neoText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subCount > 0
                    ? '$subCount subcategorias'
                    : (category.isSystem ? 'Sistema' : 'Customizada'),
                style: TextStyle(
                  fontSize: 11.5,
                  color: tc.neoTextMuted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                amount > 0 ? _fmtSimple(amount) : '—',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: amount > 0 ? tc.neoText : tc.neoTextFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtSimple(double v) {
    final f = v.abs().toStringAsFixed(2).replaceAll('.', ',');
    final p = f.split(',');
    final i = p[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $i,${p[1]}';
  }
}
