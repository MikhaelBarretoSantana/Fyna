import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fyna/core/themes/theme_colors.dart';

class RegisterStepPreferences extends StatefulWidget {
  final String selectedCurrency;
  final String selectedLocale;
  final String selectedTheme;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool budgetAlerts;
  final bool weeklySummary;
  final bool aiSuggestions;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onLocaleChanged;
  final ValueChanged<String> onThemeChanged;
  final ValueChanged<bool> onPushNotificationsChanged;
  final ValueChanged<bool> onEmailNotificationsChanged;
  final ValueChanged<bool> onBudgetAlertsChanged;
  final ValueChanged<bool> onWeeklySummaryChanged;
  final ValueChanged<bool> onAiSuggestionsChanged;

  const RegisterStepPreferences({
    super.key,
    required this.selectedCurrency,
    required this.selectedLocale,
    required this.selectedTheme,
    required this.pushNotifications,
    required this.emailNotifications,
    required this.budgetAlerts,
    required this.weeklySummary,
    required this.aiSuggestions,
    required this.onCurrencyChanged,
    required this.onLocaleChanged,
    required this.onThemeChanged,
    required this.onPushNotificationsChanged,
    required this.onEmailNotificationsChanged,
    required this.onBudgetAlertsChanged,
    required this.onWeeklySummaryChanged,
    required this.onAiSuggestionsChanged,
  });

  @override
  State<RegisterStepPreferences> createState() =>
      _RegisterStepPreferencesState();
}

class _RegisterStepPreferencesState extends State<RegisterStepPreferences> {
  static const _currencies = [
    {'code': 'BRL', 'label': 'Real (R\$)', 'symbol': 'R\$'},
    {'code': 'USD', 'label': 'Dólar (US\$)', 'symbol': 'US\$'},
    {'code': 'EUR', 'label': 'Euro (€)', 'symbol': '€'},
    {'code': 'GBP', 'label': 'Libra (£)', 'symbol': '£'},
  ];

  static const _locales = [
    {'code': 'pt-BR', 'label': 'Português (Brasil)'},
    {'code': 'en-US', 'label': 'English (US)'},
    {'code': 'es-ES', 'label': 'Español'},
  ];

  static const _themes = [
    {'code': 'SYSTEM', 'label': 'Sistema', 'icon': Icons.settings_suggest_outlined},
    {'code': 'LIGHT', 'label': 'Claro', 'icon': Icons.light_mode_outlined},
    {'code': 'DARK', 'label': 'Escuro', 'icon': Icons.dark_mode_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step title
        _buildStepTitle(),

        const SizedBox(height: 24),

        // Theme selection
        _buildSectionLabel('Aparência'),
        const SizedBox(height: 12),
        _buildThemeSelector(),

        const SizedBox(height: 24),

        // Currency & Locale row
        _buildSectionLabel('Regional'),
        const SizedBox(height: 12),
        _buildGlassDropdown(
          label: 'Moeda',
          icon: Icons.attach_money_rounded,
          value: widget.selectedCurrency,
          items: _currencies
              .map((c) => DropdownMenuItem(
                    value: c['code'] as String,
                    child: Text(c['label'] as String),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) widget.onCurrencyChanged(val);
          },
        ),

        const SizedBox(height: 12),

        _buildGlassDropdown(
          label: 'Idioma',
          icon: Icons.language_rounded,
          value: widget.selectedLocale,
          items: _locales
              .map((l) => DropdownMenuItem(
                    value: l['code'] as String,
                    child: Text(l['label'] as String),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) widget.onLocaleChanged(val);
          },
        ),

        const SizedBox(height: 24),

        // Notifications
        _buildSectionLabel('Notificações'),
        const SizedBox(height: 12),
        _buildGlassSwitch(
          title: 'Notificações push',
          subtitle: 'Receba alertas em tempo real',
          icon: Icons.notifications_outlined,
          value: widget.pushNotifications,
          onChanged: widget.onPushNotificationsChanged,
        ),
        const SizedBox(height: 8),
        _buildGlassSwitch(
          title: 'E-mails',
          subtitle: 'Resumos e atualizações por e-mail',
          icon: Icons.email_outlined,
          value: widget.emailNotifications,
          onChanged: widget.onEmailNotificationsChanged,
        ),
        const SizedBox(height: 8),
        _buildGlassSwitch(
          title: 'Alertas de orçamento',
          subtitle: 'Aviso ao se aproximar do limite',
          icon: Icons.account_balance_wallet_outlined,
          value: widget.budgetAlerts,
          onChanged: widget.onBudgetAlertsChanged,
        ),
        const SizedBox(height: 8),
        _buildGlassSwitch(
          title: 'Resumo semanal',
          subtitle: 'Relatório automático toda semana',
          icon: Icons.summarize_outlined,
          value: widget.weeklySummary,
          onChanged: widget.onWeeklySummaryChanged,
        ),
        const SizedBox(height: 8),
        _buildGlassSwitch(
          title: 'Sugestões de IA',
          subtitle: 'Dicas personalizadas de economia',
          icon: Icons.auto_awesome_outlined,
          value: widget.aiSuggestions,
          onChanged: widget.onAiSuggestionsChanged,
        ),
      ],
    );
  }

  Widget _buildStepTitle() {
    final tc = ThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferências',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: tc.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Personalize sua experiência no Fyna.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: tc.textTertiary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    final tc = ThemeColors.of(context);
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: tc.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildThemeSelector() {
    final tc = ThemeColors.of(context);
    return Row(
      children: _themes.map((theme) {
        final isSelected = widget.selectedTheme == theme['code'];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: theme != _themes.last ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => widget.onThemeChanged(theme['code'] as String),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tc.accent.withValues(alpha: 0.2)
                          : tc.glass,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? tc.accent.withValues(alpha: 0.6)
                            : tc.glassBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          theme['icon'] as IconData,
                          color: isSelected
                              ? tc.accentLight
                              : tc.textTertiary,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          theme['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? tc.textPrimary
                                : tc.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGlassDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final tc = ThemeColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: tc.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: tc.glassBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: tc.textTertiary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    items: items,
                    onChanged: onChanged,
                    isExpanded: true,
                    dropdownColor: tc.dropdownBg,
                    style: TextStyle(
                      color: tc.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: tc.textMuted,
                    ),
                    hint: Text(
                      label,
                      style: TextStyle(
                        color: tc.textMuted,
                        fontSize: 15,
                      ),
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

  Widget _buildGlassSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final tc = ThemeColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: tc.glass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: tc.glassBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: value
                      ? tc.accent.withValues(alpha: 0.15)
                      : tc.glassOverlay,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: value
                      ? tc.accentLight
                      : tc.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tc.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: tc.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: tc.switchActive,
                activeTrackColor: tc.switchActiveTrack,
                inactiveThumbColor: tc.switchInactiveThumb,
                inactiveTrackColor: tc.switchInactiveTrack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
