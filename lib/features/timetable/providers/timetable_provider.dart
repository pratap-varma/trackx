import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/calendar/providers/calendar_provider.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';

// StateProvider to track the selected weekday tab (1 = Monday, 6 = Saturday)
final selectedTimetableDayProvider = StateProvider<int>((ref) {
  final now = DateTime.now();
  // Map Sunday (7) to Monday (1)
  return now.weekday == 7 ? 1 : now.weekday;
});

// Mockable current time provider for testability
final currentTimeProvider = Provider<DateTime>((ref) => DateTime.now());

// Filters timetable entries for the active semester
final activeSemesterTimetableProvider = Provider<List<TimetableEntry>>((ref) {
  final entries = ref.watch(timetableRepositoryProvider);
  final activeSem = ref.watch(activeSemesterProvider);

  if (activeSem == null) return [];
  return entries.where((e) => e.semesterId == activeSem.id).toList();
});

// Returns today's active timetable entries, sorted by startTime
final todayTimetableProvider = Provider<List<TimetableEntry>>((ref) {
  final entries = ref.watch(activeSemesterTimetableProvider);
  final now = ref.watch(currentTimeProvider);

  // If today is an effective holiday (Sunday, Saturday, public holiday, college holiday)
  final isHoliday = ref.watch(isHolidayDateProvider(now));
  if (isHoliday) return [];

  final overrideDay = ref.watch(dayOfWeekOverrideProvider(now));
  final effectiveDayOfWeek = overrideDay ?? now.weekday;

  final today = entries
      .where((e) => e.dayOfWeek == effectiveDayOfWeek && e.isEnabled)
      .toList();
  today.sort((a, b) => a.startTime.compareTo(b.startTime));
  return today;
});

// Identifies the active class (if any)
final currentClassProvider = Provider<TimetableEntry?>((ref) {
  final todayEntries = ref.watch(todayTimetableProvider);
  final now = ref.watch(currentTimeProvider);

  for (final entry in todayEntries) {
    if (entry.isCurrent(now)) return entry;
  }
  return null;
});

// Identifies the next upcoming class
final nextClassProvider = Provider<TimetableEntry?>((ref) {
  final todayEntries = ref.watch(todayTimetableProvider);
  final now = ref.watch(currentTimeProvider);
  final currentMinutes = now.hour * 60 + now.minute;

  for (final entry in todayEntries) {
    if (entry.startTime > currentMinutes) return entry;
  }
  return null;
});

// Identifies completed classes today that have not been logged in attendance
final completedUnmarkedClassesProvider = Provider<List<TimetableEntry>>((ref) {
  final todayEntries = ref.watch(todayTimetableProvider);
  final now = ref.watch(currentTimeProvider);
  final attendance = ref.watch(attendanceRepositoryProvider);
  final activeSem = ref.watch(activeSemesterProvider);

  if (activeSem == null) return [];

  // Filter for completed classes
  final completed = todayEntries.where((e) => e.isCompleted(now)).toList();

  // Find matches in attendance logs
  final unmarked = completed.where((entry) {
    final hasRecord = attendance.any(
      (rec) =>
          rec.semesterId == activeSem.id &&
          rec.subjectId == entry.subjectId &&
          rec.periodNumber == entry.periodNumber &&
          rec.date.year == now.year &&
          rec.date.month == now.month &&
          rec.date.day == now.day,
    );
    return !hasRecord;
  }).toList();

  return unmarked;
});
