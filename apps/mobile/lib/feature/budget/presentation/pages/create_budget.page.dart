import 'package:flutter/material.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/enums/budget_period_type.dart';

class CreateBudgetPage extends StatefulWidget {
  const CreateBudgetPage({super.key});

  @override
  State<CreateBudgetPage> createState() => _CreateBudgetPageState();
}

class _CreateBudgetPageState extends State<CreateBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  final _thresholdController = TextEditingController(text: '80');

  BudgetPeriodType _periodType = BudgetPeriodType.MONTHLY;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _alertEnabled = true;
  String? _selectedCategoryId;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F5F8),
      appBar: AppBar(
        title: const Text('Novo Orçamento'),
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
              _buildTextField(
                controller: _nameController,
                label: 'Nome do orçamento',
                hint: 'Ex: Alimentação mensal',
                isDark: isDark,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _limitController,
                label: 'Valor limite',
                hint: 'R\$ 0,00',
                isDark: isDark,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o valor' : null,
              ),
              const SizedBox(height: 16),
              _buildDropdown(isDark),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Data início',
                      date: _startDate,
                      isDark: isDark,
                      onChanged: (d) => setState(() => _startDate = d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Data fim',
                      date: _endDate,
                      isDark: isDark,
                      onChanged: (d) => setState(() => _endDate = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildAlertSection(isDark),
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
                          'Criar orçamento',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
                color: isDark ? AppColors.darkAccent : AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Período',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14142A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF252540)
                  : const Color(0xFFEEEEF2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BudgetPeriodType>(
              value: _periodType,
              isExpanded: true,
              dropdownColor:
                  isDark ? const Color(0xFF1C1C2E) : Colors.white,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
              ),
              items: BudgetPeriodType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _periodType = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required bool isDark,
    required ValueChanged<DateTime> onChanged,
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
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14142A) : Colors.white,
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
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14142A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEF2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: isDark ? AppColors.darkAccent : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Alerta de orçamento',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Switch.adaptive(
                value: _alertEnabled,
                onChanged: (val) => setState(() => _alertEnabled = val),
                activeColor:
                    isDark ? AppColors.darkAccent : AppColors.primary,
              ),
            ],
          ),
          if (_alertEnabled) ...[
            const SizedBox(height: 12),
            _buildTextField(
              controller: _thresholdController,
              label: 'Limite de alerta (%)',
              hint: '80',
              isDark: isDark,
              keyboardType: TextInputType.number,
            ),
          ],
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // TODO: Chamar API para criar orçamento
      Navigator.pop(context, true);
    }
  }
}
