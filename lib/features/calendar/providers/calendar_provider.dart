import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/core/services/google_calendar_service.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/calendar/data/repositories/calendar_repository.dart';
import 'package:trackx/features/calendar/domain/models/calendar_event_model.dart';

final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  return GoogleCalendarService();
});

final calendarRepositoryProvider =
    StateNotifierProvider<CalendarRepository, List<CalendarEvent>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      final service = ref.watch(googleCalendarServiceProvider);
      return CalendarRepository(prefs, service, ref);
    });

final isCalendarConnectedProvider = Provider<bool>((ref) {
  ref.watch(calendarRepositoryProvider);
  final repo = ref.read(calendarRepositoryProvider.notifier);
  return repo.isConnected();
});

final userCalendarsListProvider = Provider<List<UserCalendarInfo>>((ref) {
  ref.watch(calendarRepositoryProvider);
  final repo = ref.read(calendarRepositoryProvider.notifier);
  return repo.availableCalendars;
});

final calendarLastSyncTimeProvider = Provider<DateTime?>((ref) {
  ref.watch(calendarRepositoryProvider);
  final repo = ref.read(calendarRepositoryProvider.notifier);
  return repo.lastSyncTime;
});

final calendarRegionProvider = Provider<String>((ref) {
  ref.watch(calendarRepositoryProvider);
  final repo = ref.read(calendarRepositoryProvider.notifier);
  return repo.getRegion();
});

/// All calendar events for selected date
final eventsForSelectedDateProvider =
    Provider.family<List<CalendarEvent>, DateTime>((ref, date) {
      final events = ref.watch(calendarRepositoryProvider);
      return events.where((h) => h.occursOn(date)).toList();
    });

/// Public holidays & festivals for selected date (including user overrides)
final holidaysForSelectedDateProvider =
    Provider.family<List<CalendarEvent>, DateTime>((ref, date) {
      ref.watch(calendarRepositoryProvider);
      final repo = ref.read(calendarRepositoryProvider.notifier);
      return repo.getEffectiveHolidaysForDate(date);
    });

/// Boolean helper to check if date is an effective holiday
final isHolidayDateProvider = Provider.family<bool, DateTime>((ref, date) {
  ref.watch(calendarRepositoryProvider);
  final repo = ref.read(calendarRepositoryProvider.notifier);
  return repo.isDateEffectiveHoliday(date);
});

/// Helper to check if user has custom overridden this date
final isHolidayOverriddenProvider =
    Provider.family<bool, DateTime>((ref, date) {
      ref.watch(calendarRepositoryProvider);
      final repo = ref.read(calendarRepositoryProvider.notifier);
      return repo.isHolidayOverriddenToWorking(date) ||
          repo.isCustomHolidayDeclared(date);
    });

/// Personal / work calendar events for selected date
final personalEventsForSelectedDateProvider =
    Provider.family<List<CalendarEvent>, DateTime>((ref, date) {
      final events = ref.watch(calendarRepositoryProvider);
      return events
          .where((h) => h.occursOn(date) && !h.isHolidayOrFestival)
          .toList();
    });
