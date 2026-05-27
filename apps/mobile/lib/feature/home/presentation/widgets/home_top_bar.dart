import 'package:flutter/material.dart';
import 'package:fyna/core/themes/theme_colors.dart';

/// Top bar da Home: campo de busca + ícone IA/refresh + sino com badge.
class HomeTopBar extends StatelessWidget {
  final bool hasUnread;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onRefreshTap;

  const HomeTopBar({
    super.key,
    required this.hasUnread,
    this.onNotificationsTap,
    this.onSearchTap,
    this.onRefreshTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSearchTap,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: tc.neoCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tc.neoCardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: tc.neoTextMuted, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Buscar',
                      style: TextStyle(
                        color: tc.neoTextFaint,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _CircleAction(
            icon: Icons.refresh_rounded,
            onTap: onRefreshTap,
          ),
          const SizedBox(width: 8),
          _CircleAction(
            icon: Icons.notifications_none_rounded,
            badge: hasUnread,
            onTap: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool badge;

  const _CircleAction({
    required this.icon,
    this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: tc.neoCard,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: tc.neoCardBorder),
              ),
              child: Icon(icon, color: tc.neoText, size: 20),
            ),
          ),
        ),
        if (badge)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: tc.neoNegative,
                shape: BoxShape.circle,
                border: Border.all(color: tc.neoCard, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
