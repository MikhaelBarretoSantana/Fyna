import 'package:flutter/material.dart';
import 'package:fyna/core/constants/app_colors.dart';

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
  int _priority = 1;
  int _selectedColorIndex = 0;
  bool _isSubmitting = false;

  static const List<Color> _colors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.success,
    AppColors.info,
    AppColors.warning,
    AppColors.error,
    AppColors.categoryTravel,
    AppColors.categoryEntertainment,
    AppColors.categoryEducation,
    AppColors.categoryShopping,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F5F8),
      appBar: AppBar(
        title: const Text('Nova Meta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview card
              _buildPreviewCard(isDark),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: 'Nome da meta',
                hint: 'Ex: Viagem para Europa',
                isDark: isDark,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Descrição (opcional)',
                hint: 'Detalhes sobre essa meta',
                isDark: isDark,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _targetController,
                label: 'Valor da meta',
                hint: 'R\$ 0,00',
                isDark: isDark,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o valor' : null,
              ),
              const SizedBox(height: 16),
              _buildDatePicker(isDark),
              const SizedBox(height: 16),
              _buildPriority(isDark),
              const SizedBox(height: 16),
              _buildColorPicker(isDark),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.darkAccent : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
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
                      : const Text(
                          'Criar meta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  Widget _buildPreviewCard(bool isDark) {
    final color = _colors[_selectedColorIndex];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag_rounded, color: Colors.white54, size: 32),
          const SizedBox(height: 12),
          Text(
            _nameController.text.isEmpty
                ? 'Nome da meta'
                : _nameController.text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _targetController.text.isEmpty
                ? 'R\$ 0,00'
                : 'R\$ ${_targetController.text}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF14142A) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF252540)
                    : const Color(0xFFEEEEF2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF252540)
                    : const Color(0xFFEEEEF2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color:
                    isDark ? AppColors.darkAccent : AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prazo (opcional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  _targetDate ?? DateTime.now().add(const Duration(days: 90)),
              firstDate: DateTime.now(),
              lastDate: DateTime(2035),
            );
            if (picked != null) setState(() => _targetDate = picked);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF14142A) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF252540)
                    : const Color(0xFFEEEEF2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
                const SizedBox(width: 8),
                Text(
                  _targetDate != null
                      ? '${_targetDate!.day.toString().padLeft(2, '0')}/${_targetDate!.month.toString().padLeft(2, '0')}/${_targetDate!.year}'
                      : 'Selecionar data',
                  style: TextStyle(
                    fontSize: 15,
                    color: _targetDate != null
                        ? (isDark ? Colors.white : AppColors.textPrimary)
                        : (isDark ? Colors.white24 : Colors.black26),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriority(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prioridade',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final value = index + 1;
            final isSelected = _priority == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _priority = value),
                child: Container(
                  margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? AppColors.darkAccent
                            : AppColors.primary)
                        : (isDark
                            ? const Color(0xFF14142A)
                            : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark
                              ? const Color(0xFF252540)
                              : const Color(0xFFEEEEF2)),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white38 : Colors.black45),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildColorPicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cor',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_colors.length, (index) {
            final isSelected = _selectedColorIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedColorIndex = index),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _colors[index],
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _colors[index].withValues(alpha: 0.4),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 20)
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // TODO: Chamar API para criar meta
      Navigator.pop(context, true);
    }
  }
}
