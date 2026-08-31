import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum GlassTier {
  subtle,
  standard,
  modal,
  hero,
}

class GlassContainer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double? blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final List<Color>? gradientColors;
  final Color? borderColor;
  final Color? glowColor;
  final Color? tintColor;
  final VoidCallback? onTap;
  final GlassTier tier;
  final bool showLightRim;
  final bool showSheen;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.blur,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.gradientColors,
    this.borderColor,
    this.glowColor,
    this.tintColor,
    this.onTap,
    this.tier = GlassTier.standard,
    this.showLightRim = false,
    this.showSheen = false,
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null) {
      HapticFeedback.selectionClick();
      _pressController.forward();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      _pressController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Clean, natural glassmorphism tokens
    double effectiveBlur;
    Color baseBgColor;
    Color defaultBorderColor;
    double shadowBlur;
    double shadowOpacity;

    switch (widget.tier) {
      case GlassTier.subtle:
        effectiveBlur = widget.blur ?? 12.0;
        baseBgColor = isDark
            ? const Color(0x0EFFFFFF) // 5.5% white
            : const Color(0xCCFFFFFF); // 80% white
        defaultBorderColor = isDark
            ? const Color(0x14FFFFFF) // 8% white
            : const Color(0x0F000000); // 6% black
        shadowBlur = 10.0;
        shadowOpacity = isDark ? 0.10 : 0.03;
        break;

      case GlassTier.hero:
        effectiveBlur = widget.blur ?? 20.0;
        baseBgColor = isDark
            ? const Color(0x1AFFFFFF) // 10% white
            : const Color(0xE6FFFFFF); // 90% white
        defaultBorderColor = isDark
            ? const Color(0x28FFFFFF) // 16% white
            : const Color(0x1A000000); // 10% black
        shadowBlur = 24.0;
        shadowOpacity = isDark ? 0.20 : 0.06;
        break;

      case GlassTier.modal:
        effectiveBlur = widget.blur ?? 24.0;
        baseBgColor = isDark
            ? const Color(0x22121829) // Deep frosted navy
            : const Color(0xF2FFFFFF); // 95% white
        defaultBorderColor = isDark
            ? const Color(0x22FFFFFF)
            : const Color(0x18000000);
        shadowBlur = 32.0;
        shadowOpacity = isDark ? 0.35 : 0.08;
        break;

      case GlassTier.standard:
        effectiveBlur = widget.blur ?? 16.0;
        baseBgColor = isDark
            ? const Color(0x14FFFFFF) // 8% white
            : const Color(0xDBFFFFFF); // 86% white
        defaultBorderColor = isDark
            ? const Color(0x1CFFFFFF) // 11% white
            : const Color(0x12000000); // 7% black
        shadowBlur = 16.0;
        shadowOpacity = isDark ? 0.16 : 0.04;
        break;
    }

    final Color finalBorderColor = widget.borderColor ?? defaultBorderColor;

    Widget container = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity),
            blurRadius: shadowBlur,
            offset: const Offset(0, 4),
          ),
          if (widget.glowColor != null)
            BoxShadow(
              color: widget.glowColor!.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 20.0,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectiveBlur,
            sigmaY: effectiveBlur,
          ),
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.tintColor != null
                  ? Color.alphaBlend(widget.tintColor!, baseBgColor)
                  : baseBgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: finalBorderColor, width: 0.8),
              gradient: widget.gradientColors != null
                  ? LinearGradient(
                      colors: widget.gradientColors!,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: ScaleTransition(scale: _scaleAnimation, child: container),
      );
    }

    return container;
  }
}
