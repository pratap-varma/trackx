import 'package:flutter/material.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class GlassPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GlassPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: GlassContainer(
        borderRadius: 16.0,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        gradientColors: onPressed == null
            ? [Colors.white10, Colors.white10]
            : [
                AppTheme.accentPurple.withOpacity(0.8),
                AppTheme.accentBlue.withOpacity(0.8),
              ],
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
