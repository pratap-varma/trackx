import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:trackx/theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final List<Color>? gradientColors;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 25.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.gradientColors,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? AppTheme.darkGlassBg : AppTheme.lightGlassBg;

    final Color finalBorderColor = borderColor ?? (isDark
        ? AppTheme.darkGlassBorder
        : AppTheme.lightGlassBorder);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: finalBorderColor, width: 1.0),
              gradient: gradientColors != null
                  ? LinearGradient(
                      colors: gradientColors!,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
