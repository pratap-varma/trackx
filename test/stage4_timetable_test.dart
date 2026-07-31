import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';

void main() {
  group('Stage 4 - Timetable Unit & Conflict Tests', () {
    test('TimetableEntry Serialization matches specification', () {
      final entry = TimetableEntry(
        id: 'e1',
        userId: 'u1',
        semesterId: 's1',
        subjectId: 'sub1',
        dayOfWeek: 1, // Monday
        periodNumber: 2,
        startTime: 615, // 10:15 AM
        endTime: 675, // 11:15 AM
        room: 'B-302',
        notes: 'Odd weeks',
        isEnabled: true,
        createdAt: 10,
        updatedAt: 20,
      );

      final map = entry.toMap();
      final fromMap = TimetableEntry.fromMap(map);

      expect(fromMap.id, 'e1');
      expect(fromMap.startTime, 615);
      expect(fromMap.endTime, 675);
      expect(fromMap.room, 'B-302');
      expect(fromMap.isEnabled, true);
    });

    test(
      'Conflict checker prevents overlapping schedules on same day',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repo = TimetableRepository(prefs);

        // Period 1: 9:15 - 10:15
        final baseEntry = TimetableEntry(
          id: 'e1',
          userId: 'u1',
          semesterId: 's1',
          subjectId: 'sub1',
          dayOfWeek: 1,
          periodNumber: 1,
          startTime: 555,
          endTime: 615,
          isEnabled: true,
          createdAt: 0,
          updatedAt: 0,
        );

        await repo.addEntry(baseEntry);

        // Duplicate period on same day
        final dupPeriod = baseEntry.copyWith(id: 'e2', subjectId: 'sub2');
        expect(
          repo.verifyConflict(dupPeriod),
          'Period 1 is already occupied on this day.',
        );

        // Time overlap: starts 9:45, ends 10:45 (partially inside 9:15-10:15)
        final overlap = baseEntry.copyWith(
          id: 'e3',
          periodNumber: 2,
          startTime: 585,
          endTime: 645,
        );
        expect(
          repo.verifyConflict(overlap),
          startsWith('Time overlaps with scheduled class'),
        );

        // Non-overlapping class: starts 10:15, ends 11:15
        final distinct = baseEntry.copyWith(
          id: 'e4',
          periodNumber: 2,
          startTime: 615,
          endTime: 675,
        );
        expect(repo.verifyConflict(distinct), null);
      },
    );

    test('Current and Completed logic is accurate', () {
      final entry = TimetableEntry(
        id: 'e1',
        userId: 'u1',
        semesterId: 's1',
        subjectId: 'sub1',
        dayOfWeek: 1, // Monday
        periodNumber: 1,
        startTime: 555, // 9:15 AM
        endTime: 615, // 10:15 AM
        isEnabled: true,
        createdAt: 0,
        updatedAt: 0,
      );

      // Assume it's Monday 9:30 AM (Weekday = 1, currentMinutes = 570)
      final monday930 = DateTime(2026, 7, 13, 9, 30); // 2026-07-13 is a Monday
      expect(entry.isCurrent(monday930), true);
      expect(entry.isCompleted(monday930), false);

      // Assume it's Monday 11:00 AM (completed)
      final monday1100 = DateTime(2026, 7, 13, 11, 00);
      expect(entry.isCurrent(monday1100), false);
      expect(entry.isCompleted(monday1100), true);

      // Assume it's Tuesday (different day, shouldn't match current)
      final tuesday930 = DateTime(2026, 7, 14, 9, 30);
      expect(entry.isCurrent(tuesday930), false);
    });
  });
}
