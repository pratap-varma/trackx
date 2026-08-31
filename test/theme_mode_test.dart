import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Light and Dark Theme Mode Tests', () {
    test('1. Default theme mode is Dark if not previously saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final initialMode = container.read(themeModeProvider);
      expect(initialMode, ThemeMode.dark);
    });

    test('2. Changing ThemeMode to Light persists and updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final notifier = container.read(themeModeProvider.notifier);
      await notifier.setThemeMode(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(prefs.getString('app_theme_mode_setting'), 'light');
    });

    test('3. Changing ThemeMode to System persists and updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final notifier = container.read(themeModeProvider.notifier);
      await notifier.setThemeMode(ThemeMode.system);

      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(prefs.getString('app_theme_mode_setting'), 'system');
    });

    test('4. AppTheme builds valid light and dark ThemeData', () {
      final darkTheme = AppTheme.buildTheme(Brightness.dark, const Color(0xFF5B5FEF));
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.colorScheme.primary, const Color(0xFF5B5FEF));
      expect(darkTheme.scaffoldBackgroundColor, AppTheme.darkBgBase);

      final lightTheme = AppTheme.buildTheme(Brightness.light, const Color(0xFF5B5FEF));
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.colorScheme.primary, const Color(0xFF5B5FEF));
      expect(lightTheme.scaffoldBackgroundColor, AppTheme.lightBgBase);
    });

    test('5. AccentColorNotifier persists chosen palette color', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final accentNotifier = container.read(accentColorProvider.notifier);
      const emerald = Color(0xFF10B981);
      await accentNotifier.setAccent(emerald);

      expect(container.read(accentColorProvider), emerald);
    });
  });
}
