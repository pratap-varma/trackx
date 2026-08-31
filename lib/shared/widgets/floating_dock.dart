import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackx/shared/widgets/glass_container.dart';

class DockItem {
  final IconData icon;
  final String label;

  const DockItem({required this.icon, required this.label});
}

class FloatingDock extends StatelessWidget {
  final int currentIndex;
  final List<DockItem> items;
  final ValueChanged<int> onTabSelected;

  const FloatingDock({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: GlassContainer(
            tier: GlassTier.modal,
            borderRadius: 26,
            showLightRim: true,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isActive = index == currentIndex;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTabSelected(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isDark
                              ? primaryColor.withValues(alpha: 0.22)
                              : primaryColor.withValues(alpha: 0.12))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? (isDark
                                ? primaryColor.withValues(alpha: 0.45)
                                : primaryColor.withValues(alpha: 0.30))
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          color: isActive
                              ? (isDark ? const Color(0xFFC0C1FF) : primaryColor)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.45)
                                  : const Color(0xFF64748B)),
                          size: 21,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isActive
                                ? (isDark ? const Color(0xFFDEE2F4) : const Color(0xFF0F172A))
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
