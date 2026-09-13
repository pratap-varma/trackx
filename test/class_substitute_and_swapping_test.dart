import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/semesters/domain/semester_model.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/core/services/widget_data_service.dart';
import 'package:trackx/features/timetable/data/repositories/class_substitute_repository.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';
import 'package:trackx/features/timetable/providers/timetable_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Class Substitute Repository & Persistence Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('1. Setting substitute persists across new instances (app restart simulation)', () async {
      final repo1 = ClassSubstituteRepository(prefs);
      final date = DateTime(2026, 9, 2);
      const entryId = 'entry-101';
      const substituteSubId = 'sub-physics';

      await repo1.setSubstitute(
        date: date,
        entryId: entryId,
        substituteSubjectId: substituteSubId,
      );

      expect(repo1.getSubstitute(date, entryId), equals('sub-physics'));

      // Simulate closing and reopening the app with a brand new repository reading same prefs
      final repo2 = ClassSubstituteRepository(prefs);
      expect(repo2.getSubstitute(date, entryId), equals('sub-physics'));
    });

    test('2. Removing substitute clears persistent storage', () async {
      final repo = ClassSubstituteRepository(prefs);
      final date = DateTime(2026, 9, 2);
      const entryId = 'entry-102';

      await repo.setSubstitute(
        date: date,
        entryId: entryId,
        substituteSubjectId: 'sub-chemistry',
      );
      expect(repo.getSubstitute(date, entryId), equals('sub-chemistry'));

      await repo.removeSubstitute(date: date, entryId: entryId);
      expect(repo.getSubstitute(date, entryId), isNull);

      // Verify simulated restart shows cleared
      final repoRestart = ClassSubstituteRepository(prefs);
      expect(repoRestart.getSubstitute(date, entryId), isNull);
    });

    test('3. TimetableEntry copyWith and isSubstituted flag works correctly', () {
      final entry = TimetableEntry(
        id: 'e1',
        userId: 'u1',
        semesterId: 'sem1',
        subjectId: 'sub-math',
        dayOfWeek: 1,
        periodNumber: 1,
        startTime: 540,
        endTime: 600,
        isEnabled: true,
        createdAt: 0,
        updatedAt: 0,
      );

      expect(entry.isSubstituted, isFalse);

      final swapped = entry.copyWith(
        subjectId: 'sub-physics',
        originalSubjectId: entry.subjectId,
      );

      expect(swapped.subjectId, equals('sub-physics'));
      expect(swapped.originalSubjectId, equals('sub-math'));
      expect(swapped.isSubstituted, isTrue);
    });
  });

  group('Timetable Period Swapping Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('4. swapPeriods atomically swaps two scheduled periods on same day', () async {
      final repo = TimetableRepository(prefs);

      final p1 = TimetableEntry(
        id: 'entry-p1',
        userId: 'u1',
        semesterId: 'sem-1',
        subjectId: 'sub-math',
        dayOfWeek: 1,
        periodNumber: 1,
        startTime: 555, // 9:15 AM
        endTime: 615,   // 10:15 AM
        isEnabled: true,
        createdAt: 0,
        updatedAt: 0,
      );

      final p2 = TimetableEntry(
        id: 'entry-p2',
        userId: 'u1',
        semesterId: 'sem-1',
        subjectId: 'sub-physics',
        dayOfWeek: 1,
        periodNumber: 2,
        startTime: 630, // 10:30 AM
        endTime: 690,   // 11:30 AM
        isEnabled: true,
        createdAt: 0,
        updatedAt: 0,
      );

      await repo.addEntry(p1);
      await repo.addEntry(p2);

      expect(repo.state.length, equals(2));

      // Swap period 1 and period 2
      final err = await repo.swapPeriods(
        semesterId: 'sem-1',
        dayOfWeek: 1,
        periodA: 1,
        periodB: 2,
      );

      expect(err, isNull);

      final swappedMath = repo.state.firstWhere((e) => e.id == 'entry-p1');
      final swappedPhysics = repo.state.firstWhere((e) => e.id == 'entry-p2');

      // Math is now Period 2 at 10:30
      expect(swappedMath.periodNumber, equals(2));
      expect(swappedMath.startTime, equals(630));
      expect(swappedMath.endTime, equals(690));

      // Physics is now Period 1 at 9:15
      expect(swappedPhysics.periodNumber, equals(1));
      expect(swappedPhysics.startTime, equals(555));
      expect(swappedPhysics.endTime, equals(615));

      // Verify persistence across reload
      final repoReloaded = TimetableRepository(prefs);
      final reloadedMath = repoReloaded.state.firstWhere((e) => e.id == 'entry-p1');
      expect(reloadedMath.periodNumber, equals(2));
    });
  });

  group('Provider Cascading & Widget Sync Tests', () {
    test('5. todayTimetableProvider reflects swapped/substitute class for current day', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final activeSem = Semester(
        id: 'sem-test',
        userId: 'u1',
        programmeId: 'prog-1',
        name: 'Fall 2026',
        semesterNumber: 1,
        academicYear: '2026-2027',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        status: 'Active',
        plannedCredits: 20,
        completedCredits: 0,
        attendanceTarget: 75.0,
        notes: '',
        createdAt: 0,
        updatedAt: 0,
      );

      final now = DateTime(2026, 9, 2, 10, 0); // Wednesday
      final dayOfWeek = now.weekday;

      final entry = TimetableEntry(
        id: 'slot-1',
        userId: 'u1',
        semesterId: 'sem-test',
        subjectId: 'sub-original',
        dayOfWeek: dayOfWeek,
        periodNumber: 1,
        startTime: now.hour * 60 + now.minute - 10,
        endTime: now.hour * 60 + now.minute + 50,
        isEnabled: true,
        createdAt: 0,
        updatedAt: 0,
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          activeSemesterProvider.overrideWithValue(activeSem),
          currentTimeProvider.overrideWithValue(now),
          timetableRepositoryProvider.overrideWith(
            (ref) => TimetableRepository(prefs, ref)..state = [entry],
          ),
        ],
      );

      // Initially, today's entry has sub-original
      final initialEntries = container.read(todayTimetableProvider);
      expect(initialEntries.isNotEmpty, isTrue);
      expect(initialEntries.first.subjectId, equals('sub-original'));
      expect(initialEntries.first.isSubstituted, isFalse);

      // Set substitute
      await container.read(classSubstituteRepositoryProvider.notifier).setSubstitute(
        date: now,
        entryId: 'slot-1',
        substituteSubjectId: 'sub-proxy',
      );

      // Now todayTimetableProvider must reflect sub-proxy
      final updatedEntries = container.read(todayTimetableProvider);
      expect(updatedEntries.first.subjectId, equals('sub-proxy'));
      expect(updatedEntries.first.originalSubjectId, equals('sub-original'));
      expect(updatedEntries.first.isSubstituted, isTrue);

      // currentClassProvider must also reflect sub-proxy
      final currentClass = container.read(currentClassProvider);
      expect(currentClass, isNotNull);
      expect(currentClass!.subjectId, equals('sub-proxy'));
      expect(currentClass.originalSubjectId, equals('sub-original'));
      expect(currentClass.isSubstituted, isTrue);

      // 6. Test WidgetDataService sync
      final subProxySubject = Subject(
        id: 'sub-proxy',
        userId: 'u1',
        semesterId: 'sem-test',
        name: 'Advanced Physics',
        facultyName: 'Dr. Feynman',
        colorValue: 0xFF5B5FEF,
        type: 'Theory',
        targetAttendance: 75.0,
        presentClasses: 8,
        absentClasses: 2,
        status: 'Active',
        expectedDifficulty: 'Medium',
        createdAt: 0,
        updatedAt: 0,
      );

      container.read(subjectRepositoryProvider.notifier).state = [subProxySubject];

      final widgetService = container.read(widgetDataServiceProvider);
      await widgetService.syncWithAppData(container);

      final widgetJson = prefs.getString('px_home_widgets_data_v2');
      expect(widgetJson, isNotNull);
      expect(widgetJson!.contains('Advanced Physics (Proxy)'), isTrue);
    });
  });
}
