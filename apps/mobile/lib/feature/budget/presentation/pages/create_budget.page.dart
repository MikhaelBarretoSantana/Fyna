import 'package:flutter/material.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/enums/budget_period_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_screen_header.dart';
import 'package:fyna/core/widgets/category_picker_sheet.dart';
import 'package:fyna/core/widgets/create_amount_hero.dart';
import 'package:fyna/core/widgets/create_form_field_tile.dart';
import 'package:fyna/core/widgets/create_segmented_tabs.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
import 'package:fyna/feature/category/domain/entities/category_entity.dart';
import 'package:intl/intl.dart';

class CreateBudgetPage extends StatefulWidget {
  const CreateBudgetPage({super.key});

  @override
  State<CreateBudgetPage> createState() => _CreateBudgetPageState();
}

class _CreateBudgetPageState extends State<CreateBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();

  // Apenas Semanal / Mensal / Anual no design — alinhamos a UI a esses 3
  // pontos de corte e mapeamos para BudgetPeriodType.
  int _periodIndex = 1; // 0=Semanal, 1=Mensal, 2=Anual
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late DateTime _endDate = _defaultEndDate();
  bool _alertEnabled = true;
  double _alertThreshold = 80; // percentual
  String? _selectedCategoryId;

  /// True após o usuário interagir com o seletor (mesmo que escolha
  /// "Sem categoria específica"). Sem isso, o submit era aceito com o
  /// estado-padrão `null`, criando um budget GLOBAL que conta todas as
  /// despesas — comportamento confuso quando o usuário acha que está
  /// criando um budget para uma categoria.
  bool _categoryPicked = false;

  List<CategoryEntity> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats =
          await Injection.instance.categoryRepository.getCategories();
      if (!mounted) return;
      setState(() => _categories =
          cats.where((c) => c.type.toJson() == 'EXPENSE').toList());
    } catch (_) {}
  }

  BudgetPeriodType get _periodType {
    switch (_periodIndex) {
      case 0:
        return BudgetPeriodType.WEEKLY;
      case 2:
        return BudgetPeriodType.ANNUALLY;
      case 1:
      default:
        return BudgetPeriodType.MONTHLY;
    }
  }

  DateTime _defaultEndDate() {
    final now = DateTime.now();
    switch (_periodIndex) {
      case 0:
        return now.add(const Duration(days: 6));
      case 2:
        return DateTime(now.year, 12, 31);
      case 1:
      default:
        return DateTime(now.year, now.month + 1, 0);
    }
  }

  void _onPeriodChanged(int i) {
    setState(() {
      _periodIndex = i;
      // Recalcula sugestão de range
      final now = DateTime.now();
      switch (i) {
        case 0:
          _startDate = now;
          _endDate = now.add(const Duration(days: 6));
          break;
        case 2:
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31);
          break;
        case 1:
        default:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
      }
    });
  }

  String? _selectedCategoryName() {
    if (_selectedCategoryId == null) return null;
    return _categories
        .firstWhere(
          (c) => c.id == _selectedCategoryId,
          orElse: () => _categories.first,
        )
        .name;
  }

  int _selectedCategorySubcount() {
    if (_selectedCategoryId == null) return 0;
    return _categories.where((c) => c.parentId == _selectedCategoryId).length;
  }

  Future<void> _showCategoryPicker() async {
    final result = await showCategoryPickerSheet(
      context,
      categories: _categories,
      highlightId: _selectedCategoryId,
      title: 'Categoria do orçamento',
      subtitle: 'A escolha define o que será contabilizado',
      allowNoCategory: true,
      noCategoryLabel: 'Sem categoria específica',
      noCategorySubtitle: 'Orçamento geral — conta todas as despesas',
    );
    if (result != null && mounted) {
      setState(() {
        _selectedCategoryId = result.category?.id;
        _categoryPicked = true;
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final tc = ThemeColors.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: tc.neoTeal,
            brightness: tc.isDark ? Brightness.dark : Brightness.light,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_categoryPicked) {
      _showError('Escolha uma categoria (ou "Sem categoria específica")');
      setState(() {}); // força rebuild para mostrar estado de erro no field
      return;
    }
    final amount = parseBrlAmount(_limitController.text);
    if (amount == null || amount <= 0) {
      _showError('Valor limite inválido');
      return;
    }
    if (!_endDate.isAfter(_startDate)) {
      _showError('Data fim deve ser depois da data início');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Injection.instance.budgetRepository.createBudget(
        categoryId: _selectedCategoryId,
        name: _nameController.text.trim(),
        amountLimit: amount,
        periodType: _periodType,
        startDate: _startDate,
        endDate: _endDate,
        alertThreshold: _alertEnabled ? _alertThreshold : null,
        alertEnabled: _alertEnabled,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orçamento criado'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } on ServerException catch (e) {
      _showError(e.message);
    } on NetworkException {
      _showError('Sem conexão com a internet');
    } catch (_) {
      _showError('Erro ao criar orçamento');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    final tc = ThemeColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: tc.neoNegative,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      DateFormat("dd MMM yyyy", 'pt_BR').format(d);

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: tc.neoBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: 'Novo orçamento',
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CreateAmountHero(
                        label: 'Limite mensal',
                        controller: _limitController,
                        autofocus: true,
                      ),
                      const SizedBox(height: 14),
                      CreateInlineTextField(
                        icon: Icons.edit_outlined,
                        label: 'Nome do orçamento',
                        controller: _nameController,
                        hint: 'Ex: Alimentação mensal',
                        maxLength: 100,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Informe o nome'
                                : null,
                      ),
                      const SizedBox(height: 10),
                      CreateFormFieldTile(
                        icon: Icons.category_outlined,
                        label: 'Categoria',
                        value: _categoryPicked
                            ? (_selectedCategoryName() ??
                                'Geral · todas as despesas')
                            : null,
                        hint: 'Toque para escolher',
                        isError: !_categoryPicked,
                        trailing: _selectedCategoryId != null &&
                                _selectedCategorySubcount() > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tc.badge('shopping').bg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_selectedCategorySubcount()} sub',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: tc.badge('shopping').fg,
                                  ),
                                ),
                              )
                            : null,
                        onTap: _showCategoryPicker,
                      ),
                      if (!_categoryPicked)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                          child: Text(
                            'Escolha uma categoria específica ou "Sem categoria" '
                            'para um orçamento geral.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: tc.neoTextMuted,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      _sectionLabel(tc, 'PERÍODO'),
                      const SizedBox(height: 8),
                      CreateSegmentedTabs(
                        labels: const ['Semanal', 'Mensal', 'Anual'],
                        selectedIndex: _periodIndex,
                        onChanged: _onPeriodChanged,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: CreateFormFieldTile(
                              icon: Icons.play_circle_outline_rounded,
                              label: 'Início',
                              value: _fmtDate(_startDate),
                              onTap: () => _pickDate(isStart: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CreateFormFieldTile(
                              icon: Icons.stop_circle_outlined,
                              label: 'Fim',
                              value: _fmtDate(_endDate),
                              onTap: () => _pickDate(isStart: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildAlertCard(tc),
                    ],
                  ),
                ),
              ),
            ),
            _buildCta(tc),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeColors tc, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: tc.neoTextFaint,
        ),
      );

  Widget _buildAlertCard(ThemeColors tc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: tc.neoCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.neoCardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconBadge(
                icon: Icons.notifications_rounded,
                tone: 'warning',
                size: 36,
                iconSize: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alertar ao atingir',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: tc.neoText,
                      ),
                    ),
                    Text(
                      'Notificar quando ultrapassar o limite configurado',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: tc.neoTextMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _alertEnabled,
                onChanged: (v) => setState(() => _alertEnabled = v),
                activeTrackColor: tc.neoTeal,
              ),
            ],
          ),
          if (_alertEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Limite de alerta',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: tc.neoTextMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_alertThreshold.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tc.neoAttention,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: tc.neoAttention,
                inactiveTrackColor: tc.neoCardBorder,
                thumbColor: tc.neoAttention,
                overlayColor: tc.neoAttention.withValues(alpha: 0.12),
                trackHeight: 3,
              ),
              child: Slider(
                value: _alertThreshold,
                min: 10,
                max: 100,
                divisions: 18,
                onChanged: (v) => setState(() => _alertThreshold = v),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCta(ThemeColors tc) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: tc.neoTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Criar orçamento'),
          ),
        ),
      ),
    );
  }
}
