import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/theme/app_theme.dart';

class AppBackground extends ConsumerStatefulWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  ConsumerState<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends ConsumerState<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );

    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.watch(accentColorProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Deep Navy Base (#0E131F)
          Container(
            color: isDark ? const Color(0xFF0E131F) : AppTheme.lightBgBase,
          ),

          // Glow Blob 1: Luminous Primary Container (#5B5FEF)
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 440,
              height: 440,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: isDark ? 0.30 : 0.18),
                    accentColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Glow Blob 2: Tertiary Purple (#8151EB)
          Positioned(
            bottom: -130,
            right: -130,
            child: Container(
              width: 460,
              height: 460,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8151EB).withValues(alpha: isDark ? 0.28 : 0.16),
                    const Color(0xFF8151EB).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Glow Blob 3: Secondary Sky Blue (#7BD0FF)
          Positioned(
            top: 280,
            left: 40,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7BD0FF).withValues(alpha: isDark ? 0.18 : 0.10),
                    const Color(0xFF7BD0FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main Screen Content
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}
