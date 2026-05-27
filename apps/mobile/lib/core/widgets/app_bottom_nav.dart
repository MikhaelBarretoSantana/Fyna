import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/core/themes/theme_colors.dart';

class AppBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AppBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Bottom nav padrão do app, com slot central para o FAB.
///
/// Espera 4 itens; o FAB (passado via [floatingActionButton] do Scaffold)
/// flutua sobre o "notch" central.
class AppBottomNav extends StatelessWidget {
  final List<AppBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  }) : assert(items.length == 4, 'AppBottomNav requires exactly 4 items');

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tc.neoCard,
        boxShadow: [
          BoxShadow(
            color: tc.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildItem(context, 0),
                    _buildItem(context, 1),
                  ],
                ),
              ),
              const SizedBox(width: 72),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildItem(context, 2),
                    _buildItem(context, 3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final tc = ThemeColors.of(context);
    final item = items[index];
    final isSelected = index == selectedIndex;
    final activeColor = tc.neoTeal;
    final inactiveColor = tc.neoTextFaint;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// FAB central do app — círculo teal com "+", levemente elevado.
class AppCenterFab extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const AppCenterFab({
    super.key,
    required this.onTap,
    this.icon = Icons.add_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 24),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: tc.neoTeal.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: tc.neoTeal,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
