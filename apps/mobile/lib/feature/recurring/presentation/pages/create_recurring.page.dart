import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/enums/recurring_frequency.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_list_item.dart';
import 'package:fyna/core/widgets/app_screen_header.dart';
import 'package:fyna/core/widgets/category_picker_sheet.dart';
import 'package:fyna/core/widgets/create_amount_hero.dart';
import 'package:fyna/core/widgets/create_form_field_tile.dart';
import 'package:fyna/core/widgets/create_segmented_tabs.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
import 'package:fyna/feature/account/domain/entities/account_entity.dart';
import 'package:fyna/feature/category/domain/entities/category_entity.dart';
import 'package:intl/intl.dart';

class CreateRecurringPage extends StatefulWidget {
  const CreateRecurringPage({super.key});

  @override
  State<CreateRecurringPage> createState() => _CreateRecurringPageState();
}

class _CreateRecurringPageState extends State<CreateRecurringPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  RecurringFrequency _selectedFrequency = RecurringFrequency.MONTHLY;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;

  List<AccountEntity> _accounts = [];
  List<CategoryEntity> _categories = [];
  bool _isLoadingData = true;

  static const List<RecurringFrequency> _frequencyOptions = [
    RecurringFrequency.DAILY,
    RecurringFrequency.WEEKLY,
    RecurringFrequency.BIWEEKLY,
    RecurringFrequency.MONTHLY,
    RecurringFrequency.BIMONTHLY,
    RecurringFrequency.ANNUALLY,
  ];

  /// Ordem visual dos tabs: Receita (0), Despesa (1), Transferência (2).
  /// Receita primeiro por decisão de UX.
  static const List<TransactionType> _tabOrder = [
    TransactionType.income,
    TransactionType.expense,
    TransactionType.transfer,
  ];

  int _tabIndexFromType(TransactionType t) => _tabOrder.indexOf(t);
  TransactionType _typeFromTabIndex(int i) =>
      _tabOrder[i.clamp(0, _tabOrder.length - 1)];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    List<AccountEntity> a = [];
    List<CategoryEntity> c = [];
    try {
      a = await Injection.instance.accountRepository.getAccounts();
    } catch (_) {}
    try {
      c = await Injection.instance.categoryRepository.getCategories();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _accounts = a;
      _categories = c;
      if (_accounts.isNotEmpty) _selectedAccountId = _accounts.first.id;
      _isLoadingData = false;
    });
  }

  List<CategoryEntity> get _filteredCategories {
    final typeFilter = _selectedType.toJson();
    return _categories.where((c) => c.type.toJson() == typeFilter).toList();
  }

  DateTime _nextOccurrence() {
    // Aproximação: a próxima ocorrência considera a frequência a partir da
    // data de início. Para visualização — backend recalcula.
    final now = DateTime.now();
    var next = _startDate;
    if (next.isBefore(now)) {
      switch (_selectedFrequency) {
        case RecurringFrequency.DAILY:
          next = now.add(const Duration(days: 1));
          break;
        case RecurringFrequency.WEEKLY:
          next = now.add(const Duration(days: 7));
          break;
        case RecurringFrequency.BIWEEKLY:
          next = now.add(const Duration(days: 14));
          break;
        case RecurringFrequency.MONTHLY:
          next = DateTime(now.year, now.month + 1, _startDate.day);
          break;
        case RecurringFrequency.BIMONTHLY:
          next = DateTime(now.year, now.month + 2, _startDate.day);
          break;
        case RecurringFrequency.QUARTERLY:
          next = DateTime(now.year, now.month + 3, _startDate.day);
          break;
        case RecurringFrequency.SEMIANNUALLY:
          next = DateTime(now.year, now.month + 6, _startDate.day);
          break;
        case RecurringFrequency.ANNUALLY:
          next = DateTime(now.year + 1, now.month, _startDate.day);
          break;
      }
    }
    return next;
  }

  String _daysUntilNext() {
    final next = _nextOccurrence();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextDay = DateTime(next.year, next.month, next.day);
    final diff = nextDay.difference(today).inDays;
    if (diff < 0) return '';
    if (diff == 0) return ' (hoje)';
    if (diff == 1) return ' (em 1 dia)';
    return ' (em $diff dias)';
  }

  Color _heroAccent(ThemeColors tc) {
    switch (_selectedType) {
      case TransactionType.income:
        return tc.neoPositive;
      case TransactionType.transfer:
        return tc.neoTeal;
      case TransactionType.expense:
        return tc.neoNegative;
    }
  }

  String _signFor() {
    switch (_selectedType) {
      case TransactionType.income:
        return '+';
      case TransactionType.transfer:
        return '';
      case TransactionType.expense:
        return '-';
    }
  }

  String _frequencyShortLabel() {
    switch (_selectedFrequency) {
      case RecurringFrequency.DAILY:
        return 'DIÁRIA';
      case RecurringFrequency.WEEKLY:
        return 'SEMANAL';
      case RecurringFrequency.BIWEEKLY:
        return 'QUINZENAL';
      case RecurringFrequency.MONTHLY:
        return 'MENSAL · DIA ${_startDate.day}';
      case RecurringFrequency.BIMONTHLY:
        return 'BIMESTRAL';
      case RecurringFrequency.QUARTERLY:
        return 'TRIMESTRAL';
      case RecurringFrequency.SEMIANNUALLY:
        return 'SEMESTRAL';
      case RecurringFrequency.ANNUALLY:
        return 'ANUAL';
    }
  }

  Future<void> _pickDate({bool isEndDate = false}) async {
    final tc = ThemeColors.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: isEndDate ? (_endDate ?? _startDate) : _startDate,
      firstDate: isEndDate ? _startDate : DateTime(2020),
      lastDate: DateTime(2035),
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
        if (isEndDate) {
          _endDate = picked;
        } else {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        }
      });
    }
  }

  void _showAccountPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.65,
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                const SizedBox(height: 14),
                Text(
                  'Conta',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tc.neoText,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _accounts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final a = _accounts[i];
                      final isSelected = a.id == _selectedAccountId;
                      return AppListItem(
                        leading: IconBadge(
                          icon: Icons.account_balance_wallet_rounded,
                          tone: 'transfer',
                        ),
                        title: a.name,
                        subtitle: a.type.label,
                        trailing: isSelected
                            ? Icon(Icons.check_rounded, color: tc.neoTeal)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() => _selectedAccountId = a.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCategoryPicker() async {
    final result = await showCategoryPickerSheet(
      context,
      categories: _filteredCategories,
      highlightId: _selectedCategoryId,
      title: 'Categoria',
      subtitle: 'Tipo: ${_selectedType.label.toLowerCase()}',
      allowNoCategory: true,
    );
    if (result != null && mounted) {
      setState(() => _selectedCategoryId = result.category?.id);
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      _showError('Selecione uma conta');
      return;
    }
    final amount = parseBrlAmount(_amountController.text) ?? 0;
    if (amount <= 0) {
      _showError('O valor deve ser maior que zero');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Injection.instance.recurringRepository.createRecurring(
        accountId: _selectedAccountId!,
        type: _selectedType.toJson(),
        amount: amount,
        description: _descriptionController.text.trim(),
        frequency: _selectedFrequency.toJson(),
        startDate: _startDate,
        categoryId: _selectedCategoryId,
        endDate: _endDate,
      );
      if (mounted) Navigator.pop(context, true);
    } on ServerException catch (e) {
      _showError(e.message);
    } on NetworkException {
      _showError('Sem conexão com a internet');
    } on TimeoutException {
      _showError('A requisição demorou demais. Tente novamente.');
    } catch (_) {
      _showError('Erro inesperado ao criar recorrência');
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

  String? _selectedAccountLabel() {
    if (_selectedAccountId == null) return null;
    final a = _accounts.firstWhere((x) => x.id == _selectedAccountId,
        orElse: () => _accounts.first);
    return '${a.name} · ${a.type.label}';
  }

  String? _selectedCategoryLabel() {
    if (_selectedCategoryId == null) return null;
    return _categories
        .firstWhere((x) => x.id == _selectedCategoryId,
            orElse: () => _categories.first)
        .name;
  }

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
              title: 'Nova recorrência',
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            ),
            if (_isLoadingData)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: tc.neoTeal),
                ),
              )
            else if (_accounts.isEmpty)
              Expanded(child: _buildNoAccountsState(tc))
            else
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CreateSegmentedTabs(
                          labels: const ['Receita', 'Despesa', 'Transfer.'],
                          // Ordem dos labels acima é orientada por UX (despesa
                          // primeiro porque é o caso mais comum). NÃO usamos
                          // `_selectedType.index` porque o enum tem ordem
                          // diferente (income=0, expense=1, transfer=2) — isso
                          // estava trocando os comportamentos de Despesa/Receita.
                          selectedIndex: _tabIndexFromType(_selectedType),
                          activeColor: _heroAccent(tc),
                          onChanged: (i) {
                            setState(() {
                              _selectedType = _typeFromTabIndex(i);
                              _selectedCategoryId = null;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildRecurringHero(tc),
                        const SizedBox(height: 14),
                        CreateInlineTextField(
                          icon: Icons.edit_outlined,
                          label: 'Descrição',
                          controller: _descriptionController,
                          hint: _selectedType == TransactionType.income
                              ? 'Ex: Salário, Aluguel recebido'
                              : 'Ex: Netflix, Aluguel',
                          maxLength: 80,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe a descrição'
                              : null,
                          autofocus: true,
                        ),
                        const SizedBox(height: 10),
                        CreateFormFieldTile(
                          icon: Icons.category_outlined,
                          label: 'Categoria',
                          value: _selectedCategoryLabel(),
                          hint: 'Selecionar (opcional)',
                          onTap: _showCategoryPicker,
                        ),
                        const SizedBox(height: 10),
                        CreateFormFieldTile(
                          icon: Icons.account_balance_outlined,
                          label: 'Conta',
                          value: _selectedAccountLabel(),
                          onTap: _showAccountPicker,
                        ),
                        const SizedBox(height: 14),
                        _sectionLabel(tc, 'FREQUÊNCIA'),
                        const SizedBox(height: 8),
                        _buildFrequencyChips(tc),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: CreateFormFieldTile(
                                icon: Icons.play_circle_outline_rounded,
                                label: 'Início',
                                value: DateFormat("dd MMM yyyy", 'pt_BR')
                                    .format(_startDate),
                                onTap: () => _pickDate(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CreateFormFieldTile(
                                icon: Icons.stop_circle_outlined,
                                label: 'Fim (opcional)',
                                value: _endDate != null
                                    ? DateFormat("dd MMM yyyy", 'pt_BR')
                                        .format(_endDate!)
                                    : 'Sem data fim',
                                trailing: _endDate != null
                                    ? IconButton(
                                        onPressed: () =>
                                            setState(() => _endDate = null),
                                        icon: Icon(Icons.close_rounded,
                                            size: 18,
                                            color: tc.neoTextFaint),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      )
                                    : null,
                                onTap: () => _pickDate(isEndDate: true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!_isLoadingData && _accounts.isNotEmpty) _buildCta(tc),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringHero(ThemeColors tc) {
    final accent = _heroAccent(tc);
    final sign = _signFor();
    final next = _nextOccurrence();

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          decoration: BoxDecoration(
            // Dark fundo como no design (preto-azulado)
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF181B26), Color(0xFF0E1018)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.autorenew_rounded,
                      size: 14, color: Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    'VALOR · ${_frequencyShortLabel()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      sign,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'R\$',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [_BrlFormatter()],
                      cursorColor: accent,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: '0,00',
                        hintStyle: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: accent.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Próxima: ${DateFormat("dd MMM yyyy", 'pt_BR').format(next)}${_daysUntilNext()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildFrequencyChips(ThemeColors tc) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _frequencyOptions.map((f) {
        final selected = f == _selectedFrequency;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedFrequency = f);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? tc.neoTeal : tc.neoCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? tc.neoTeal : tc.neoCardBorder,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: tc.neoTeal.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              f.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : tc.neoText,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoAccountsState(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconBadge(
              icon: Icons.account_balance_wallet_rounded,
              tone: 'neutral',
              size: 64,
              iconSize: 28,
              radius: 18,
            ),
            const SizedBox(height: 14),
            Text(
              'Nenhuma conta cadastrada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: tc.neoTextMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Crie uma conta antes de criar recorrências.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: tc.neoTextFaint),
            ),
          ],
        ),
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
            onPressed: _isLoading ? null : _handleCreate,
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
                : const Text('Criar recorrência'),
          ),
        ),
      ),
    );
  }

}

/// Espelha o formatter de [CreateAmountHero] para uso direto no hero
/// customizado dessa página (que tem layout diferente do componente padrão).
class _BrlFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    if (digits.length > 12) digits = digits.substring(0, 12);
    final padded = digits.padLeft(3, '0');
    final intPart = padded.substring(0, padded.length - 2);
    final decPart = padded.substring(padded.length - 2);
    final intFormatted = intPart.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    final intClean = intFormatted.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted = '${intClean.isEmpty ? '0' : intClean},$decPart';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
