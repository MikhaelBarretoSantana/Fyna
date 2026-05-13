import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/enums/account_types.dart';
import 'package:fyna/core/errors/exceptions.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _balanceController = TextEditingController(text: '0,00');

  AccountTypes _selectedType = AccountTypes.checking;
  String _selectedColor = '#1A7B8C';
  bool _includeInTotal = true;
  bool _isLoading = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  // Cores disponíveis para a conta
  static const List<Map<String, dynamic>> _colorOptions = [
    {'hex': '#1A7B8C', 'color': Color(0xFF1A7B8C), 'name': 'Teal'},
    {'hex': '#0D4F6E', 'color': Color(0xFF0D4F6E), 'name': 'Azul Escuro'},
    {'hex': '#2BA3A8', 'color': Color(0xFF2BA3A8), 'name': 'Ciano'},
    {'hex': '#00D4AA', 'color': Color(0xFF00D4AA), 'name': 'Verde'},
    {'hex': '#FF6B6B', 'color': Color(0xFFFF6B6B), 'name': 'Vermelho'},
    {'hex': '#FFB300', 'color': Color(0xFFFFB300), 'name': 'Amarelo'},
    {'hex': '#7C83FD', 'color': Color(0xFF7C83FD), 'name': 'Roxo'},
    {'hex': '#FF9800', 'color': Color(0xFFFF9800), 'name': 'Laranja'},
    {'hex': '#E91E63', 'color': Color(0xFFE91E63), 'name': 'Rosa'},
    {'hex': '#4CAF50', 'color': Color(0xFF4CAF50), 'name': 'Verde Claro'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _institutionController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final balanceText = _balanceController.text
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final balance = double.tryParse(balanceText) ?? 0.0;

      await Injection.instance.accountRepository.createAccount(
        name: _nameController.text.trim(),
        type: _selectedType.toJson(),
        institution: _institutionController.text.trim().isNotEmpty
            ? _institutionController.text.trim()
            : null,
        color: _selectedColor,
        icon: _getIconForType(_selectedType),
        initialBalance: balance,
        includeInTotal: _includeInTotal,
      );

      if (mounted) {
        Navigator.pop(context, true); // true = conta criada com sucesso
      }
    } on ServerException catch (e) {
      _showError(e.message);
    } on NetworkException {
      _showError('Sem conexão com a internet');
    } on TimeoutException {
      _showError('A requisição demorou demais. Tente novamente.');
    } catch (_) {
      _showError('Erro inesperado ao criar conta');
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

  String _getIconForType(AccountTypes type) {
    switch (type) {
      case AccountTypes.checking:
        return 'account_balance';
      case AccountTypes.savings:
        return 'savings';
      case AccountTypes.creditCard:
        return 'credit_card';
      case AccountTypes.cash:
        return 'payments';
      case AccountTypes.investment:
        return 'trending_up';
      case AccountTypes.digitalWallet:
        return 'account_balance_wallet';
      case AccountTypes.other:
        return 'account_balance';
    }
  }

  IconData _getIconDataForType(AccountTypes type) {
    switch (type) {
      case AccountTypes.checking:
        return Icons.account_balance_rounded;
      case AccountTypes.savings:
        return Icons.savings_rounded;
      case AccountTypes.creditCard:
        return Icons.credit_card_rounded;
      case AccountTypes.cash:
        return Icons.payments_rounded;
      case AccountTypes.investment:
        return Icons.trending_up_rounded;
      case AccountTypes.digitalWallet:
        return Icons.account_balance_wallet_rounded;
      case AccountTypes.other:
        return Icons.account_balance_rounded;
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Preview card
                        _buildPreviewCard(isDark),
                        const SizedBox(height: 28),

                        // Nome da conta
                        _buildSectionLabel('Nome da conta', isDark),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameController,
                          hint: 'Ex: Nubank, Itaú, Carteira...',
                          isDark: isDark,
                          icon: Icons.edit_rounded,
                          maxLength: 50,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Informe o nome da conta';
                            }
                            if (v.trim().length > 50) {
                              return 'Máximo de 50 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Tipo de conta
                        _buildSectionLabel('Tipo de conta', isDark),
                        const SizedBox(height: 10),
                        _buildAccountTypeSelector(isDark),
                        const SizedBox(height: 24),

                        // Instituição
                        _buildSectionLabel('Instituição (opcional)', isDark),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _institutionController,
                          hint: 'Ex: Banco do Brasil, Caixa...',
                          isDark: isDark,
                          icon: Icons.business_rounded,
                          maxLength: 60,
                        ),
                        const SizedBox(height: 24),

                        // Saldo inicial
                        _buildSectionLabel('Saldo inicial', isDark),
                        const SizedBox(height: 8),
                        _buildBalanceField(isDark),
                        const SizedBox(height: 24),

                        // Cor
                        _buildSectionLabel('Cor', isDark),
                        const SizedBox(height: 10),
                        _buildColorSelector(isDark),
                        const SizedBox(height: 24),

                        // Incluir no total
                        _buildIncludeInTotalSwitch(isDark),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
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
          Text(
            'Nova conta',
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

  Widget _buildPreviewCard(bool isDark) {
    final selectedColorObj = _colorOptions.firstWhere(
      (c) => c['hex'] == _selectedColor,
      orElse: () => _colorOptions.first,
    );
    final previewColor = selectedColorObj['color'] as Color;
    final name = _nameController.text.trim();
    final balanceText = _balanceController.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            previewColor,
            previewColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: previewColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconDataForType(_selectedType),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Nome da conta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(
                            alpha: name.isNotEmpty ? 1 : 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _selectedType.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Saldo inicial',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'R\$ $balanceText',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
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
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLength: maxLength,
      onChanged: (_) => setState(() {}), // Atualiza preview
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
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white38 : AppColors.textTertiary,
          size: 22,
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

  Widget _buildAccountTypeSelector(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AccountTypes.values.map((type) {
        final isSelected = type == _selectedType;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? AppColors.darkAccent.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.1))
                  : (isDark ? const Color(0xFF1C1C2E) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (isDark ? AppColors.darkAccent : AppColors.primary)
                    : (isDark
                        ? const Color(0xFF2D2D44)
                        : AppColors.border),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconDataForType(type),
                  size: 18,
                  color: isSelected
                      ? (isDark ? AppColors.darkAccent : AppColors.primary)
                      : (isDark ? Colors.white54 : AppColors.textTertiary),
                ),
                const SizedBox(width: 8),
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? (isDark ? AppColors.darkAccent : AppColors.primary)
                        : (isDark ? Colors.white70 : AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBalanceField(bool isDark) {
    return TextFormField(
      controller: _balanceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_CurrencyInputFormatter()],
      onChanged: (_) => setState(() {}), // Atualiza preview
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        prefixText: 'R\$ ',
        prefixStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white54 : AppColors.textTertiary,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      ),
    );
  }

  Widget _buildColorSelector(bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _colorOptions.map((option) {
        final color = option['color'] as Color;
        final hex = option['hex'] as String;
        final isSelected = hex == _selectedColor;

        return GestureDetector(
          onTap: () => setState(() => _selectedColor = hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.textPrimary)
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIncludeInTotalSwitch(bool isDark) {
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
            Icons.calculate_rounded,
            color: isDark ? Colors.white54 : AppColors.textTertiary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incluir no saldo total',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Considerar esta conta no cálculo geral',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _includeInTotal,
            onChanged: (v) => setState(() => _includeInTotal = v),
            activeColor: isDark ? AppColors.darkAccent : AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCreate,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.darkAccent : AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              (isDark ? AppColors.darkAccent : AppColors.primary)
                  .withValues(alpha: 0.5),
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
            : const Text(
                'Criar conta',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Formata entrada numérica como moeda brasileira (ex: 1.234,56).
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove tudo que não é dígito
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '0,00',
        selection: TextSelection.collapsed(offset: 4),
      );
    }

    // Garante pelo menos 3 dígitos (para ter centavos)
    while (digitsOnly.length < 3) {
      digitsOnly = '0$digitsOnly';
    }

    // Separa inteiro e decimais
    final intPart = digitsOnly.substring(0, digitsOnly.length - 2);
    final decPart = digitsOnly.substring(digitsOnly.length - 2);

    // Remove zeros à esquerda do inteiro (mantém pelo menos um)
    final cleanInt = intPart.replaceFirst(RegExp(r'^0+'), '');
    final finalInt = cleanInt.isEmpty ? '0' : cleanInt;

    // Adiciona separador de milhar
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
