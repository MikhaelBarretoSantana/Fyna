import 'package:flutter/material.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/icon_badge.dart';

/// Card de insight da IA na Home.
///
/// Fundo lavanda claro, sparkle icon + headline + link "Ver análise da IA →".
class HomeAiInsightCard extends StatelessWidget {
  final String message;
  final String ctaLabel;
  final VoidCallback? onTap;

  const HomeAiInsightCard({
    super.key,
    required this.message,
    this.ctaLabel = 'Ver análise da IA',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final badge = tc.badge('ai');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Material(
        color: badge.bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: [
                IconBadge(
                  icon: Icons.auto_awesome_rounded,
                  tone: 'ai',
                  background: Colors.white.withValues(
                    alpha: tc.isDark ? 0.06 : 0.7,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: tc.neoText,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            ctaLabel,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: badge.fg,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 14, color: badge.fg),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
