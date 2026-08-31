import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
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

    bool isTest = false;
    try {
      if (!kIsWeb) {
        isTest = Platform.environment.containsKey('FLUTTER_TEST');
      }
    } catch (_) {
      isTest = false;
    }

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
      backgroundColor: isDark ? AppTheme.darkBgBase : AppTheme.lightBgBase,
      body: Stack(
        children: [
          // 1. Background Base Color
          Container(
            color: isDark ? const Color(0xFF0E131F) : AppTheme.lightBgBase,
          ),

          // 2. Dynamic Ambient Glow Blobs with Multi-Orb Sinusoidal Drift
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final val = _controller.value * 2 * math.pi;
              final dx1 = math.sin(val) * 45.0;
              final dy1 = math.cos(val) * 30.0;

              final dx2 = math.cos(val * 0.8) * 50.0;
              final dy2 = math.sin(val * 0.8) * 40.0;

              final dx3 = math.sin(val * 1.2) * 35.0;
              final dy3 = math.cos(val * 1.2) * 25.0;

              final dx4 = math.cos(val * 1.5) * 30.0;
              final dy4 = math.sin(val * 1.5) * 35.0;

              return Stack(
                children: [
                  // Glow Blob 1: Primary Dynamic Accent (Top-Left Drift)
                  Positioned(
                    top: -100 + dy1,
                    left: -100 + dx1,
                    child: Container(
                      width: 480,
                      height: 480,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accentColor.withValues(
                              alpha: isDark ? 0.22 : 0.12,
                            ),
                            accentColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Glow Blob 2: Luminous Purple (Bottom-Right Drift)
                  Positioned(
                    bottom: -110 + dy2,
                    right: -110 + dx2,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF8151EB).withValues(
                              alpha: isDark ? 0.18 : 0.10,
                            ),
                            const Color(0xFF8151EB).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Glow Blob 3: Sky Cyan (Center-Left Drift)
                  Positioned(
                    top: 280 + dy3,
                    left: -40 + dx3,
                    child: Container(
                      width: 380,
                      height: 380,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF7BD0FF).withValues(
                              alpha: isDark ? 0.14 : 0.08,
                            ),
                            const Color(0xFF7BD0FF).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Glow Blob 4: Emerald / Teal Soft Focus (Mid-Right Drift)
                  Positioned(
                    top: 450 + dy4,
                    right: -60 + dx4,
                    child: Container(
                      width: 360,
                      height: 360,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF10B981).withValues(
                              alpha: isDark ? 0.12 : 0.06,
                            ),
                            const Color(0xFF10B981).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 3. Main Screen Content Layer
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}
