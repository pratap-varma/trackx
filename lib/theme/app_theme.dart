import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';

// Provider for dynamic accent color
final accentColorProvider = StateNotifierProvider<AccentColorNotifier, Color>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AccentColorNotifier(prefs);
});

class AccentColorNotifier extends StateNotifier<Color> {
  final SharedPreferences _prefs;
  static const String _keyAccent = 'theme_accent_color_val';

  AccentColorNotifier(this._prefs) : super(const Color(0xFF5B5FEF)) {
    final val = _prefs.getInt(_keyAccent);
    if (val != null) {
      state = Color(val);
    }
  }

  Future<void> setAccent(Color color) async {
    state = color;
    await _prefs.setInt(_keyAccent, color.toARGB32());
  }
}

class AppTheme {
  // Luminous Intelligence Color Palette
  static const Color primary = Color(0xFFC0C1FF);
  static const Color primaryContainer = Color(0xFF5B5FEF);
  static const Color secondary = Color(0xFF7BD0FF);
  static const Color tertiary = Color(0xFFD0BCFF);
  static const Color tertiaryContainer = Color(0xFF8151EB);

  static const Color accentPurple = Color(0xFF5B5FEF);
  static const Color accentBlue = Color(0xFF7BD0FF);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentPink = Color(0xFF8151EB);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentRed = Color(0xFFEF4444);

  // Luminous Intelligence Ambient Surfaces
  static const Color darkBgBase = Color(0xFF0E131F); // Deep Navy Base
  static const Color darkSurfaceContainer = Color(0xFF1B1F2C);
  static const Color darkSurfaceHigh = Color(0xFF252A37);
  static const Color darkGlassBg = Color(0x14FFFFFF); // 8% white glass
  static const Color darkGlassBorder = Color(
    0x1FDEE2F4,
  ); // 12% luminous outline

  // Light Mode Ambient
  static const Color lightBgBase = Color(0xFFF6F8FC);
  static const Color lightGlassBg = Color(0x1F000000);
  static const Color lightGlassBorder = Color(0x33000000);

  static ThemeData buildTheme(Brightness brightness, Color accentColor) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: accentColor,
              primaryContainer: const Color(0xFF5B5FEF),
              secondary: const Color(0xFF7BD0FF),
              tertiary: const Color(0xFF8151EB),
              surface: darkBgBase,
              error: accentRed,
            )
          : ColorScheme.light(
              primary: accentColor,
              secondary: accentColor.withValues(alpha: 0.8),
              surface: lightBgBase,
              error: accentRed,
            ),
      textTheme: isDark
          ? GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
              displayLarge: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFDEE2F4),
              ),
              titleLarge: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFDEE2F4),
              ),
              titleMedium: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDEE2F4),
              ),
              bodyLarge: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.normal,
                color: const Color(0xFFDEE2F4).withValues(alpha: 0.9),
              ),
              bodyMedium: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: const Color(0xFFDEE2F4).withValues(alpha: 0.7),
              ),
              labelLarge: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFC6C5D7),
              ),
            )
          : GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
    );
  }

  static ThemeData get darkTheme => buildTheme(Brightness.dark, accentPurple);
  static ThemeData get lightTheme => buildTheme(Brightness.light, accentPurple);
}
