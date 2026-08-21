import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/core/services/persistence_service.dart';
import 'package:trackx/core/utils/attendance_calculator.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';

void main() {
  group('Production Data Flow Audit Tests', () {
    late SharedPreferences prefs;
    late PersistenceService persistence;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      persistence = PersistenceService(prefs);

      // Authenticate a real test user
      final profile = UserProfile(
        id: 'usr_audit_1',
        name: 'Jane Doe',
        email: 'jane@college.edu',
        branch: 'Computer Science',
        semester: 1,
        globalTarget: 75.0,
        themeMode: 'dark',
        themeColorPack: 'purple',
        onboardingCompleted: true,
        createdTimestamp: DateTime.now().millisecondsSinceEpoch,
        updatedTimestamp: DateTime.now().millisecondsSinceEpoch,
      );
      await persistence.saveUserProfile(profile);
      await persistence.saveAuthToken('token_1');

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          persistenceServiceProvider.overrideWithValue(persistence),
        ],
      );

      // Create an active semester
      await container
          .read(semesterRepositoryProvider.notifier)
          .createSemester(
            'Fall 2026',
            1,
            DateTime(2026, 8, 1),
            DateTime(2026, 12, 15),
            status: 'Active',
          );
    });

    tearDown(() {
      container.dispose();
    });

    test('1. Clean account initializes with ZERO academic records', () {
      final subjects = container.read(subjectRepositoryProvider);
      final timetable = container.read(timetableRepositoryProvider);
      final attendance = container.read(attendanceRepositoryProvider);
      final tasks = container.read(tasksProvider);
      final exams = container.read(examsProvider);
      final stats = container.read(statsProvider);

      expect(subjects, isEmpty);
      expect(timetable, isEmpty);
      expect(attendance, isEmpty);
      expect(tasks, isEmpty);
      expect(exams, isEmpty);
      expect(stats.totalRecorded, 0);
      expect(stats.totalPresent, 0);
      expect(stats.overallPercentage, 0.0);
    });

    test(
      '2. Planner & Timetable Reactive Data Flow with immediate CRUD propagation',
      () async {
        final subRepo = container.read(subjectRepositoryProvider.notifier);
        final ttRepo = container.read(timetableRepositoryProvider.notifier);
        final activeSem = container.read(activeSemesterProvider)!;

        // Create 2 subjects
        await subRepo.addSubject(
          activeSem.id,
          'Data Structures',
          'Prof. Smith',
          0xFF5B5FEF,
          75.0,
        );
        await subRepo.addSubject(
          activeSem.id,
          'DBMS',
          'Dr. Brown',
          0xFF10B981,
          75.0,
        );

        final subjects = container.read(subjectRepositoryProvider);
        final dsId = subjects.firstWhere((s) => s.name == 'Data Structures').id;
        final dbmsId = subjects.firstWhere((s) => s.name == 'DBMS').id;

        // Add 2 timetable entries on Monday (dayOfWeek = 1)
        final dsEntry = TimetableEntry(
          id: 'entry_ds',
          userId: 'usr_audit_1',
          semesterId: activeSem.id,
          subjectId: dsId,
          dayOfWeek: 1,
          periodNumber: 1,
          startTime: 9 * 60 + 15, // 09:15
          endTime: 10 * 60 + 15, // 10:15
          room: 'LH-1',
          isEnabled: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        final dbmsEntry = TimetableEntry(
          id: 'entry_dbms',
          userId: 'usr_audit_1',
          semesterId: activeSem.id,
          subjectId: dbmsId,
          dayOfWeek: 1,
          periodNumber: 2,
          startTime: 10 * 60 + 15, // 10:15
          endTime: 11 * 60 + 15, // 11:15
          room: 'Lab-2',
          isEnabled: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await ttRepo.addEntry(dsEntry);
        await ttRepo.addEntry(dbmsEntry);

        // Verify timetable state has both entries
        var currentTT = container.read(timetableRepositoryProvider);
        expect(currentTT.length, 2);
        expect(currentTT.map((e) => e.subjectId), containsAll([dsId, dbmsId]));

        // Verify today timetable provider filters properly for Monday
        final mondayTime = DateTime(
          2026,
          8,
          24,
          9,
          30,
        ); // 2026-08-24 is a Monday
        final mondayClasses =
            currentTT
                .where((e) => e.dayOfWeek == mondayTime.weekday && e.isEnabled)
                .toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));
        expect(mondayClasses.length, 2);
        expect(mondayClasses[0].subjectId, dsId);
        expect(mondayClasses[1].subjectId, dbmsId);

        // Delete DBMS
        await ttRepo.deleteEntry('entry_dbms');

        // Verify Planner/Timetable immediately stops displaying DBMS
        currentTT = container.read(timetableRepositoryProvider);
        expect(currentTT.length, 1);
        expect(currentTT.first.subjectId, dsId);
        expect(currentTT.any((e) => e.subjectId == dbmsId), isFalse);
      },
    );

    test(
      '3. Attendance Flow: Subject connection & statistics consistency',
      () async {
        final subRepo = container.read(subjectRepositoryProvider.notifier);
        final attRepo = container.read(attendanceRepositoryProvider.notifier);
        final activeSem = container.read(activeSemesterProvider)!;

        await subRepo.addSubject(
          activeSem.id,
          'Data Structures',
          'Prof. Smith',
          0xFF5B5FEF,
          75.0,
        );
        final dsId = container.read(subjectRepositoryProvider).first.id;

        // Mark: Present, Present, Absent (Total = 3, Present = 2, Absent = 1)
        await attRepo.markAttendance(
          userId: 'usr_audit_1',
          semesterId: activeSem.id,
          subjectId: dsId,
          date: DateTime(2026, 8, 10),
          status: 'present',
        );
        await attRepo.markAttendance(
          userId: 'usr_audit_1',
          semesterId: activeSem.id,
          subjectId: dsId,
          date: DateTime(2026, 8, 11),
          status: 'present',
        );
        await attRepo.markAttendance(
          userId: 'usr_audit_1',
          semesterId: activeSem.id,
          subjectId: dsId,
          date: DateTime(2026, 8, 12),
          status: 'absent',
        );

        final records = container.read(attendanceRepositoryProvider);
        expect(records.length, 3);
        expect(records.where((r) => r.status == 'present').length, 2);
        expect(records.where((r) => r.status == 'absent').length, 1);

        // Verify StatsProvider calculates exact same values for Dashboard and Analytics
        final stats = container.read(statsProvider);
        expect(stats.totalRecorded, 3);
        expect(stats.totalPresent, 2);
        // 2 / 3 * 100 = 66.66666...
        expect(stats.overallPercentage, closeTo(66.67, 0.01));

        final subStats = stats.allSubjectStats.firstWhere(
          (s) => s.subject.id == dsId,
        );
        expect(subStats.totalCount, 3);
        expect(subStats.presentCount, 2);
        expect(subStats.absentCount, 1);
        expect(subStats.percentage, closeTo(66.67, 0.01));

        // AttendanceCalculator consistency check
        final safeBunks = AttendanceCalculator.calculateSafeBunks(2, 3, 75.0);
        expect(safeBunks, 0); // At 66.67% vs 75% target, cannot safely bunk

        final recovery = AttendanceCalculator.calculateRequiredRecovery(
          2,
          3,
          75.0,
        );
        expect(
          recovery,
          1,
        ); // Attending 1 more class: (2+1)/(3+1) = 3/4 = 75.0%
        expect(subStats.requiredRecovery, recovery);
      },
    );

    test(
      '4. Cascade Subject Deletion removes dependent timetable & attendance records',
      () async {
        final subRepo = container.read(subjectRepositoryProvider.notifier);
        final ttRepo = container.read(timetableRepositoryProvider.notifier);
        final attRepo = container.read(attendanceRepositoryProvider.notifier);
        final activeSem = container.read(activeSemesterProvider)!;

        await subRepo.addSubject(
          activeSem.id,
          'Algorithms',
          'Prof. Miller',
          0xFF5B5FEF,
          75.0,
        );
        final algoId = container.read(subjectRepositoryProvider).first.id;

        // Add timetable entry and attendance record for Algorithms
        await ttRepo.addEntry(
          TimetableEntry(
            id: 'tt_algo',
            userId: 'usr_audit_1',
            semesterId: activeSem.id,
            subjectId: algoId,
            dayOfWeek: 2,
            periodNumber: 1,
            startTime: 9 * 60,
            endTime: 10 * 60,
            isEnabled: true,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        await attRepo.markAttendance(
          userId: 'usr_audit_1',
          semesterId: activeSem.id,
          subjectId: algoId,
          date: DateTime.now(),
          status: 'present',
        );

        expect(container.read(timetableRepositoryProvider).length, 1);
        expect(container.read(attendanceRepositoryProvider).length, 1);

        // Delete the subject
        await subRepo.deleteSubject(algoId);

        // Verify subject, timetable entries, and attendance records are all cleaned up
        expect(container.read(subjectRepositoryProvider), isEmpty);
        expect(container.read(timetableRepositoryProvider), isEmpty);
        expect(container.read(attendanceRepositoryProvider), isEmpty);
      },
    );
  });
}
