import 'package:flutter/material.dart';
import 'package:fyna/core/themes/theme_colors.dart';

/// Badge quadrado arredondado com fundo pastel + ícone saturado.
///
/// Padrão visual usado em listas de transações, categorias, contas,
/// recorrências e notificações.
///
/// Use `tone` (food/transport/...) para um par pré-definido, ou
/// passe `background`/`foreground` para customizar.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final String? tone;
  final Color? background;
  final Color? foreground;
  final double size;
  final double iconSize;
  final double radius;

  const IconBadge({
    super.key,
    required this.icon,
    this.tone,
    this.background,
    this.foreground,
    this.size = 40,
    this.iconSize = 20,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final pair = tone != null ? tc.badge(tone!) : null;
    final bg = background ?? pair?.bg ?? tc.badge('neutral').bg;
    final fg = foreground ?? pair?.fg ?? tc.badge('neutral').fg;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: fg, size: iconSize),
    );
  }
}
