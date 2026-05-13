// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

/// Paleta de cores do Finance AI App
/// 
/// Baseada em tons de teal/cyan que transmitem:
/// - Confiança e segurança (finanças)
/// - Inovação e tecnologia (IA)
/// - Tranquilidade e controle
abstract class AppColors {
  // ============================================
  // PRIMARY COLORS (Teal/Cyan)
  // ============================================
  
  /// Primary color principal - usado em elementos de destaque
  static const Color primary = Color(0xFF1A7B8C);
  
  /// Variações do primary
  static const Color primaryDark = Color(0xFF0D4F6E);
  static const Color primaryLight = Color(0xFF2BA3A8);
  static const Color primaryLighter = Color(0xFF5BC4BE);
  static const Color primaryLightest = Color(0xFF8DD8D3);
  
  // ============================================
  // SECONDARY COLORS (Accent)
  // ============================================
  
  /// Cor de destaque para CTAs e elementos importantes
  static const Color accent = Color(0xFF00D4AA);
  static const Color accentDark = Color(0xFF00B894);
  static const Color accentLight = Color(0xFF55EFC4);
  
  // ============================================
  // SEMANTIC COLORS
  // ============================================
  
  /// Sucesso - receitas, ganhos, positivo
  static const Color success = Color(0xFF00C853);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color successDark = Color(0xFF00962D);
  
  /// Erro - despesas altas, alertas críticos
  static const Color error = Color(0xFFFF5252);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFFD32F2F);
  
  /// Warning - alertas, atenção
  static const Color warning = Color(0xFFFFB300);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color warningDark = Color(0xFFFF8F00);
  
  /// Info - informações, dicas
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color infoDark = Color(0xFF1565C0);
  
  // ============================================
  // NEUTRAL COLORS
  // ============================================
  
  /// Backgrounds
  static const Color background = Color(0xFFF8FAFB);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  /// Cards
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2C2C2C);
  
  /// Text colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);
  
  /// Text colors (dark mode)
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFD1D5DB);
  static const Color textTertiaryDark = Color(0xFF9CA3AF);
  
  /// Borders & Dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color dividerDark = Color(0xFF374151);
  
  // ============================================
  // CATEGORY COLORS (para categorias de gastos)
  // ============================================
  
  static const Color categoryFood = Color(0xFFFF6B6B);        // Alimentação
  static const Color categoryTransport = Color(0xFF4ECDC4);   // Transporte
  static const Color categoryEntertainment = Color(0xFFFFE66D); // Lazer
  static const Color categoryHealth = Color(0xFF95E1D3);      // Saúde
  static const Color categoryShopping = Color(0xFFF38181);    // Compras
  static const Color categoryBills = Color(0xFF7C83FD);       // Contas
  static const Color categoryEducation = Color(0xFFA8D8EA);   // Educação
  static const Color categoryTravel = Color(0xFFAA96DA);      // Viagem
  static const Color categoryInvestment = Color(0xFF00C9A7);  // Investimento
  static const Color categorySalary = Color(0xFF00D4AA);      // Salário
  static const Color categoryOther = Color(0xFFB8B8D1);       // Outros
  
  // ============================================
  // DARK PALETTE — Cores específicas para tema escuro
  // ============================================

  /// Primary dark mode — tons mais profundos e saturados
  static const Color darkPrimary = Color(0xFF14647A);
  static const Color darkPrimaryLight = Color(0xFF1E8F9A);
  static const Color darkPrimaryLighter = Color(0xFF27A8AA);

  /// Accent dark mode — levemente mais suave para contraste em fundo escuro
  static const Color darkAccent = Color(0xFF00BFA5);
  static const Color darkAccentLight = Color(0xFF4DD8B5);

  /// Superfícies dark mode
  static const Color darkSurface1 = Color(0xFF1C1C2A); // cards, containers
  static const Color darkSurface2 = Color(0xFF242438); // elevated cards
  static const Color darkSurface3 = Color(0xFF2D2D44); // dialogs, menus

  /// Glass dark mode — efeitos glassmorphism para fundo escuro
  static const Color darkGlassWhite = Color(0x14FFFFFF);   // 8% white
  static const Color darkGlassBorder = Color(0x29FFFFFF);   // 16% white
  static const Color darkGlassOverlay = Color(0x0AFFFFFF);  // 4% white

  /// Glass light mode — efeitos glassmorphism para fundo claro
  static const Color lightGlass = Color(0x1A000000);          // 10% black
  static const Color lightGlassBorder = Color(0x26000000);    // 15% black
  static const Color lightGlassOverlay = Color(0x0D000000);   // 5% black

  /// Semantic dark mode
  static const Color darkSuccess = Color(0xFF00E676);
  static const Color darkSuccessLight = Color(0xFF1B3A26);
  static const Color darkError = Color(0xFFFF6E6E);
  static const Color darkErrorLight = Color(0xFF3A1B1B);
  static const Color darkWarning = Color(0xFFFFCA28);
  static const Color darkWarningLight = Color(0xFF3A351B);
  static const Color darkInfo = Color(0xFF42A5F5);
  static const Color darkInfoLight = Color(0xFF1B2A3A);

  /// Shadows dark mode
  static const Color darkShadow = Color(0x40000000);       // 25% black
  static const Color darkShadowLight = Color(0x1A000000);   // 10% black

  // ============================================
  // GRADIENT DEFINITIONS
  // ============================================
  
  /// Gradiente principal (usado no onboarding, headers)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D4F6E),
      Color(0xFF1A7B8C),
      Color(0xFF2BA3A8),
      Color(0xFF5BC4BE),
      Color(0xFF8DD8D3),
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  /// Gradiente da Welcome Page (light mode)
  /// Superior: tons claros de verde/cyan → Inferior: tons escuros profundos
  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF8DD8D3), // Pale cyan (topo - mais claro)
      Color(0xFF5BC4BE), // Light cyan
      Color(0xFF2BA3A8), // Cyan
      Color(0xFF1A7B8C), // Teal
      Color(0xFF0D4F6E), // Deep teal
      Color(0xFF082F45), // Muito escuro (base)
    ],
    stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
  );

  /// Gradiente da Welcome Page (dark mode)
  /// Tons navy/índigo profundos com subtoque de teal
  static const LinearGradient welcomeGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A2A3E), // Navy escuro (topo)
      Color(0xFF162234), // Navy mais profundo
      Color(0xFF111C2E), // Deep navy
      Color(0xFF0D1724), // Muito escuro
      Color(0xFF09111B), // Quase preto
      Color(0xFF060D14), // Base - quase preto com subtoque azul
    ],
    stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
  );

  /// Gradiente do Drawer
  static const LinearGradient drawerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D4F6E),
      Color(0xFF1A7B8C),
    ],
  );

  /// Gradiente do Drawer (dark mode)
  static const LinearGradient drawerGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D1724),
      Color(0xFF111C2E),
    ],
  );

  // ============================================
  // GLASS / OVERLAY COLORS
  // ============================================

  /// Cores para efeitos glassmorphism
  static const Color glassWhite = Color(0x1AFFFFFF);      // 10% white
  static const Color glassBorder = Color(0x33FFFFFF);      // 20% white
  static const Color glassOverlay = Color(0x0DFFFFFF);     // 5% white
  
  /// Gradiente para cards de receita
  static const LinearGradient incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00C9A7),
      Color(0xFF00D4AA),
      Color(0xFF55EFC4),
    ],
  );
  
  /// Gradiente para cards de despesa
  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6B6B),
      Color(0xFFFF8E8E),
      Color(0xFFFFB4B4),
    ],
  );
  
  /// Gradiente escuro (dark mode)
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0F3460),
    ],
  );
  
  // ============================================
  // CHART COLORS
  // ============================================
  
  static const List<Color> chartColors = [
    Color(0xFF1A7B8C),
    Color(0xFF00D4AA),
    Color(0xFFFF6B6B),
    Color(0xFFFFE66D),
    Color(0xFF7C83FD),
    Color(0xFFF38181),
    Color(0xFF4ECDC4),
    Color(0xFFAA96DA),
    Color(0xFF95E1D3),
    Color(0xFFA8D8EA),
  ];
  
  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Retorna a cor da categoria pelo nome
  static Color getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'alimentação':
      case 'food':
        return categoryFood;
      case 'transporte':
      case 'transport':
        return categoryTransport;
      case 'lazer':
      case 'entertainment':
        return categoryEntertainment;
      case 'saúde':
      case 'health':
        return categoryHealth;
      case 'compras':
      case 'shopping':
        return categoryShopping;
      case 'contas':
      case 'bills':
        return categoryBills;
      case 'educação':
      case 'education':
        return categoryEducation;
      case 'viagem':
      case 'travel':
        return categoryTravel;
      case 'investimento':
      case 'investment':
        return categoryInvestment;
      case 'salário':
      case 'salary':
        return categorySalary;
      default:
        return categoryOther;
    }
  }
  
  /// Retorna cor com opacidade
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}
