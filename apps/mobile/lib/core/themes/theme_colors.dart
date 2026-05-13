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
}
