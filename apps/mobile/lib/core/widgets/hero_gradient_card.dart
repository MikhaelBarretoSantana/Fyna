import 'package:flutter/material.dart';
import 'package:fyna/core/themes/theme_colors.dart';

/// Card "hero" no topo de várias telas (Saldo, Patrimônio, Saúde Financeira,
/// Limite mensal, etc.). Fundo em gradiente teal escuro com leve glow.
class HeroGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final LinearGradient? gradient;

  const HeroGradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(22, 22, 22, 22),
    this.radius = 22,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient ?? tc.heroGradient,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: tc.isDark ? 0.35 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child: child,
          ),
        ),
        // Glow decorativo canto superior direito
        Positioned(
          right: -20,
          top: -20,
          child: IgnorePointer(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
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
}
