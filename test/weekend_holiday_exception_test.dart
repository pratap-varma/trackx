import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/services/device_calendar_service.dart';
import 'package:trackx/features/calendar/data/repositories/calendar_repository.dart';
import 'package:mockito/mockito.dart';

class MockDeviceCalendarService extends Mock implements DeviceCalendarService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sunday & Saturday College Holidays & Working Exceptions', () {
    late SharedPreferences prefs;
    late CalendarRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = CalendarRepository(prefs, MockDeviceCalendarService());
    });

    test('1. Every Sunday is marked as a college holiday by default', () {
      // Find upcoming Sunday
      final now = DateTime.now();
      final sunday = now.add(Duration(days: (7 - now.weekday) % 7));
      expect(sunday.weekday, equals(DateTime.sunday));

      expect(repo.isDateEffectiveHoliday(sunday), isTrue);

      final holidays = repo.getEffectiveHolidaysForDate(sunday);
      expect(holidays.isNotEmpty, isTrue);
      expect(holidays.first.title.toLowerCase(), contains('sunday'));
    });

    test('2. Every Saturday is marked as a college holiday by default', () {
      // Find upcoming Saturday
      final now = DateTime.now();
      final saturday = now.add(Duration(days: (6 - now.weekday + 7) % 7));
      expect(saturday.weekday, equals(DateTime.saturday));

      expect(repo.isDateEffectiveHoliday(saturday), isTrue);

      final holidays = repo.getEffectiveHolidaysForDate(saturday);
      expect(holidays.isNotEmpty, isTrue);
      expect(holidays.first.title.toLowerCase(), contains('saturday'));
    });

    test('3. Regular weekdays (Monday - Friday) are working days by default', () {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      expect(monday.weekday, equals(DateTime.monday));

      expect(repo.isDateEffectiveHoliday(monday), isFalse);
    });

    test('4. Toggling Saturday switches it to a working day exception', () async {
      final now = DateTime.now();
      final saturday = now.add(Duration(days: (6 - now.weekday + 7) % 7));

      expect(repo.isDateEffectiveHoliday(saturday), isTrue);

      // Toggle to Working day (e.g. compensatory college day)
      final newState = await repo.toggleHolidayForDate(saturday);
      expect(newState, isFalse); // Not a holiday anymore
      expect(repo.isDateEffectiveHoliday(saturday), isFalse);
      expect(repo.isHolidayOverriddenToWorking(saturday), isTrue);
      expect(repo.getEffectiveHolidaysForDate(saturday), isEmpty);

      // Toggle back to holiday
      final reverted = await repo.toggleHolidayForDate(saturday);
      expect(reverted, isTrue);
      expect(repo.isDateEffectiveHoliday(saturday), isTrue);
    });

    test('5. Toggling Sunday switches it to a working day exception if needed', () async {
      final now = DateTime.now();
      final sunday = now.add(Duration(days: (7 - now.weekday) % 7));

      expect(repo.isDateEffectiveHoliday(sunday), isTrue);

      // Toggle to Working day
      final isHolidayNow = await repo.toggleHolidayForDate(sunday);
      expect(isHolidayNow, isFalse);
      expect(repo.isDateEffectiveHoliday(sunday), isFalse);

      // Reset override
      await repo.resetHolidayOverride(sunday);
      expect(repo.isDateEffectiveHoliday(sunday), isTrue);
    });
  });
}
