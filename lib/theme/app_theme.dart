import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';

import 'package:trackx/core/services/widget_data_service.dart';

// Provider for dynamic accent color
final accentColorProvider = StateNotifierProvider<AccentColorNotifier, Color>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AccentColorNotifier(prefs, ref);
});

class AccentColorNotifier extends StateNotifier<Color> {
  final SharedPreferences _prefs;
  final Ref _ref;
  static const String _keyAccent = 'theme_accent_color_val';

  AccentColorNotifier(this._prefs, this._ref) : super(const Color(0xFF5B5FEF)) {
    final val = _prefs.getInt(_keyAccent);
    if (val != null) {
      state = Color(val);
    }
  }

  Future<void> setAccent(Color color) async {
    state = color;
    await _prefs.setInt(_keyAccent, color.toARGB32());
    try {
      await _ref.read(widgetDataServiceProvider).syncWithAppData(_ref);
    } catch (_) {}
  }
}

// Provider for dynamic ThemeMode (Dark, Light, System)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs, ref);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  final Ref _ref;
  static const String _keyThemeMode = 'app_theme_mode_setting';

  ThemeModeNotifier(this._prefs, this._ref) : super(_loadInitialTheme(_prefs));

  static ThemeMode _loadInitialTheme(SharedPreferences prefs) {
    final str = prefs.getString(_keyThemeMode);
    if (str == 'light') return ThemeMode.light;
    if (str == 'system') return ThemeMode.system;
    return ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : (mode == ThemeMode.system ? 'system' : 'dark');
    await _prefs.setString(_keyThemeMode, modeStr);

    try {
      final authRepo = _ref.read(authRepositoryProvider.notifier);
      final currentProfile = _ref.read(authRepositoryProvider).userProfile;
      if (currentProfile != null) {
        await authRepo.saveFullProfile(currentProfile.copyWith(themeMode: modeStr));
      }
    } catch (_) {}

    try {
      await _ref.read(widgetDataServiceProvider).syncWithAppData(_ref);
    } catch (_) {}
  }
}

class AppTheme {
  // Luminous Intelligence Color Palette Defaults
  static const Color primary = Color(0xFFC0C1FF);
  static const Color primaryContainer = Color(0xFF5B5FEF);
  static const Color secondary = Color(0xFF7BD0FF);
  static const Color tertiary = Color(0xFFD0BCFF);
  static const Color tertiaryContainer = Color(0xFF8151EB);

  static const Color accentPurple = Color(0xFF5B5FEF);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentViolet = Color(0xFF8151EB);
  static const Color accentRed = Color(0xFFEF4444);

  // Dark Mode Ambient Surfaces
  static const Color darkBgBase = Color(0xFF0E131F); // Deep Navy Base
  static const Color darkSurfaceContainer = Color(0xFF1B1F2C);
  static const Color darkSurfaceHigh = Color(0xFF252A37);
  static const Color darkGlassBg = Color(0x14FFFFFF); // 8% white glass
  static const Color darkGlassBorder = Color(0x1FDEE2F4); // 12% luminous outline

  // Multi-tier Frosted Glass Tokens (Dark)
  static const Color darkGlassSubtleBg = Color(0x0CFFFFFF); // 5% subtle
  static const Color darkGlassSubtleBorder = Color(0x14DEE2F4);
  static const Color darkGlassModalBg = Color(0xF20E1628); // 95% deep navy frost
  static const Color darkGlassModalBorder = Color(0x33DEE2F4); // 20% luminous rim

  // Light Mode Ambient Surfaces
  static const Color lightBgBase = Color(0xFFF1F5F9); // Crisp Slate-White
  static const Color lightSurfaceContainer = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFF8FAFC);
  static const Color lightGlassBg = Color(0xCCFFFFFF); // 80% white frost
  static const Color lightGlassBorder = Color(0x1F000000); // 12% subtle outline
  static const Color lightGlassSubtleBg = Color(0x99FFFFFF);
  static const Color lightGlassSubtleBorder = Color(0x14000000);
  static const Color lightGlassModalBg = Color(0xF7FFFFFF);
  static const Color lightGlassModalBorder = Color(0x26000000);

  static TextTheme _buildTextTheme(Brightness brightness, bool isTest) {
    final isDark = brightness == Brightness.dark;
    if (isTest) {
      return isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    }

    if (isDark) {
      return GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
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
      );
    } else {
      return GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF1E293B),
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF334155),
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF475569),
        ),
      );
    }
  }

  static ThemeData buildTheme(Brightness brightness, Color accentColor) {
    final isDark = brightness == Brightness.dark;
    bool isTest = false;
    try {
      if (!kIsWeb) {
        isTest = Platform.environment.containsKey('FLUTTER_TEST');
      }
    } catch (_) {
      isTest = false;
    }

    final HSLColor hsl = HSLColor.fromColor(accentColor);
    final Color secondaryColor = hsl.withHue((hsl.hue + 25) % 360).toColor();
    final Color tertiaryColor = hsl.withHue((hsl.hue + 55) % 360).toColor();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: accentColor,
      scaffoldBackgroundColor: isDark ? darkBgBase : lightBgBase,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: accentColor,
              primaryContainer: accentColor.withValues(alpha: 0.25),
              secondary: secondaryColor,
              tertiary: tertiaryColor,
              surface: darkBgBase,
              surfaceContainer: darkSurfaceContainer,
              surfaceContainerHigh: darkSurfaceHigh,
              error: accentRed,
            )
          : ColorScheme.light(
              primary: accentColor,
              primaryContainer: accentColor.withValues(alpha: 0.15),
              secondary: secondaryColor,
              tertiary: tertiaryColor,
              surface: lightBgBase,
              surfaceContainer: lightSurfaceContainer,
              surfaceContainerHigh: lightSurfaceHigh,
              error: accentRed,
            ),
      textTheme: _buildTextTheme(brightness, isTest),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accentColor : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accentColor.withValues(alpha: 0.5)
              : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accentColor : null,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accentColor : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentColor,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: accentColor,
        labelColor: isDark ? Colors.white : accentColor,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        thumbColor: accentColor,
        overlayColor: accentColor.withValues(alpha: 0.2),
      ),
      chipTheme: ChipThemeData(
        selectedColor: accentColor,
        checkmarkColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme => buildTheme(Brightness.dark, accentPurple);
  static ThemeData get lightTheme => buildTheme(Brightness.light, accentPurple);
}

extension ThemeContextExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get accentColor => Theme.of(this).colorScheme.primary;
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get primaryContainer => Theme.of(this).colorScheme.primaryContainer;
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
  Color get tertiaryColor => Theme.of(this).colorScheme.tertiary;
  LinearGradient get accentGradient => LinearGradient(
        colors: [Theme.of(this).colorScheme.primary, Theme.of(this).colorScheme.tertiary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  Color get textColor => isDark ? const Color(0xFFDEE2F4) : const Color(0xFF0F172A);
  Color get subtextColor => isDark ? const Color(0xFFDEE2F4).withValues(alpha: 0.70) : const Color(0xFF475569);
  Color get mutedTextColor => isDark ? const Color(0xFFDEE2F4).withValues(alpha: 0.45) : const Color(0xFF94A3B8);
  Color get subtleBorderColor =>
      isDark ? const Color(0x1FDEE2F4) : const Color(0x1F000000);
  Color get glassFillColor =>
      isDark ? AppTheme.darkGlassBg : AppTheme.lightGlassBg;
  Color get glassBorderColor =>
      isDark ? AppTheme.darkGlassBorder : AppTheme.lightGlassBorder;
  Color get cardColor =>
      isDark ? AppTheme.darkSurfaceContainer : AppTheme.lightSurfaceContainer;
  Color get dividerColor =>
      isDark ? Colors.white10 : Colors.black12;
  Color get iconColor =>
      isDark ? Colors.white : const Color(0xFF0F172A);
  Color get scaffoldBackgroundColor =>
      isDark ? AppTheme.darkBgBase : AppTheme.lightBgBase;
}
