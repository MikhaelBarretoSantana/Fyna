import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/enums/goal_priority.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_screen_header.dart';
import 'package:fyna/core/widgets/create_amount_hero.dart';
import 'package:fyna/core/widgets/create_form_field_tile.dart';
import 'package:intl/intl.dart';

class CreateGoalPage extends StatefulWidget {
  const CreateGoalPage({super.key});

  @override
  State<CreateGoalPage> createState() => _CreateGoalPageState();
}

class _CreateGoalPageState extends State<CreateGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();

  DateTime? _targetDate;
  GoalPriority _priority = GoalPriority.MEDIUM;
  int _selectedColorIndex = 6; // default lavanda (combina com o hero do design)
  bool _isSubmitting = false;

  static const List<Color> _colors = [
    Color(0xFFA48BFF), // lavanda (design)
    Color(0xFF1A6F82), // teal
    Color(0xFF12A36A), // verde
    Color(0xFF3D77D6), // azul
    Color(0xFFE89A2E), // laranja
    Color(0xFFE53E3E), // vermelho
    Color(0xFFAA96DA), // travel
    Color(0xFFCB9416), // entertainment
    Color(0xFF7BA9F0), // education
    Color(0xFFF38181), // shopping
  ];

  static const List<String> _colorHex = [
    '#A48BFF',
    '#1A6F82',
    '#12A36A',
    '#3D77D6',
    '#E89A2E',
    '#E53E3E',
    '#AA96DA',
    '#CB9416',
    '#7BA9F0',
    '#F38181',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
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
                (HSLColor.fromColor(_selectedColor).lightness - 0.12)
                    .clamp(0.0, 1.0),
              )
              .toColor(),
        ],
      );

  Future<void> _pickDate() async {
    final tc = ThemeColors.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _selectedColor,
            brightness: tc.isDark ? Brightness.dark : Brightness.light,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = parseBrlAmount(_targetController.text);
    if (amount == null || amount <= 0) {
      _showError('Valor da meta inválido');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await Injection.instance.goalRepository.createGoal(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        targetAmount: amount,
        targetDate: _targetDate,
        color: _colorHex[_selectedColorIndex],
        priority: _priority.toJson(),
      );
      if (mounted) Navigator.pop(context, true);
    } on ServerException catch (e) {
      _showError(e.message);
    } on NetworkException {
      _showError('Sem conexão com a internet');
    } catch (_) {
      _showError('Erro ao criar meta');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

  String _monthsUntil(DateTime date) {
    final now = DateTime.now();
    final months =
        (date.year - now.year) * 12 + (date.month - now.month);
    if (months <= 0) return 'data inválida';
    if (months == 1) return '1 mês';
    if (months < 12) return '$months meses';
    final years = months ~/ 12;
    final remaining = months % 12;
    if (remaining == 0) return years == 1 ? '1 ano' : '$years anos';
    return '$years a${years > 1 ? 'nos' : 'no'} e $remaining ${remaining == 1 ? 'mês' : 'meses'}';
  }

  String _monthlySavings(double target) {
    if (_targetDate == null) return '';
    final now = DateTime.now();
    final months =
        (_targetDate!.year - now.year) * 12 + (_targetDate!.month - now.month);
    if (months <= 0) return '';
    final perMonth = target / months;
    final f = perMonth.toStringAsFixed(2).replaceAll('.', ',');
    final parts = f.split(',');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '~R\$ $intPart,${parts[1]}/mês';
  }

  String _priorityLabel() {
    switch (_priority) {
      case GoalPriority.HIGH:
        return 'ALTA PRIORIDADE';
      case GoalPriority.MEDIUM:
        return 'MÉDIA PRIORIDADE';
      case GoalPriority.LOW:
        return 'BAIXA PRIORIDADE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final target = parseBrlAmount(_targetController.text) ?? 0;

    return Scaffold(
      backgroundColor: tc.neoBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: 'Nova meta',
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
                        icon: Icons.flag_outlined,
                        label: 'Nome da meta',
                        controller: _nameController,
                        hint: 'Ex: Viagem Portugal',
                        maxLength: 100,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o nome'
                            : null,
                        autofocus: true,
                      ),
                      const SizedBox(height: 10),
                      CreateInlineTextField(
                        icon: Icons.notes_outlined,
                        label: 'Descrição (opcional)',
                        controller: _descriptionController,
                        hint: 'Detalhes sobre essa meta',
                        maxLength: 200,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10),
                      CreateInlineTextField(
                        icon: Icons.attach_money_rounded,
                        label: 'Valor da meta',
                        controller: _targetController,
                        hint: '0,00',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          final value = parseBrlAmount(v ?? '');
                          if (value == null || value <= 0) {
                            return 'Valor inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      CreateFormFieldTile(
                        icon: Icons.event_outlined,
                        label: 'Data alvo',
                        value: _targetDate != null
                            ? DateFormat("dd MMMM yyyy", 'pt_BR')
                                .format(_targetDate!)
                            : null,
                        hint: 'Selecionar (opcional)',
                        onTap: _pickDate,
                      ),
                      if (_targetDate != null && target > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                          child: Text(
                            'Você tem ${_monthsUntil(_targetDate!)} · ${_monthlySavings(target)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: tc.neoTextMuted,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      _sectionLabel(tc, 'PRIORIDADE'),
                      const SizedBox(height: 8),
                      _buildPriorityRow(tc),
                      const SizedBox(height: 14),
                      _sectionLabel(tc, 'COR'),
                      const SizedBox(height: 8),
                      _buildColorRow(tc),
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
    final amount = parseBrlAmount(_targetController.text);
    final amountText = amount != null && amount > 0
        ? 'R\$ ${_fmtCurrencyValue(amount)}'
        : 'R\$ 0,00';

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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasName ? _nameController.text.trim() : 'Nome da meta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: hasName
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.55),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_descriptionController.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _descriptionController.text.trim(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'META',
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
                  amountText,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _priorityLabel(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
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

  Widget _buildPriorityRow(ThemeColors tc) {
    Widget chip(GoalPriority p, Color color, String label) {
      final selected = _priority == p;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _priority = p);
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? color : tc.neoCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : tc.neoCardBorder,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : tc.neoText,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(GoalPriority.LOW, tc.neoTextMuted, 'Baixa'),
        const SizedBox(width: 10),
        chip(GoalPriority.MEDIUM, tc.neoTeal, 'Média'),
        const SizedBox(width: 10),
        chip(GoalPriority.HIGH, tc.neoNegative, 'Alta'),
      ],
    );
  }

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

  Widget _buildCta(ThemeColors tc) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
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
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Criar meta'),
          ),
        ),
      ),
    );
  }

  String _fmtCurrencyValue(double v) {
    final f = v.toStringAsFixed(2).replaceAll('.', ',');
    final p = f.split(',');
    final i = p[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$i,${p[1]}';
  }
}
