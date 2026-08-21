import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/calendar/providers/calendar_provider.dart';
import 'package:trackx/features/planner/domain/models/calendar_conflict_model.dart';
import 'package:trackx/features/planner/domain/services/calendar_conflict_service.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';

final calendarConflictServiceProvider = Provider<CalendarConflictService>((
  ref,
) {
  return const CalendarConflictService();
});

/// Computes schedule conflicts on a given target date
final conflictsForSelectedDateProvider =
    Provider.family<List<CalendarConflict>, DateTime>((ref, date) {
      final service = ref.watch(calendarConflictServiceProvider);
      final timetableEntries = ref.watch(timetableRepositoryProvider);
      final subjects = ref.watch(subjectRepositoryProvider);
      final tasks = ref.watch(tasksProvider);
      final calendarEvents = ref.watch(calendarRepositoryProvider);

      return service.detectConflictsForDate(
        date: date,
        timetableEntries: timetableEntries,
        subjects: subjects,
        tasks: tasks,
        calendarEvents: calendarEvents,
      );
    });

/// Quick boolean check for date badges/indicators
final hasConflictOnDateProvider = Provider.family<bool, DateTime>((ref, date) {
  final conflicts = ref.watch(conflictsForSelectedDateProvider(date));
  return conflicts.isNotEmpty;
});
