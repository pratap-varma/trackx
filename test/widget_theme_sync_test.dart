import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/services/widget_data_service.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('WidgetDataService stores themeMode, isDark, and accentColor correctly', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final service = WidgetDataService(prefs);

    await service.updateWidgetsData(
      overallAttendance: '82%',
      attendanceBadge: 'ON TRACK',
      attendanceBunkInfo: 'Safe to Bunk: 2 classes',
      attendanceTargetInfo: 'Target: 75%',
      attendanceRatio: '24 / 29 Conducted',
      scheduleDay: 'WEDNESDAY',
      scheduleBadge: 'TODAY',
      nextClassMeta: 'NEXT CLASS',
      nextClassName: 'Computer Networks',
      nextClassRoom: 'Room 302',
      scheduleSummary: '4 classes remaining',
      classesToday: 5,
      scheduleSlotsJson: '[]',
      examsHeader: 'EXAMS & EVENTS',
      examsBadge: 'SCHEDULED',
      nextExamMeta: 'MIDTERM',
      nextExamTitle: 'Operating Systems',
      nextExamDateTime: 'Tomorrow at 10:00 AM',
      examsSummary: '1 upcoming exam this week',
      upcomingExamsCount: 1,
      examsSlotsJson: '[]',
      themeMode: 'light',
      isDark: false,
      accentColor: '#3B82F6',
    );

    final widgetData = service.getWidgetData();
    expect(widgetData['themeMode'], equals('light'));
    expect(widgetData['isDark'], equals(false));
    expect(widgetData['accentColor'], equals('#3B82F6'));
  });

  test('ThemeModeNotifier and AccentColorNotifier sync with WidgetDataService', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // Initial state
    expect(container.read(themeModeProvider), equals(ThemeMode.dark));

    // Change theme mode to light
    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
    expect(container.read(themeModeProvider), equals(ThemeMode.light));

    // Change accent color to custom blue
    const customColor = Color(0xFF3B82F6);
    await container.read(accentColorProvider.notifier).setAccent(customColor);
    expect(container.read(accentColorProvider), equals(customColor));

    // Check stored widget data
    final widgetData = container.read(widgetDataServiceProvider).getWidgetData();
    expect(widgetData['themeMode'], equals('light'));
    expect(widgetData['isDark'], equals(false));
    expect(widgetData['accentColor'], equals('#3B82F6'));
  });
}
