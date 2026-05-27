import 'package:flutter/material.dart';
import 'package:fyna/core/themes/theme_colors.dart';

/// Header padrão das telas de conteúdo (Transações, Categorias, Contas, etc.).
///
/// Composto por: linha de ações (back + actions) + título grande + subtítulo.
class AppScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  const AppScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 12),
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final hasActionRow = showBack || actions.isNotEmpty;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasActionRow) ...[
            Row(
              children: [
                if (showBack)
                  _SquareIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBack ?? () => Navigator.maybePop(context),
                  ),
                const Spacer(),
                ...actions,
              ],
            ),
            const SizedBox(height: 14),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: tc.neoText,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: tc.neoTextMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Material(
      color: tc.neoCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tc.neoCardBorder),
          ),
          child: Icon(icon, size: 16, color: tc.neoText),
        ),
      ),
    );
  }
}

/// Botão de ação principal do header (geralmente o "+").
/// Quadrado arredondado, fundo teal sólido.
class HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const HeaderActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final button = Material(
      color: tc.neoTeal,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
