import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme Color Presets (Apple Glass styling)
  static const Color accentPurple = Color(0xFFC084FC);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color accentGreen = Color(0xFF34D399);
  static const Color accentPink = Color(0xFFF472B6);
  static const Color accentOrange = Color(0xFFFB923C);
  static const Color accentRed = Color(0xFFF87171);

  // Dark Mode Ambient (VisionOS standard)
  static const Color darkBgBase = Color(0xFF0A0518);
  static const Color darkGlassBg = Color(0x14FFFFFF); // 8% opacity
  static const Color darkGlassBorder = Color(0x26FFFFFF); // 15% opacity

  // Light Mode Ambient
  static const Color lightBgBase = Color(0xFFF6F8FC);
  static const Color lightGlassBg = Color(0x1F000000); // 12% opacity black
  static const Color lightGlassBorder = Color(0x33000000); // 20% opacity black

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor:
          Colors.transparent, // Background blobs will render behind
      colorScheme: const ColorScheme.dark(
        primary: accentPurple,
        secondary: accentBlue,
        surface: darkBgBase,
        error: accentRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.outfit(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titleLarge: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            titleMedium: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            bodyLarge: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.white.withOpacity(0.9),
            ),
            bodyMedium: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.white.withOpacity(0.7),
            ),
            labelLarge: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: accentPurple,
        secondary: accentBlue,
        surface: lightBgBase,
        error: accentRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.outfit(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            titleLarge: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            titleMedium: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            bodyLarge: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.black.withOpacity(0.9),
            ),
            bodyMedium: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.black.withOpacity(0.7),
            ),
            labelLarge: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
    );
  }
}
