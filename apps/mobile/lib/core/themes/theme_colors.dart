// lib/core/themes/theme_colors.dart

import 'package:flutter/material.dart';
import 'package:fyna/core/constants/app_colors.dart';

/// Helper que resolve cores de acordo com o brilho do tema atual.
///
/// Usa [Theme.of(context).brightness] para decidir se retorna
/// a variante light ou dark de cada cor.
///
/// Exemplo de uso:
/// ```dart
/// final tc = ThemeColors.of(context);
/// Container(
///   decoration: BoxDecoration(gradient: tc.backgroundGradient),
///   child: Text('Olá', style: TextStyle(color: tc.textPrimary)),
/// );
/// ```
class ThemeColors {
  final Brightness brightness;

  const ThemeColors._(this.brightness);

  /// Cria uma instância baseada no tema atual.
  factory ThemeColors.of(BuildContext context) {
    return ThemeColors._(Theme.of(context).brightness);
  }

  bool get isDark => brightness == Brightness.dark;

  // ============================================
  // GRADIENTS
  // ============================================

  /// Gradiente de fundo das telas de auth (welcome/login/register)
  LinearGradient get backgroundGradient =>
      isDark ? AppColors.welcomeGradientDark : AppColors.welcomeGradient;

  /// Gradiente do drawer
  LinearGradient get drawerGradient =>
      isDark ? AppColors.drawerGradientDark : AppColors.drawerGradient;

  // ============================================
  // TEXT
  // ============================================

  /// Cor principal de texto (títulos, body)
  Color get textPrimary =>
      isDark ? AppColors.textPrimaryDark : Colors.white;

  /// Texto secundário (subtítulos, dicas)
  Color get textSecondary =>
      isDark
          ? AppColors.textSecondaryDark
          : Colors.white.withValues(alpha: 0.85);

  /// Texto terciário / placeholders
  Color get textTertiary =>
      isDark
          ? AppColors.textTertiaryDark
          : Colors.white.withValues(alpha: 0.7);

  /// Texto com opacidade leve (labels de seção)
  Color get textMuted =>
      isDark
          ? Colors.white.withValues(alpha: 0.45)
          : Colors.white.withValues(alpha: 0.55);

  // ============================================
  // GLASS / MORPHISM
  // ============================================

  /// Fundo de containers glass
  Color get glass =>
      isDark ? AppColors.darkGlassWhite : AppColors.glassWhite;

  /// Borda de containers glass
  Color get glassBorder =>
      isDark ? AppColors.darkGlassBorder : AppColors.glassBorder;

  /// Overlay glass (mais sutil)
  Color get glassOverlay =>
      isDark ? AppColors.darkGlassOverlay : AppColors.glassOverlay;

  // ============================================
  // DECORATIVE
  // ============================================

  /// Efeito radial decorativo - tons claros
  Color get decorCircleLight =>
      isDark
          ? AppColors.darkPrimaryLighter.withValues(alpha: 0.12)
          : AppColors.primaryLightest.withValues(alpha: 0.2);

  /// Efeito radial decorativo - tons escuros
  Color get decorCircleDark =>
      isDark
          ? AppColors.darkPrimary.withValues(alpha: 0.35)
          : AppColors.primaryDark.withValues(alpha: 0.5);

  /// Efeito radial accent
  Color get decorCircleAccent =>
      isDark
          ? AppColors.darkAccent.withValues(alpha: 0.06)
          : AppColors.accent.withValues(alpha: 0.08);

  // ============================================
  // BUTTONS
  // ============================================

  /// Botão primário - fundo
  Color get primaryButtonBg =>
      isDark ? AppColors.darkAccent : Colors.white;

  /// Botão primário - texto
  Color get primaryButtonText =>
      isDark ? Colors.white : AppColors.primaryDark;

  /// Botão primário - sombra
  Color get primaryButtonShadow =>
      isDark
          ? AppColors.darkAccent.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.15);

  // ============================================
  // SEMANTIC
  // ============================================

  /// Cor de sucesso
  Color get success => isDark ? AppColors.darkSuccess : AppColors.success;

  /// Cor de erro
  Color get error => isDark ? AppColors.darkError : AppColors.error;

  /// Cor de warning
  Color get warning => isDark ? AppColors.darkWarning : AppColors.warning;

  /// Cor informativa
  Color get info => isDark ? AppColors.darkInfo : AppColors.info;

  // ============================================
  // ACCENT
  // ============================================

  /// Accent principal
  Color get accent => isDark ? AppColors.darkAccent : AppColors.accent;

  /// Accent claro
  Color get accentLight =>
      isDark ? AppColors.darkAccentLight : AppColors.accentLight;

  // ============================================
  // SURFACES
  // ============================================

  /// Superfície de cards e containers (fora das telas de auth)
  Color get surface =>
      isDark ? AppColors.surfaceDark : AppColors.surface;

  /// Background de telas de conteúdo (fora das telas de auth)
  Color get background =>
      isDark ? AppColors.backgroundDark : AppColors.background;

  /// Cor primária do app
  Color get primary =>
      isDark ? AppColors.darkPrimary : AppColors.primary;

  /// Borda padrão
  Color get border =>
      isDark ? AppColors.borderDark : AppColors.border;

  /// Dropdown background
  Color get dropdownBg =>
      isDark ? AppColors.darkSurface2 : const Color(0xFF1A3A4A);

  /// Step indicator ativo
  Color get stepActive =>
      isDark ? AppColors.darkAccent : Colors.white;

  /// Step indicator completo
  Color get stepCompleted =>
      isDark ? AppColors.darkAccentLight : AppColors.accent;

  /// Step indicator inativo
  Color get stepInactive =>
      isDark
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.white.withValues(alpha: 0.25);

  /// Step glow
  Color get stepGlow =>
      isDark
          ? AppColors.darkAccent.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.3);

  // ============================================
  // SWITCH
  // ============================================

  /// Switch ativo cor
  Color get switchActive => isDark ? AppColors.darkAccent : AppColors.accent;

  /// Switch ativo track
  Color get switchActiveTrack =>
      isDark
          ? AppColors.darkAccent.withValues(alpha: 0.3)
          : AppColors.accent.withValues(alpha: 0.3);

  /// Switch inativo thumb
  Color get switchInactiveThumb =>
      Colors.white.withValues(alpha: 0.6);

  /// Switch inativo track
  Color get switchInactiveTrack =>
      Colors.white.withValues(alpha: 0.15);

  // ============================================
  // NEO DESIGN (telas com fundo claro + cards brancos)
  // ============================================

  /// Background neutro das telas de conteúdo (Home, Transações, etc.)
  /// Tom off-white levemente acinzentado para que cards brancos se destaquem.
  Color get neoBackground =>
      isDark ? const Color(0xFF0A0F1A) : const Color(0xFFF4F5F7);

  /// Fundo de cards principais (brancos sobre o neoBackground)
  Color get neoCard =>
      isDark ? const Color(0xFF161B2A) : Colors.white;

  /// Variação mais elevada (bottom sheets, dialogs)
  Color get neoCardElevated =>
      isDark ? const Color(0xFF1E2436) : Colors.white;

  /// Borda muito sutil em cards brancos
  Color get neoCardBorder => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.04);

  /// Sombra padrão de cards brancos
  Color get neoCardShadow => isDark
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.black.withValues(alpha: 0.04);

  /// Texto principal sobre fundo claro (não sobre gradiente)
  Color get neoText => isDark
      ? const Color(0xFFF1F3F8)
      : const Color(0xFF0F172A);

  /// Texto secundário sobre fundo claro
  Color get neoTextMuted => isDark
      ? const Color(0xFF9CA6B8)
      : const Color(0xFF6B7280);

  /// Texto terciário/legenda
  Color get neoTextFaint => isDark
      ? const Color(0xFF6B7280)
      : const Color(0xFF9CA3AF);

  /// Cor do FAB / accent teal do app (não confundir com onboarding)
  Color get neoTeal => isDark
      ? const Color(0xFF1F7A8C)
      : const Color(0xFF1A6F82);

  /// Gradiente "Hero" — usado em saldo, patrimônio, saúde financeira, etc.
  /// Tom teal escuro com leve highlight no canto superior direito.
  LinearGradient get heroGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF12303C),
            Color(0xFF0C1F28),
          ],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F6E80),
            Color(0xFF0E3D4A),
          ],
        );

  /// Gradiente de pill ativa (tabs selecionados)
  LinearGradient get pillActiveGradient => isDark
      ? const LinearGradient(
          colors: [Color(0xFF1F7A8C), Color(0xFF0F4E5E)],
        )
      : const LinearGradient(
          colors: [Color(0xFF1A6F82), Color(0xFF0F4859)],
        );

  /// Fundo de pill inativa
  Color get pillInactiveBg => isDark
      ? const Color(0xFF1E2436)
      : Colors.white;

  /// Borda de pill inativa
  Color get pillInactiveBorder => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.06);

  /// Verde de valores positivos (receitas)
  Color get neoPositive => isDark
      ? const Color(0xFF22C788)
      : const Color(0xFF12A36A);

  /// Vermelho de valores negativos (despesas)
  Color get neoNegative => isDark
      ? const Color(0xFFFF6B6B)
      : const Color(0xFFE53E3E);

  /// Amarelo de alerta (warning suave)
  Color get neoAttention => isDark
      ? const Color(0xFFFFB84D)
      : const Color(0xFFE89A2E);

  /// Roxo de IA (insights, sugestões)
  Color get neoAi => isDark
      ? const Color(0xFFA48BFF)
      : const Color(0xFF7C5CFC);

  // ============================================
  // CATEGORY BADGES (fundo pastel + ícone saturado)
  // ============================================

  /// Mapa de "tom" semântico para par (background, foreground) do badge.
  /// `tone` aceita: food, transport, entertainment, shopping, health, bills,
  /// salary, transfer, ai, info, success, warning, danger, neutral.
  ({Color bg, Color fg}) badge(String tone) {
    final pastels = isDark ? _badgePastelsDark : _badgePastelsLight;
    return pastels[tone] ?? pastels['neutral']!;
  }

  static const Map<String, ({Color bg, Color fg})> _badgePastelsLight = {
    'food':           (bg: Color(0xFFFFE5E0), fg: Color(0xFFE85D4A)),
    'transport':      (bg: Color(0xFFDFF6F2), fg: Color(0xFF12A892)),
    'entertainment':  (bg: Color(0xFFFFF4D6), fg: Color(0xFFCB9416)),
    'shopping':       (bg: Color(0xFFEAE6FB), fg: Color(0xFF7C5CFC)),
    'health':         (bg: Color(0xFFE3F4E8), fg: Color(0xFF2D9E60)),
    'bills':          (bg: Color(0xFFE6EEFA), fg: Color(0xFF3D77D6)),
    'salary':         (bg: Color(0xFFFFF4D6), fg: Color(0xFFC9941C)),
    'transfer':       (bg: Color(0xFFE0EEF1), fg: Color(0xFF1F7A8C)),
    'ai':             (bg: Color(0xFFEEE9FF), fg: Color(0xFF7C5CFC)),
    'info':           (bg: Color(0xFFE6F0FB), fg: Color(0xFF3D77D6)),
    'success':        (bg: Color(0xFFDFF4E5), fg: Color(0xFF12A36A)),
    'warning':        (bg: Color(0xFFFFF1D6), fg: Color(0xFFCB8E16)),
    'danger':         (bg: Color(0xFFFFE3E0), fg: Color(0xFFE53E3E)),
    'neutral':        (bg: Color(0xFFEEF0F4), fg: Color(0xFF6B7280)),
  };

  static const Map<String, ({Color bg, Color fg})> _badgePastelsDark = {
    'food':           (bg: Color(0xFF3B1E1B), fg: Color(0xFFFF8F7E)),
    'transport':      (bg: Color(0xFF143430), fg: Color(0xFF4DD8B5)),
    'entertainment':  (bg: Color(0xFF3A2E10), fg: Color(0xFFFFC857)),
    'shopping':       (bg: Color(0xFF231C3F), fg: Color(0xFFA48BFF)),
    'health':         (bg: Color(0xFF143324), fg: Color(0xFF55D88A)),
    'bills':          (bg: Color(0xFF15233E), fg: Color(0xFF7BA9F0)),
    'salary':         (bg: Color(0xFF3A2E10), fg: Color(0xFFFFCA28)),
    'transfer':       (bg: Color(0xFF112A33), fg: Color(0xFF5BC4D8)),
    'ai':             (bg: Color(0xFF252040), fg: Color(0xFFB39DFF)),
    'info':           (bg: Color(0xFF15233E), fg: Color(0xFF7BA9F0)),
    'success':        (bg: Color(0xFF132E22), fg: Color(0xFF55D88A)),
    'warning':        (bg: Color(0xFF3A2C0E), fg: Color(0xFFFFC857)),
    'danger':         (bg: Color(0xFF3B1B1B), fg: Color(0xFFFF8585)),
    'neutral':        (bg: Color(0xFF1E2436), fg: Color(0xFF9CA6B8)),
  };
}
