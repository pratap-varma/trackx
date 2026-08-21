import 'package:trackx/features/calendar/domain/models/calendar_event_model.dart';
import 'package:trackx/features/planner/domain/models/calendar_conflict_model.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';

class CalendarConflictService {
  const CalendarConflictService();

  /// Parse time strings like "14:30", "2:30 PM", "9:15 AM" into hour and minute
  static (int, int)? parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    final clean = timeStr.trim().toUpperCase();

    final isPm = clean.contains('PM');
    final isAm = clean.contains('AM');
    final digitsOnly = clean.replaceAll(RegExp(r'[^0-9:]'), '');
    final parts = digitsOnly.split(':');

    if (parts.isEmpty) return null;
    int hour = int.tryParse(parts[0]) ?? 0;
    int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    if (isPm && hour < 12) {
      hour += 12;
    } else if (isAm && hour == 12) {
      hour = 0;
    }

    return (hour.clamp(0, 23), minute.clamp(0, 59));
  }

  /// Detect all conflicts on a specific target date
  List<CalendarConflict> detectConflictsForDate({
    required DateTime date,
    required List<TimetableEntry> timetableEntries,
    required List<Subject> subjects,
    required List<Task> tasks,
    required List<CalendarEvent> calendarEvents,
  }) {
    final scheduleItems = <ConflictScheduleItem>[];

    // 1. Map college classes on this weekday
    for (final entry in timetableEntries) {
      if (!entry.isEnabled || entry.dayOfWeek != date.weekday) continue;
      final subject = subjects.cast<Subject?>().firstWhere(
        (s) => s?.id == entry.subjectId,
        orElse: () => null,
      );

      final start = entry.toDateTime(date, entry.startTime);
      final end = entry.toDateTime(date, entry.endTime);

      if (start.isBefore(end)) {
        scheduleItems.add(
          ConflictScheduleItem(
            id: 'class_${entry.id}',
            title: subject?.name ?? 'Class',
            itemType: ConflictItemType.collegeClass,
            startDateTime: start,
            endDateTime: end,
            subtitle: entry.room != null
                ? 'Room: ${entry.room}'
                : 'College Timetable',
            location: entry.room,
          ),
        );
      }
    }

    // 2. Map study planner tasks on this date with scheduled times
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    for (final task in tasks) {
      if (task.isCompleted) continue;
      final taskDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      if (taskDate != dateStart) continue;

      final parsed = parseTimeString(task.dueTime);
      if (parsed != null) {
        final (hour, minute) = parsed;
        final start = DateTime(date.year, date.month, date.day, hour, minute);
        // Default task duration 60 minutes
        final end = start.add(const Duration(minutes: 60));

        scheduleItems.add(
          ConflictScheduleItem(
            id: 'task_${task.id}',
            title: task.title,
            itemType: ConflictItemType.studyTask,
            startDateTime: start,
            endDateTime: end,
            subtitle: 'Category: ${task.category}',
          ),
        );
      }
    }

    // 3. Map personal Google Calendar events on this date (excluding all-day holidays)
    for (final event in calendarEvents) {
      if (event.isAllDay || event.isHolidayOrFestival) continue;
      if (!event.occursOn(date)) continue;

      final localStart = event.startDateTime.toLocal();
      final localEnd = event.endDateTime.toLocal();

      // Clamp to selected day for same-day conflict assessment
      final effectiveStart = localStart.isBefore(dateStart)
          ? dateStart
          : localStart;
      final effectiveEnd = localEnd.isAfter(dateEnd) ? dateEnd : localEnd;

      if (effectiveStart.isBefore(effectiveEnd)) {
        scheduleItems.add(
          ConflictScheduleItem(
            id: 'gcal_${event.calendarId}_${event.id}',
            title: event.title,
            itemType: ConflictItemType.googleEvent,
            startDateTime: effectiveStart,
            endDateTime: effectiveEnd,
            subtitle: event.calendarName,
            location: event.location,
          ),
        );
      }
    }

    // 4. Overlap Detection Engine
    scheduleItems.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    final conflicts = <CalendarConflict>[];
    final seenPairs = <String>{};

    for (int i = 0; i < scheduleItems.length; i++) {
      for (int j = i + 1; j < scheduleItems.length; j++) {
        final itemA = scheduleItems[i];
        final itemB = scheduleItems[j];

        // If itemB starts at or after itemA ends, no overlap with itemA (and subsequent sorted items)
        if (!itemB.startDateTime.isBefore(itemA.endDateTime)) {
          break;
        }

        // Overlap exists: startA < endB && startB < endA
        final overlapStart = itemA.startDateTime.isAfter(itemB.startDateTime)
            ? itemA.startDateTime
            : itemB.startDateTime;
        final overlapEnd = itemA.endDateTime.isBefore(itemB.endDateTime)
            ? itemA.endDateTime
            : itemB.endDateTime;

        if (overlapEnd.isAfter(overlapStart)) {
          final pairKey = '${itemA.id}__${itemB.id}';
          if (!seenPairs.contains(pairKey)) {
            seenPairs.add(pairKey);

            final conflictType = _resolveConflictType(
              itemA.itemType,
              itemB.itemType,
            );
            final overlapMins = overlapEnd.difference(overlapStart).inMinutes;
            final severity = overlapMins >= 30
                ? ConflictSeverity.high
                : ConflictSeverity.warning;

            conflicts.add(
              CalendarConflict(
                id: 'conflict_${itemA.id}_${itemB.id}',
                firstEvent: itemA,
                secondEvent: itemB,
                startDateTime: overlapStart,
                endDateTime: overlapEnd,
                conflictType: conflictType,
                severity: severity,
              ),
            );
          }
        }
      }
    }

    return conflicts;
  }

  ConflictType _resolveConflictType(
    ConflictItemType typeA,
    ConflictItemType typeB,
  ) {
    if ((typeA == ConflictItemType.collegeClass &&
            typeB == ConflictItemType.googleEvent) ||
        (typeA == ConflictItemType.googleEvent &&
            typeB == ConflictItemType.collegeClass)) {
      return ConflictType.classAndGoogleEvent;
    }
    if ((typeA == ConflictItemType.collegeClass &&
            typeB == ConflictItemType.studyTask) ||
        (typeA == ConflictItemType.studyTask &&
            typeB == ConflictItemType.collegeClass)) {
      return ConflictType.classAndStudyTask;
    }
    if ((typeA == ConflictItemType.studyTask &&
            typeB == ConflictItemType.googleEvent) ||
        (typeA == ConflictItemType.googleEvent &&
            typeB == ConflictItemType.studyTask)) {
      return ConflictType.studyTaskAndGoogleEvent;
    }
    if (typeA == ConflictItemType.googleEvent &&
        typeB == ConflictItemType.googleEvent) {
      return ConflictType.googleEventAndGoogleEvent;
    }
    return ConflictType.multipleEvents;
  }
}
