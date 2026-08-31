import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:trackx/shared/widgets/glass_container.dart';

class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showHandle;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.padding,
    this.showHandle = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.60),
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (ctx) => GlassBottomSheet(child: builder(ctx)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      tier: GlassTier.modal,
      borderRadius: 28.0,
      showLightRim: true,
      padding: padding ?? const EdgeInsets.fromLTRB(22, 16, 22, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHandle) ...[
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          child,
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(
          begin: 0.05,
          end: 0,
          duration: 200.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
