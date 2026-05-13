import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/feature/account/domain/entities/account_entity.dart';
import 'package:fyna/feature/category/domain/entities/category_entity.dart';

class CreateTransactionPage extends StatefulWidget {
  final TransactionType? initialType;

  const CreateTransactionPage({super.key, this.initialType});

  @override
  State<CreateTransactionPage> createState() => _CreateTransactionPageState();
}

class _CreateTransactionPageState extends State<CreateTransactionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController(text: '0,00');
  final _notesController = TextEditingController();

  late TransactionType _selectedType;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _transferAccountId;
  DateTime _transactionDate = DateTime.now();
  DateTime? _dueDate;
  bool _isPaid = true;
  bool _isLoading = false;

  // Dados carregados do backend
  List<AccountEntity> _accounts = [];
  List<CategoryEntity> _categories = [];
  bool _isLoadingData = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? TransactionType.expense;
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
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // Carrega contas e categorias independentemente para evitar
    // que a falha de um impeça o outro de carregar.
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

      // ─── Validações de saldo ───
      final selectedAccount = _accounts.firstWhere(
        (a) => a.id == _selectedAccountId,
      );

      if (_selectedType == TransactionType.expense) {
        if (amount > selectedAccount.currentBalance) {
          final confirmed = await _showBalanceWarning(
            amount: amount,
            balance: selectedAccount.currentBalance,
            accountName: selectedAccount.name,
          );
          if (confirmed != true) {
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      if (_selectedType == TransactionType.transfer) {
        if (amount > selectedAccount.currentBalance) {
          _showError(
            'Saldo insuficiente na conta "${selectedAccount.name}". '
            'Disponível: ${_formatCurrency(selectedAccount.currentBalance)}',
          );
          setState(() => _isLoading = false);
          return;
        }
        if (_transferAccountId == _selectedAccountId) {
          _showError('As contas de origem e destino devem ser diferentes');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Validação de descrição duplicada recente (últimas 24h)
      // Validação de data futura
      if (_transactionDate.isAfter(DateTime.now().add(const Duration(days: 1)))) {
        final confirmFuture = await _showConfirmDialog(
          title: 'Data futura',
          message: 'A data informada é no futuro. Deseja continuar?',
        );
        if (confirmFuture != true) {
          setState(() => _isLoading = false);
          return;
        }
      }

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

      if (mounted) {
        Navigator.pop(context, true);
      }
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

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }

  Future<bool?> _showBalanceWarning({
    required double amount,
    required double balance,
    required String accountName,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 32,
          ),
        ),
        title: Text(
          'Saldo insuficiente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A conta "$accountName" possui saldo de '
              '${_formatCurrency(balance)}, mas a despesa é de '
              '${_formatCurrency(amount)}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O saldo ficará negativo se continuar.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Registrar mesmo assim',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkAccent : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Continuar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({bool isDueDate = false}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? (_dueDate ?? DateTime.now()) : _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _transactionDate = picked;
        }
      });
    }
  }

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
                  child: Center(child: CircularProgressIndicator()),
                )
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
                          // Tipo de transação
                          _buildTransactionTypeSelector(isDark),
                          const SizedBox(height: 24),

                          // Valor
                          _buildAmountSection(isDark),
                          const SizedBox(height: 24),

                          // Descrição
                          _buildSectionLabel('Descrição', isDark),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _descriptionController,
                            hint: 'Ex: Almoço, Salário, Uber...',
                            isDark: isDark,
                            icon: Icons.description_rounded,
                            maxLength: 80,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe a descrição';
                              }
                              if (v.trim().length > 80) {
                                return 'Máximo de 80 caracteres';
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

                          // Conta destino (só pra transferência)
                          if (_selectedType == TransactionType.transfer) ...[
                            _buildSectionLabel('Conta destino', isDark),
                            const SizedBox(height: 8),
                            _buildTransferAccountDropdown(isDark),
                            const SizedBox(height: 24),
                          ],

                          // Categoria
                          _buildSectionLabel('Categoria (opcional)', isDark),
                          const SizedBox(height: 8),
                          _buildCategoryDropdown(isDark),
                          const SizedBox(height: 24),

                          // Data da transação
                          _buildSectionLabel('Data', isDark),
                          const SizedBox(height: 8),
                          _buildDateSelector(isDark),
                          const SizedBox(height: 24),

                          // Data de vencimento (opcional)
                          _buildSectionLabel('Vencimento (opcional)', isDark),
                          const SizedBox(height: 8),
                          _buildDueDateSelector(isDark),
                          const SizedBox(height: 24),

                          // Pago?
                          _buildPaidSwitch(isDark),
                          const SizedBox(height: 24),

                          // Notas (opcional)
                          _buildSectionLabel('Notas (opcional)', isDark),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _notesController,
                            hint: 'Observações adicionais...',
                            isDark: isDark,
                            icon: Icons.notes_rounded,
                            maxLines: 3,
                            maxLength: 200,
                          ),
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

  Widget _buildHeader(bool isDark) {
    final typeColor = _getTypeColor(_selectedType);
    final typeIcon = _getTypeIcon(_selectedType);
    final title = _selectedType == TransactionType.income
        ? 'Nova receita'
        : _selectedType == TransactionType.transfer
            ? 'Nova transferência'
            : 'Nova despesa';

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F5F8),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? typeColor.withValues(alpha: 0.1)
                : typeColor.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
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
              Icon(
                Icons.account_balance_rounded,
                size: 64,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma conta encontrada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crie uma conta primeiro para registrar transações.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : const Color(0xFFEEEEF2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: TransactionType.values.map((type) {
          final isSelected = type == _selectedType;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = type;
                  _selectedCategoryId = null; // Reset categoria ao trocar tipo
                  _transferAccountId = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _getTypeColor(type) : Colors.transparent,
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
                      type.label,
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
        border: Border.all(
          color: typeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            _selectedType == TransactionType.income
                ? 'Quanto você recebeu?'
                : _selectedType == TransactionType.transfer
                    ? 'Quanto transferir?'
                    : 'Quanto você gastou?',
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
          ? (context, {required currentLength, required isFocused, required maxLength}) {
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
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 40 : 0),
          child: Icon(
            icon,
            color: isDark ? Colors.white38 : AppColors.textTertiary,
            size: 22,
          ),
        ),
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
          hint: Text(
            'Selecione uma conta',
            style: TextStyle(
              color: isDark ? Colors.white30 : AppColors.textDisabled,
              fontSize: 16,
            ),
          ),
          dropdownColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          items: _accounts
              .map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedAccountId = v),
        ),
      ),
    );
  }

  Widget _buildTransferAccountDropdown(bool isDark) {
    final availableAccounts =
        _accounts.where((a) => a.id != _selectedAccountId).toList();

    return _buildDropdownContainer(
      isDark: isDark,
      icon: Icons.arrow_forward_rounded,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _transferAccountId,
          isExpanded: true,
          hint: Text(
            'Selecione a conta destino',
            style: TextStyle(
              color: isDark ? Colors.white30 : AppColors.textDisabled,
              fontSize: 16,
            ),
          ),
          dropdownColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          items: availableAccounts
              .map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _transferAccountId = v),
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
          hint: Text(
            'Sem categoria',
            style: TextStyle(
              color: isDark ? Colors.white30 : AppColors.textDisabled,
              fontSize: 16,
            ),
          ),
          dropdownColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'Sem categoria',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.textTertiary,
                ),
              ),
            ),
            ...cats.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )),
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
          Icon(
            icon,
            color: isDark ? Colors.white38 : AppColors.textTertiary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDateSelector(bool isDark) {
    return _buildDateButton(
      isDark: isDark,
      label: _formatDate(_transactionDate),
      icon: Icons.calendar_today_rounded,
      onTap: () => _pickDate(),
    );
  }

  Widget _buildDueDateSelector(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildDateButton(
            isDark: isDark,
            label: _dueDate != null ? _formatDate(_dueDate!) : 'Não definido',
            icon: Icons.event_rounded,
            onTap: () => _pickDate(isDueDate: true),
            isPlaceholder: _dueDate == null,
          ),
        ),
        if (_dueDate != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _dueDate = null),
            child: Container(
              width: 48,
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF2D2D44) : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.close_rounded,
                color: isDark ? Colors.white38 : AppColors.textTertiary,
                size: 20,
              ),
            ),
          ),
        ],
      ],
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
            Icon(
              icon,
              color: isDark ? Colors.white38 : AppColors.textTertiary,
              size: 22,
            ),
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

  Widget _buildPaidSwitch(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2D44) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isPaid
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: _isPaid
                ? AppColors.success
                : (isDark ? Colors.white38 : AppColors.textTertiary),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedType == TransactionType.income
                      ? 'Já recebido'
                      : 'Já pago',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  _selectedType == TransactionType.income
                      ? 'Marcar se já entrou na conta'
                      : 'Marcar se já saiu da conta',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isPaid,
            onChanged: (v) => setState(() => _isPaid = v),
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

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
            : Text(
                _selectedType == TransactionType.income
                    ? 'Registrar receita'
                    : _selectedType == TransactionType.transfer
                        ? 'Registrar transferência'
                        : 'Registrar despesa',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
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
