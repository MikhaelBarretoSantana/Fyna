import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/enums/account_types.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_screen_header.dart';
import 'package:fyna/core/widgets/create_amount_hero.dart';
import 'package:fyna/core/widgets/create_form_field_tile.dart';
import 'package:fyna/core/widgets/icon_badge.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _balanceController = TextEditingController();

  AccountTypes _selectedType = AccountTypes.checking;
  int _selectedColorIndex = 6; // roxo (design mostra Nubank roxo)
  bool _includeInTotal = true;
  bool _isLoading = false;

  static const List<Color> _colors = [
    Color(0xFF1A6F82), // teal
    Color(0xFF0E3D4A), // azul escuro
    Color(0xFF2BA3A8), // ciano
    Color(0xFF12A892), // verde água
    Color(0xFFFF6B6B), // vermelho
    Color(0xFFFFB300), // amarelo/laranja
    Color(0xFF8A4FFF), // roxo Nubank
    Color(0xFFE85D4A), // laranja
    Color(0xFFE91E63), // rosa
    Color(0xFF12A36A), // verde
  ];

  static const List<String> _colorHex = [
    '#1A6F82',
    '#0E3D4A',
    '#2BA3A8',
    '#12A892',
    '#FF6B6B',
    '#FFB300',
    '#8A4FFF',
    '#E85D4A',
    '#E91E63',
    '#12A36A',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Color get _selectedColor => _colors[_selectedColorIndex];

  LinearGradient get _heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _selectedColor,
          HSLColor.fromColor(_selectedColor)
              .withLightness(
                (HSLColor.fromColor(_selectedColor).lightness - 0.15)
                    .clamp(0.0, 1.0),
              )
              .toColor(),
        ],
      );

  IconData _iconForType(AccountTypes type) {
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

  String _iconNameForType(AccountTypes type) {
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

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    final balance = parseBrlAmount(_balanceController.text) ?? 0.0;

    setState(() => _isLoading = true);
    try {
      await Injection.instance.accountRepository.createAccount(
        name: _nameController.text.trim(),
        type: _selectedType.toJson(),
        institution: _institutionController.text.trim().isNotEmpty
            ? _institutionController.text.trim()
            : null,
        color: _colorHex[_selectedColorIndex],
        icon: _iconNameForType(_selectedType),
        initialBalance: balance,
        includeInTotal: _includeInTotal,
      );
      if (mounted) Navigator.pop(context, true);
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
    final tc = ThemeColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: tc.neoNegative,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTypePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      // Sem isScrollControlled, o modal padrão limita a ~50% da tela e os 7
      // tipos não cabem em aparelhos menores — quebrava o layout.
      isScrollControlled: true,
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
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
                  'Tipo de conta',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tc.neoText,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: AccountTypes.values.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final t = AccountTypes.values[i];
                      final selected = t == _selectedType;
                      return Material(
                        color: tc.neoCard,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => _selectedType = t);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? tc.neoTeal
                                    : tc.neoCardBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                IconBadge(
                                  icon: _iconForType(t),
                                  tone: 'transfer',
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    t.label,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: tc.neoText,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Icon(Icons.check_rounded,
                                      color: tc.neoTeal),
                              ],
                            ),
                          ),
                        ),
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
              title: 'Nova conta',
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
                      _buildHeroPreview(tc),
                      const SizedBox(height: 14),
                      CreateInlineTextField(
                        icon: Icons.edit_outlined,
                        label: 'Nome da conta',
                        controller: _nameController,
                        hint: 'Ex: Nubank',
                        maxLength: 60,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o nome'
                            : null,
                        autofocus: true,
                      ),
                      const SizedBox(height: 10),
                      CreateFormFieldTile(
                        icon: Icons.account_balance_outlined,
                        label: 'Tipo de conta',
                        value: _selectedType.label,
                        onTap: _showTypePicker,
                      ),
                      const SizedBox(height: 10),
                      CreateInlineTextField(
                        icon: Icons.business_outlined,
                        label: 'Instituição (opcional)',
                        controller: _institutionController,
                        hint: 'Ex: Nu Pagamentos S.A.',
                        maxLength: 80,
                      ),
                      const SizedBox(height: 10),
                      CreateInlineTextField(
                        icon: Icons.attach_money_rounded,
                        label: 'Saldo inicial',
                        controller: _balanceController,
                        hint: '0,00',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: 14),
                      _sectionLabel(tc, 'COR'),
                      const SizedBox(height: 8),
                      _buildColorRow(tc),
                      const SizedBox(height: 14),
                      _buildIncludeInTotalCard(tc),
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

  Widget _buildHeroPreview(ThemeColors tc) {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasInstitution = _institutionController.text.trim().isNotEmpty;
    final balance = parseBrlAmount(_balanceController.text);

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            gradient: _heroGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _selectedColor.withValues(alpha: 0.3),
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
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconForType(_selectedType),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasName ? _nameController.text.trim() : 'Nome da conta',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: hasName
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.55),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _selectedType.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'SALDO INICIAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  balance != null && balance != 0
                      ? 'R\$ ${_fmtMoney(balance)}'
                      : 'R\$ 0,00',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
              if (hasInstitution)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _institutionController.text.trim(),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: -10,
          top: -10,
          child: IgnorePointer(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
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

  Widget _buildColorRow(ThemeColors tc) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(_colors.length, (i) {
        final selected = i == _selectedColorIndex;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedColorIndex = i);
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _colors[i],
              borderRadius: BorderRadius.circular(12),
              border: selected ? Border.all(color: tc.neoText, width: 2.5) : null,
            ),
            child: selected
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 18)
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildIncludeInTotalCard(ThemeColors tc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: tc.neoCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.neoCardBorder),
      ),
      child: Row(
        children: [
          IconBadge(
            icon: Icons.account_balance_wallet_rounded,
            tone: 'info',
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incluir no patrimônio total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tc.neoText,
                  ),
                ),
                Text(
                  'Soma esta conta ao saldo agregado',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: tc.neoTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _includeInTotal,
            onChanged: (v) => setState(() => _includeInTotal = v),
            activeTrackColor: tc.neoTeal,
          ),
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
                : const Text('Criar conta'),
          ),
        ),
      ),
    );
  }

  String _fmtMoney(double v) {
    final f = v.toStringAsFixed(2).replaceAll('.', ',');
    final p = f.split(',');
    final i = p[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$i,${p[1]}';
  }
}
