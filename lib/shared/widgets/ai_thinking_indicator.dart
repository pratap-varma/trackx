import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class AiThinkingIndicator extends StatelessWidget {
  final String label;
  final bool compact;

  const AiThinkingIndicator({
    super.key,
    this.label = 'AI is analyzing...',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = context.accentColor;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;
    final isDark = context.isDark;

    if (compact) {
      return GlassContainer(
        tier: GlassTier.subtle,
        borderRadius: 20,
        showLightRim: true,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        borderColor: accentColor.withValues(alpha: 0.4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: accentColor,
              size: 15,
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.15, 1.15),
                  duration: 800.ms,
                )
                .tint(color: context.secondaryColor, duration: 800.ms),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return GlassContainer(
      tier: GlassTier.modal,
      borderRadius: 24,
      showLightRim: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      borderColor: accentColor.withValues(alpha: 0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: accentColor,
              size: 26,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.12, 1.12),
                duration: 900.ms,
              )
              .shimmer(
                duration: 1500.ms,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.2),
              ),
          const SizedBox(height: 18),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Synthesizing notes & generating high-yield cards',
            style: TextStyle(
              color: subtextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
