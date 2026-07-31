import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: GlassContainer(
          borderRadius: 36.0,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTabSelected(index);
                },
                child: AnimatedScale(
                  scale: isActive ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppTheme.accentPurple.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          item.icon,
                          color: isActive
                              ? AppTheme.accentPurple
                              : Colors.white.withOpacity(0.6),
                          size: 24,
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: isActive ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? AppTheme.accentPurple
                                : Colors.transparent,
                          ),
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
    );
  }
}
