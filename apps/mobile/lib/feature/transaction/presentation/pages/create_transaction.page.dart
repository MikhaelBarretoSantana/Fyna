import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_list_item.dart';
import 'package:fyna/core/widgets/category_picker_sheet.dart';
import 'package:fyna/core/widgets/create_amount_hero.dart';
import 'package:fyna/core/widgets/create_form_field_tile.dart';
import 'package:fyna/core/widgets/create_segmented_tabs.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
import 'package:fyna/feature/account/domain/entities/account_entity.dart';
import 'package:fyna/feature/category/domain/entities/category_entity.dart';
import 'package:intl/intl.dart';

class CreateTransactionPage extends StatefulWidget {
  final TransactionType? initialType;

  const CreateTransactionPage({super.key, this.initialType});

  @override
  State<CreateTransactionPage> createState() => _CreateTransactionPageState();
}

class _CreateTransactionPageState extends State<CreateTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late TransactionType _selectedType;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _transferAccountId;
  DateTime _transactionDate = DateTime.now();
  DateTime? _dueDate;
  bool _isPaid = true;
  bool _isLoading = false;
  bool _showAdvanced = false;

  List<AccountEntity> _accounts = [];
  List<CategoryEntity> _categories = [];
  bool _isLoadingData = true;

  /// Ordem visual dos tabs: Receita (0), Despesa (1), Transferência (2).
  /// Receita primeiro por decisão de UX. Mantida explicitamente porque
  /// difere da ordem do enum [TransactionType], que coincidentemente já
  /// é (income=0, expense=1, transfer=2). Mantemos a constante explícita
  /// para não acoplar UI à ordem do enum.
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
    _selectedType = widget.initialType ?? TransactionType.expense;
    _loadInitialData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    List<AccountEntity> loadedAccounts = [];
    List<CategoryEntity> loadedCategories = [];

    try {
      loadedAccounts =
          await Injection.instance.accountRepository.getAccounts();
    } catch (_) {}

    try {
      loadedCategories =
          await Injection.instance.categoryRepository.getCategories();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _accounts = loadedAccounts;
      _categories = loadedCategories;
      if (_accounts.isNotEmpty) _selectedAccountId = _accounts.first.id;
      _isLoadingData = false;
    });
  }

  List<CategoryEntity> get _filteredCategories {
    final typeFilter = _selectedType.toJson();
    return _categories.where((c) => c.type.toJson() == typeFilter).toList();
  }

  String get _typeTitle {
    switch (_selectedType) {
      case TransactionType.income:
        return 'Nova receita';
      case TransactionType.transfer:
        return 'Nova transferência';
      case TransactionType.expense:
        return 'Nova despesa';
    }
  }

  String get _typeSubtitle {
    switch (_selectedType) {
      case TransactionType.income:
        return 'Registre uma entrada em segundos';
      case TransactionType.transfer:
        return 'Mova dinheiro entre contas';
      case TransactionType.expense:
        return 'Registre um gasto em segundos';
    }
  }

  String get _typeCta {
    switch (_selectedType) {
      case TransactionType.income:
        return 'Salvar receita';
      case TransactionType.transfer:
        return 'Salvar transferência';
      case TransactionType.expense:
        return 'Salvar despesa';
    }
  }

  Color _heroColor(ThemeColors tc) {
    switch (_selectedType) {
      case TransactionType.income:
        return tc.neoPositive;
      case TransactionType.transfer:
        return tc.neoTeal;
      case TransactionType.expense:
        return tc.neoNegative;
    }
  }

  LinearGradient _heroGradient(ThemeColors tc) {
    final base = _heroColor(tc);
    if (_selectedType == TransactionType.transfer) {
      return tc.heroGradient; // teal gradient default
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        base.withValues(alpha: tc.isDark ? 0.85 : 1.0),
        HSLColor.fromColor(base)
            .withLightness(
                (HSLColor.fromColor(base).lightness - 0.15).clamp(0.0, 1.0))
            .toColor(),
      ],
    );
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      _showError('Selecione uma conta');
      return;
    }
    if (_selectedType == TransactionType.transfer &&
        _transferAccountId == null) {
      _showError('Selecione a conta de destino');
      return;
    }

    final amount = parseBrlAmount(_amountController.text) ?? 0;
    if (amount <= 0) {
      _showError('O valor deve ser maior que zero');
      return;
    }

    final selectedAccount =
        _accounts.firstWhere((a) => a.id == _selectedAccountId);

    if (_selectedType == TransactionType.expense &&
        amount > selectedAccount.currentBalance) {
      final ok = await _showBalanceWarning(
        amount: amount,
        balance: selectedAccount.currentBalance,
        accountName: selectedAccount.name,
      );
      if (ok != true) return;
    }

    if (_selectedType == TransactionType.transfer) {
      if (amount > selectedAccount.currentBalance) {
        _showError(
          'Saldo insuficiente em "${selectedAccount.name}". '
          'Disponível: ${_fmtCurrency(selectedAccount.currentBalance)}',
        );
        return;
      }
      if (_transferAccountId == _selectedAccountId) {
        _showError('As contas de origem e destino devem ser diferentes');
        return;
      }
    }

    if (_transactionDate.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      final confirm = await _showConfirmDialog(
        title: 'Data futura',
        message: 'A data informada é no futuro. Deseja continuar?',
      );
      if (confirm != true) return;
    }

    setState(() => _isLoading = true);
    try {
      await Injection.instance.transactionRepository.createTransaction(
        accountId: _selectedAccountId!,
        type: _selectedType.toJson(),
        amount: amount,
        description: _descriptionController.text.trim(),
        transactionDate: _transactionDate,
        categoryId: _selectedCategoryId,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        dueDate: _dueDate,
        isPaid: _isPaid,
        transferAccountId: _selectedType == TransactionType.transfer
            ? _transferAccountId
            : null,
      );
      if (mounted) Navigator.pop(context, true);
    } on ServerException catch (e) {
      _showError(e.message);
    } on NetworkException {
      _showError('Sem conexão com a internet');
    } on TimeoutException {
      _showError('A requisição demorou demais. Tente novamente.');
    } catch (_) {
      _showError('Erro inesperado ao criar transação');
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool?> _showBalanceWarning({
    required double amount,
    required double balance,
    required String accountName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        return AlertDialog(
          backgroundColor: tc.neoCardElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: IconBadge(
            icon: Icons.warning_amber_rounded,
            tone: 'warning',
            size: 56,
            iconSize: 26,
            radius: 16,
          ),
          title: Text(
            'Saldo insuficiente',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tc.neoText,
            ),
          ),
          content: Text(
            '"$accountName" tem ${_fmtCurrency(balance)}, mas você está '
            'lançando ${_fmtCurrency(amount)}. O saldo ficará negativo.',
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
                backgroundColor: tc.neoAttention,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Registrar mesmo assim',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        return AlertDialog(
          backgroundColor: tc.neoCardElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tc.neoText,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 14, color: tc.neoTextMuted),
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
                backgroundColor: tc.neoTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Continuar',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate({bool isDueDate = false}) async {
    final tc = ThemeColors.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? (_dueDate ?? DateTime.now()) : _transactionDate,
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
        if (isDueDate) {
          // Vencimento é só data — meia-noite local é OK.
          _dueDate = picked;
        } else {
          // showDatePicker devolve a data com 00:00:00. Se o usuário
          // escolheu hoje, queremos a hora "agora" (não meia-noite).
          // Para qualquer outro dia, preserva a hora que estava no estado
          // (que iniciou como DateTime.now()).
          final now = DateTime.now();
          final isToday = picked.year == now.year &&
              picked.month == now.month &&
              picked.day == now.day;
          _transactionDate = isToday
              ? now
              : DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  _transactionDate.hour,
                  _transactionDate.minute,
                  _transactionDate.second,
                );
        }
      });
    }
  }

  void _showAccountPicker({bool forTransferDestination = false}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        final accounts = forTransferDestination
            ? _accounts.where((a) => a.id != _selectedAccountId).toList()
            : _accounts;
        final selectedId =
            forTransferDestination ? _transferAccountId : _selectedAccountId;

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
                  forTransferDestination ? 'Conta destino' : 'Selecione a conta',
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
                    itemCount: accounts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final a = accounts[i];
                      final isSelected = a.id == selectedId;
                      return AppListItem(
                        leading: IconBadge(
                          icon: Icons.account_balance_wallet_rounded,
                          tone: 'transfer',
                        ),
                        title: a.name,
                        subtitle:
                            '${a.type.label} · ${_fmtCurrency(a.currentBalance)}',
                        trailing: isSelected
                            ? Icon(Icons.check_rounded, color: tc.neoTeal)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            if (forTransferDestination) {
                              _transferAccountId = a.id;
                            } else {
                              _selectedAccountId = a.id;
                            }
                          });
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
    HapticFeedback.lightImpact();
    final result = await showCategoryPickerSheet(
      context,
      categories: _filteredCategories,
      highlightId: _selectedCategoryId,
      title: 'Selecione uma categoria',
      subtitle: 'Tipo: ${_selectedType.label.toLowerCase()}',
      allowNoCategory: true,
      noCategorySubtitle: 'A IA classifica para você depois',
    );
    if (result != null && mounted) {
      setState(() => _selectedCategoryId = result.category?.id);
    }
  }

  String _fmtCurrency(double v) {
    final f = v.abs().toStringAsFixed(2).replaceAll('.', ',');
    final p = f.split(',');
    final i = p[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $i,${p[1]}';
  }

  String _fmtDateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dd = DateTime(d.year, d.month, d.day);
    final time = DateFormat('HH:mm').format(d);
    if (dd == today) return 'Hoje, $time';
    if (dd == yesterday) return 'Ontem, $time';
    return DateFormat("dd MMM yyyy, HH:mm", 'pt_BR').format(d);
  }

  String _fmtDateOnly(DateTime d) {
    return DateFormat("dd MMM yyyy", 'pt_BR').format(d);
  }

  String? _selectedAccountLabel() {
    if (_selectedAccountId == null) return null;
    final a = _accounts.firstWhere((x) => x.id == _selectedAccountId,
        orElse: () => _accounts.first);
    return '${a.name} · ${_fmtCurrency(a.currentBalance)}';
  }

  String? _selectedCategoryLabel() {
    if (_selectedCategoryId == null) return null;
    final c = _categories.firstWhere((x) => x.id == _selectedCategoryId,
        orElse: () => _categories.first);
    return c.name;
  }

  String? _selectedTransferAccountLabel() {
    if (_transferAccountId == null) return null;
    final a = _accounts.firstWhere((x) => x.id == _transferAccountId,
        orElse: () => _accounts.first);
    return a.name;
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
            _buildSheetHandle(tc),
            _buildHeader(tc),
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CreateAmountHero(
                          label: 'Valor',
                          controller: _amountController,
                          gradient: _heroGradient(tc),
                          autofocus: true,
                        ),
                        const SizedBox(height: 14),
                        CreateSegmentedTabs(
                          labels: const ['Receita', 'Despesa', 'Transfer.'],
                          // Ordem dos labels acima é orientada por UX (Despesa
                          // primeiro porque é o caso mais comum). NÃO usamos
                          // `_selectedType.index` porque o enum tem ordem
                          // diferente (income=0, expense=1, transfer=2) — isso
                          // estava trocando os comportamentos de Despesa/Receita.
                          selectedIndex: _tabIndexFromType(_selectedType),
                          activeColor: _heroColor(tc),
                          onChanged: (i) {
                            setState(() {
                              _selectedType = _typeFromTabIndex(i);
                              // Limpa categoria se mudou de tipo
                              _selectedCategoryId = null;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        CreateInlineTextField(
                          icon: Icons.edit_outlined,
                          label: 'Descrição',
                          controller: _descriptionController,
                          hint: _selectedType == TransactionType.income
                              ? 'Ex: Salário, freelance...'
                              : _selectedType == TransactionType.transfer
                                  ? 'Ex: Transferência reserva'
                                  : 'Ex: Mercado, iFood...',
                          maxLength: 80,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Informe a descrição';
                            }
                            return null;
                          },
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
                          label: _selectedType == TransactionType.transfer
                              ? 'Conta de origem'
                              : 'Conta',
                          value: _selectedAccountLabel(),
                          hint: 'Selecione',
                          onTap: () => _showAccountPicker(),
                        ),
                        if (_selectedType == TransactionType.transfer) ...[
                          const SizedBox(height: 10),
                          CreateFormFieldTile(
                            icon: Icons.swap_horiz_rounded,
                            label: 'Conta de destino',
                            value: _selectedTransferAccountLabel(),
                            hint: 'Selecione',
                            onTap: () =>
                                _showAccountPicker(forTransferDestination: true),
                          ),
                        ],
                        const SizedBox(height: 10),
                        CreateFormFieldTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Data',
                          value: _fmtDateLabel(_transactionDate),
                          onTap: () => _pickDate(),
                        ),
                        const SizedBox(height: 14),
                        _buildAdvancedToggle(tc),
                        if (_showAdvanced) _buildAdvancedFields(tc),
                      ],
                    ),
                  ),
                ),
              ),
            if (!_isLoadingData && _accounts.isNotEmpty)
              _buildBottomCta(tc),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHandle(ThemeColors tc) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: tc.neoTextFaint.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: tc.neoText,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _typeSubtitle,
                  style: TextStyle(fontSize: 13, color: tc.neoTextMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(Icons.close_rounded, color: tc.neoTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedToggle(ThemeColors tc) {
    return GestureDetector(
      onTap: () => setState(() => _showAdvanced = !_showAdvanced),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(
              _showAdvanced ? 'Ocultar opções' : 'Mais opções',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tc.neoTeal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _showAdvanced
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              size: 18,
              color: tc.neoTeal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFields(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          CreateFormFieldTile(
            icon: Icons.event_outlined,
            label: 'Vencimento',
            value: _dueDate != null ? _fmtDateOnly(_dueDate!) : null,
            hint: 'Opcional',
            trailing: _dueDate != null
                ? IconButton(
                    onPressed: () => setState(() => _dueDate = null),
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: tc.neoTextFaint),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
            onTap: () => _pickDate(isDueDate: true),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
              color: tc.neoCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tc.neoCardBorder),
            ),
            child: Row(
              children: [
                Icon(
                  _isPaid
                      ? Icons.check_circle_outline_rounded
                      : Icons.pending_outlined,
                  size: 18,
                  color: tc.neoTextMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATUS',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                          color: tc.neoTextFaint,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _isPaid ? 'Pago / efetivado' : 'Pendente',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: tc.neoText,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPaid,
                  onChanged: (v) => setState(() => _isPaid = v),
                  activeTrackColor: tc.neoTeal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CreateInlineTextField(
            icon: Icons.notes_rounded,
            label: 'Notas',
            controller: _notesController,
            hint: 'Observações adicionais...',
            maxLength: 200,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCta(ThemeColors tc) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
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
                : Text(_typeCta),
          ),
        ),
      ),
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
              'Crie uma conta antes de registrar transações.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: tc.neoTextFaint),
            ),
          ],
        ),
      ),
    );
  }
}
