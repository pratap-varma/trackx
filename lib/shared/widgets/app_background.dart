import 'package:flutter/material.dart';
import 'package:trackx/theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Base Color
          Container(color: isDark ? AppTheme.darkBgBase : AppTheme.lightBgBase),

          // Glow Blob 1 (Top Left)
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentPurple.withOpacity(isDark ? 0.35 : 0.2),
                    AppTheme.accentPurple.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Glow Blob 2 (Bottom Right)
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentPink.withOpacity(isDark ? 0.35 : 0.2),
                    AppTheme.accentPink.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Glow Blob 3 (Center Ambient)
          Positioned(
            top: 250,
            left: 50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentBlue.withOpacity(isDark ? 0.25 : 0.15),
                    AppTheme.accentBlue.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main Screen Content
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
