import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/enums/recurring_frequency.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/account/domain/entities/account_entity.dart';
import 'package:fyna/feature/category/domain/entities/category_entity.dart';

class CreateRecurringPage extends StatefulWidget {
  const CreateRecurringPage({super.key});

  @override
  State<CreateRecurringPage> createState() => _CreateRecurringPageState();
}

class _CreateRecurringPageState extends State<CreateRecurringPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController(text: '0,00');

  late TransactionType _selectedType;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  RecurringFrequency _selectedFrequency = RecurringFrequency.MONTHLY;
  int _frequencyInterval = 1;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;

  // Dados carregados
  List<AccountEntity> _accounts = [];
  List<CategoryEntity> _categories = [];
  bool _isLoadingData = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _selectedType = TransactionType.expense;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadInitialData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    List<AccountEntity> loadedAccounts = [];
    List<CategoryEntity> loadedCategories = [];

    try {
      loadedAccounts =
          await Injection.instance.accountRepository.getAccounts();
    } catch (e) {
      debugPrint('Erro ao carregar contas: $e');
    }

    try {
      loadedCategories =
          await Injection.instance.categoryRepository.getCategories();
    } catch (e) {
      debugPrint('Erro ao carregar categorias: $e');
    }

    if (mounted) {
      setState(() {
        _accounts = loadedAccounts;
        _categories = loadedCategories;
        if (_accounts.isNotEmpty) {
          _selectedAccountId = _accounts.first.id;
        }
        _isLoadingData = false;
      });
    }
  }

  List<CategoryEntity> get _filteredCategories {
    final typeFilter = _selectedType == TransactionType.income
        ? 'INCOME'
        : _selectedType == TransactionType.transfer
            ? 'TRANSFER'
            : 'EXPENSE';
    return _categories.where((c) => c.type.toJson() == typeFilter).toList();
  }

  // ─── Criação ───
  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      _showError('Selecione uma conta');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amountText =
          _amountController.text.replaceAll('.', '').replaceAll(',', '.');
      final amount = double.tryParse(amountText) ?? 0.0;

      if (amount <= 0) {
        _showError('O valor deve ser maior que zero');
        setState(() => _isLoading = false);
        return;
      }

      await Injection.instance.recurringRepository.createRecurring(
        accountId: _selectedAccountId!,
        type: _selectedType.toJson(),
        amount: amount,
        description: _descriptionController.text.trim(),
        frequency: _selectedFrequency.toJson(),
        startDate: _startDate,
        categoryId: _selectedCategoryId,
        frequencyInterval: _frequencyInterval > 1 ? _frequencyInterval : null,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickDate({bool isEndDate = false}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEndDate ? (_endDate ?? _startDate) : _startDate,
      firstDate: isEndDate ? _startDate : DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        if (isEndDate) {
          _endDate = picked;
        } else {
          _startDate = picked;
          // Se endDate for antes de startDate, reseta
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        }
      });
    }
  }

  // ═══════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F5F8),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              _buildHeader(isDark),
              if (_isLoadingData)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (_accounts.isEmpty)
                _buildNoAccountsState(isDark)
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tipo
                          _buildTypeSelector(isDark),
                          const SizedBox(height: 24),

                          // Valor
                          _buildAmountSection(isDark),
                          const SizedBox(height: 24),

                          // Descrição
                          _buildSectionLabel('Descrição', isDark),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _descriptionController,
                            hint: 'Ex: Aluguel, Netflix, Salário...',
                            isDark: isDark,
                            icon: Icons.description_rounded,
                            maxLength: 80,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe a descrição';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Conta
                          _buildSectionLabel('Conta', isDark),
                          const SizedBox(height: 8),
                          _buildAccountDropdown(isDark),
                          const SizedBox(height: 24),

                          // Categoria
                          _buildSectionLabel('Categoria (opcional)', isDark),
                          const SizedBox(height: 8),
                          _buildCategoryDropdown(isDark),
                          const SizedBox(height: 24),

                          // Frequência
                          _buildSectionLabel('Frequência', isDark),
                          const SizedBox(height: 8),
                          _buildFrequencySelector(isDark),
                          const SizedBox(height: 16),
                          _buildIntervalSelector(isDark),
                          const SizedBox(height: 24),

                          // Data início
                          _buildSectionLabel('Data de início', isDark),
                          const SizedBox(height: 8),
                          _buildDateButton(
                            isDark: isDark,
                            label: _formatDate(_startDate),
                            icon: Icons.calendar_today_rounded,
                            onTap: () => _pickDate(),
                          ),
                          const SizedBox(height: 24),

                          // Data fim (opcional)
                          _buildSectionLabel('Data de término (opcional)', isDark),
                          const SizedBox(height: 8),
                          _buildEndDateSelector(isDark),
                          const SizedBox(height: 16),

                          // Preview resumo
                          _buildPreviewCard(isDark),
                          const SizedBox(height: 32),

                          // Botão criar
                          _buildCreateButton(isDark),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(bool isDark) {
    final typeColor = _getTypeColor(_selectedType);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F5F8),
        border: Border(
          bottom: BorderSide(
            color: typeColor.withValues(alpha: isDark ? 0.1 : 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_rounded,
                color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(width: 4),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.repeat_rounded, color: typeColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nova recorrência',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Automatize transações fixas',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAccountsState(bool isDark) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_rounded,
                  size: 64, color: isDark ? Colors.white24 : Colors.black12),
              const SizedBox(height: 16),
              Text('Nenhuma conta encontrada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  )),
              const SizedBox(height: 8),
              Text('Crie uma conta primeiro para criar recorrências.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : AppColors.textTertiary,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tipo ───
  Widget _buildTypeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : const Color(0xFFEEEEF2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [TransactionType.expense, TransactionType.income].map((type) {
          final isSelected = type == _selectedType;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedType = type;
                  _selectedCategoryId = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _getTypeColor(type)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _getTypeColor(type).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getTypeIcon(type),
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type == TransactionType.expense
                          ? 'Despesa fixa'
                          : 'Receita fixa',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white54 : Colors.black45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Valor ───
  Widget _buildAmountSection(bool isDark) {
    final typeColor = _getTypeColor(_selectedType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withValues(alpha: isDark ? 0.15 : 0.08),
            typeColor.withValues(alpha: isDark ? 0.05 : 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: typeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Valor recorrente',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_CurrencyInputFormatter()],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: typeColor,
              letterSpacing: -1,
            ),
            decoration: InputDecoration(
              prefixText: 'R\$ ',
              prefixStyle: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: typeColor.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Frequência ───
  Widget _buildFrequencySelector(bool isDark) {
    final frequencies = [
      RecurringFrequency.DAILY,
      RecurringFrequency.WEEKLY,
      RecurringFrequency.MONTHLY,
      RecurringFrequency.ANNUALLY,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: frequencies.map((freq) {
        final isSelected = freq == _selectedFrequency;
        final accentColor = isDark ? AppColors.darkAccent : AppColors.primary;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedFrequency = freq);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor
                  : (isDark
                      ? const Color(0xFF1C1C2E)
                      : const Color(0xFFEEEEF2)),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? null
                  : Border.all(
                      color: isDark
                          ? const Color(0xFF2D2D44)
                          : AppColors.border,
                    ),
            ),
            child: Text(
              freq.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Mais opções de frequência (bottom sheet) ───
  Widget _buildIntervalSelector(bool isDark) {
    // Mostra opções avançadas como quinzenal, bimestral, etc.
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showAllFrequencies(isDark),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1C1C2E) : const Color(0xFFEEEEF2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2D2D44)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded,
                      size: 18,
                      color: isDark ? Colors.white38 : AppColors.textTertiary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frequência detalhada',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        Text(
                          _frequencyDetailLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark ? Colors.white24 : Colors.black26),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _frequencyDetailLabel {
    if (_frequencyInterval <= 1) return _selectedFrequency.label;
    final unit = _frequencyUnitName(_selectedFrequency);
    return 'A cada $_frequencyInterval $unit';
  }

  String _frequencyUnitName(RecurringFrequency freq) {
    switch (freq) {
      case RecurringFrequency.DAILY:
        return 'dias';
      case RecurringFrequency.WEEKLY:
        return 'semanas';
      case RecurringFrequency.MONTHLY:
        return 'meses';
      case RecurringFrequency.ANNUALLY:
        return 'anos';
      default:
        return 'períodos';
    }
  }

  void _showAllFrequencies(bool isDark) {
    final allFreqs = RecurringFrequency.values;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              20, 14, 20, MediaQuery.of(ctx).padding.bottom > 0 ? 12 : 28),
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
              Text('Frequência',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  )),
              const SizedBox(height: 16),
              ...allFreqs.map((freq) {
                final isSelected = freq == _selectedFrequency;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedFrequency = freq;
                          _frequencyInterval = 1;
                        });
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                      ? AppColors.darkAccent
                                      : AppColors.primary)
                                  .withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? (isDark
                                        ? AppColors.darkAccent
                                        : AppColors.primary)
                                    .withValues(alpha: 0.3)
                                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(freq.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                )),
                            const Spacer(),
                            if (isSelected)
                              Icon(Icons.check_rounded,
                                  size: 20,
                                  color: isDark
                                      ? AppColors.darkAccent
                                      : AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ─── Data fim ───
  Widget _buildEndDateSelector(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildDateButton(
            isDark: isDark,
            label: _endDate != null
                ? _formatDate(_endDate!)
                : 'Sem data de término',
            icon: Icons.event_rounded,
            onTap: () => _pickDate(isEndDate: true),
            isPlaceholder: _endDate == null,
          ),
        ),
        if (_endDate != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _endDate = null),
            child: Container(
              width: 48,
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2D2D44)
                      : AppColors.border,
                ),
              ),
              child: Icon(Icons.close_rounded,
                  color: isDark ? Colors.white38 : AppColors.textTertiary,
                  size: 20),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Preview / resumo ───
  Widget _buildPreviewCard(bool isDark) {
    final typeColor = _getTypeColor(_selectedType);
    final amountText =
        _amountController.text.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(amountText) ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? typeColor.withValues(alpha: 0.06)
            : typeColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: typeColor.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text('Resumo da recorrência',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: typeColor.withValues(alpha: 0.8),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          _buildPreviewRow(
            isDark,
            'Tipo',
            _selectedType == TransactionType.expense
                ? 'Despesa fixa'
                : 'Receita fixa',
          ),
          _buildPreviewRow(isDark, 'Frequência', _frequencyDetailLabel),
          _buildPreviewRow(isDark, 'Início', _formatDate(_startDate)),
          if (_endDate != null)
            _buildPreviewRow(isDark, 'Término', _formatDate(_endDate!)),
          if (amount > 0) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _selectedFrequency == RecurringFrequency.MONTHLY
                    ? '≈ R\$ ${(amount * 12).toStringAsFixed(0)} por ano'
                    : _selectedFrequency == RecurringFrequency.WEEKLY
                        ? '≈ R\$ ${(amount * 4.33).toStringAsFixed(0)} por mês'
                        : _selectedFrequency == RecurringFrequency.DAILY
                            ? '≈ R\$ ${(amount * 30).toStringAsFixed(0)} por mês'
                            : '≈ R\$ ${(amount / 12).toStringAsFixed(0)} por mês',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: typeColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white30 : Colors.black38,
              )),
          const Spacer(),
          Text(value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              )),
        ],
      ),
    );
  }

  // ─── Botão criar ───
  Widget _buildCreateButton(bool isDark) {
    final typeColor = _getTypeColor(_selectedType);

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCreate,
        style: ElevatedButton.styleFrom(
          backgroundColor: typeColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: typeColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.repeat_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Criar recorrência',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  WIDGETS REUTILIZÁVEIS (mesmo padrão create_transaction)
  // ═══════════════════════════════════════════════

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      style: TextStyle(
        fontSize: 16,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      buildCounter: maxLength != null
          ? (context,
              {required currentLength,
              required isFocused,
              required maxLength}) {
              return Text(
                '$currentLength/$maxLength',
                style: TextStyle(
                  fontSize: 11,
                  color: currentLength > (maxLength ?? 0) * 0.9
                      ? AppColors.warning
                      : (isDark ? Colors.white30 : AppColors.textTertiary),
                ),
              );
            }
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : AppColors.textDisabled,
          fontSize: 16,
        ),
        prefixIcon: Icon(icon,
            color: isDark ? Colors.white38 : AppColors.textTertiary, size: 22),
        filled: true,
        fillColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2D2D44) : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2D2D44) : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkAccent : AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildAccountDropdown(bool isDark) {
    return _buildDropdownContainer(
      isDark: isDark,
      icon: Icons.account_balance_rounded,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedAccountId,
          isExpanded: true,
          hint: Text('Selecione uma conta',
              style: TextStyle(
                color: isDark ? Colors.white30 : AppColors.textDisabled,
                fontSize: 16,
              )),
          dropdownColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          items: _accounts
              .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
              .toList(),
          onChanged: (v) => setState(() => _selectedAccountId = v),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(bool isDark) {
    final cats = _filteredCategories;
    return _buildDropdownContainer(
      isDark: isDark,
      icon: Icons.category_rounded,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedCategoryId,
          isExpanded: true,
          hint: Text('Sem categoria',
              style: TextStyle(
                color: isDark ? Colors.white30 : AppColors.textDisabled,
                fontSize: 16,
              )),
          dropdownColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('Sem categoria',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppColors.textTertiary,
                  )),
            ),
            ...cats.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
          ],
          onChanged: (v) => setState(() => _selectedCategoryId = v),
        ),
      ),
    );
  }

  Widget _buildDropdownContainer({
    required bool isDark,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2D44) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: isDark ? Colors.white38 : AppColors.textTertiary,
              size: 22),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required bool isDark,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isPlaceholder = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2D2D44) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isDark ? Colors.white38 : AppColors.textTertiary,
                size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isPlaceholder
                    ? (isDark ? Colors.white30 : AppColors.textDisabled)
                    : (isDark ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Utils ───
  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return AppColors.error;
      case TransactionType.income:
        return AppColors.success;
      case TransactionType.transfer:
        return AppColors.info;
    }
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return Icons.arrow_downward_rounded;
      case TransactionType.income:
        return Icons.arrow_upward_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}

/// Formata entrada numérica como moeda brasileira (ex: 1.234,56).
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '0,00',
        selection: TextSelection.collapsed(offset: 4),
      );
    }

    while (digitsOnly.length < 3) {
      digitsOnly = '0$digitsOnly';
    }

    final intPart = digitsOnly.substring(0, digitsOnly.length - 2);
    final decPart = digitsOnly.substring(digitsOnly.length - 2);

    final cleanInt = intPart.replaceFirst(RegExp(r'^0+'), '');
    final finalInt = cleanInt.isEmpty ? '0' : cleanInt;

    final withThousands = finalInt.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    final formatted = '$withThousands,$decPart';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}