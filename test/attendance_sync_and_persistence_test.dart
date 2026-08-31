import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/ai_assistant/data/services/ai_context_builder.dart';
import 'package:trackx/core/models/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Attendance Synchronization & App-Wide Real-Time Propagation Tests', () {
    test('1. Marking attendance synchronizes Subject.presentClasses and absentClasses in real time', () async {
      final subjectRepo = container.read(subjectRepositoryProvider.notifier);
      final attendanceRepo = container.read(attendanceRepositoryProvider.notifier);

      // Create a test subject
      await subjectRepo.addSubject(
        'sem-1',
        'Operating Systems',
        'Prof. Andrew',
        0xFF5B5FEF,
        75.0,
        code: 'CS401',
      );

      var subjects = container.read(subjectRepositoryProvider);
      expect(subjects.length, 1);
      final sub = subjects.first;
      expect(sub.presentClasses, 0);
      expect(sub.absentClasses, 0);

      // Mark Attendance as Present
      await attendanceRepo.markAttendance(
        userId: 'user-1',
        semesterId: 'sem-1',
        subjectId: sub.id,
        date: DateTime(2026, 8, 30, 10),
        periodNumber: 1,
        status: 'present',
      );

      // Verify AttendanceRepository state
      final records = container.read(attendanceRepositoryProvider);
      expect(records.length, 1);
      expect(records.first.status, 'present');

      // Verify SubjectRepository has synchronized counts!
      subjects = container.read(subjectRepositoryProvider);
      expect(subjects.first.presentClasses, 1);
      expect(subjects.first.absentClasses, 0);

      // Mark Attendance for another period as Absent
      await attendanceRepo.markAttendance(
        userId: 'user-1',
        semesterId: 'sem-1',
        subjectId: sub.id,
        date: DateTime(2026, 8, 30, 11),
        periodNumber: 2,
        status: 'absent',
      );

      subjects = container.read(subjectRepositoryProvider);
      expect(subjects.first.presentClasses, 1);
      expect(subjects.first.absentClasses, 1);
    });

    test('2. Deleting attendance record accurately updates Subject counts', () async {
      final subjectRepo = container.read(subjectRepositoryProvider.notifier);
      final attendanceRepo = container.read(attendanceRepositoryProvider.notifier);

      await subjectRepo.addSubject(
        'sem-1',
        'Database Management Systems',
        'Prof. Edgar',
        0xFF10B981,
        75.0,
      );

      final sub = container.read(subjectRepositoryProvider).first;

      await attendanceRepo.markAttendance(
        userId: 'user-1',
        semesterId: 'sem-1',
        subjectId: sub.id,
        date: DateTime(2026, 8, 30, 9),
        periodNumber: 1,
        status: 'present',
      );

      var records = container.read(attendanceRepositoryProvider);
      expect(records.length, 1);
      expect(container.read(subjectRepositoryProvider).first.presentClasses, 1);

      // Delete the record
      await attendanceRepo.deleteAttendance(records.first.id);

      records = container.read(attendanceRepositoryProvider);
      expect(records.isEmpty, true);

      final updatedSub = container.read(subjectRepositoryProvider).first;
      expect(updatedSub.presentClasses, 0);
      expect(updatedSub.absentClasses, 0);
    });

    test('3. Offline / Guest mode preserves attendance and subjects without being wiped', () async {
      final subjectRepo = container.read(subjectRepositoryProvider.notifier);
      final attendanceRepo = container.read(attendanceRepositoryProvider.notifier);

      // Add subject and record with empty / guest userId
      await subjectRepo.addSubject(
        'sem-default',
        'Computer Networks',
        'Prof. Tanenbaum',
        0xFF7BD0FF,
        75.0,
      );

      final sub = container.read(subjectRepositoryProvider).first;

      await attendanceRepo.markAttendance(
        userId: '',
        semesterId: 'sem-default',
        subjectId: sub.id,
        date: DateTime(2026, 8, 30, 14),
        periodNumber: 3,
        status: 'present',
      );

      expect(container.read(attendanceRepositoryProvider).length, 1);

      // Create fresh container simulating app restart
      final freshContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final freshSubjects = freshContainer.read(subjectRepositoryProvider);
      final freshRecords = freshContainer.read(attendanceRepositoryProvider);

      expect(freshSubjects.isNotEmpty, true);
      expect(freshSubjects.first.name, 'Computer Networks');
      expect(freshRecords.isNotEmpty, true);
      expect(freshRecords.first.status, 'present');
      expect(freshSubjects.first.presentClasses, 1);

      freshContainer.dispose();
    });

    test('4. AiContextBuilder derives accurate attendance percentage from synchronized records', () {
      final profile = UserProfile(
        id: 'u1',
        name: 'Test Student',
        email: 'test@example.com',
        branch: 'CSE',
        semester: 4,
        globalTarget: 75.0,
        themeMode: 'dark',
        themeColorPack: 'purple',
        onboardingCompleted: true,
        createdTimestamp: 1000,
        updatedTimestamp: 1000,
        programmeName: 'B.Tech',
        currentSemesterId: 'sem-1',
      );

      final sub = Subject(
        id: 'sub-1',
        userId: 'u1',
        semesterId: 'sem-1',
        name: 'Algorithms',
        facultyName: 'Dr. Cormen',
        colorValue: 0xFF5B5FEF,
        type: 'Theory',
        targetAttendance: 75.0,
        presentClasses: 3,
        absentClasses: 1,
        status: 'Active',
        expectedDifficulty: 'Moderate',
        createdAt: 100,
        updatedAt: 100,
      );

      final attendance = [
        AttendanceRecord(
          id: 'a1',
          userId: 'u1',
          semesterId: 'sem-1',
          subjectId: 'sub-1',
          date: DateTime(2026, 8, 28),
          periodNumber: 1,
          status: 'present',
          source: 'manual',
          createdAt: 100,
          updatedAt: 100,
        ),
        AttendanceRecord(
          id: 'a2',
          userId: 'u1',
          semesterId: 'sem-1',
          subjectId: 'sub-1',
          date: DateTime(2026, 8, 29),
          periodNumber: 1,
          status: 'present',
          source: 'manual',
          createdAt: 100,
          updatedAt: 100,
        ),
        AttendanceRecord(
          id: 'a3',
          userId: 'u1',
          semesterId: 'sem-1',
          subjectId: 'sub-1',
          date: DateTime(2026, 8, 30),
          periodNumber: 1,
          status: 'absent',
          source: 'manual',
          createdAt: 100,
          updatedAt: 100,
        ),
      ];

      final aiContext = AiContextBuilder.build(
        profile: profile,
        semesters: [],
        subjects: [sub],
        attendance: attendance,
        tasks: [],
        assignments: [],
        exams: [],
        timetable: [],
        consentFlags: {'attendance': true},
      );

      expect(aiContext.subjects.length, 1);
      // 2 present out of 3 sessions = 66.67%
      expect(aiContext.subjects.first.currentAttendance, closeTo(66.67, 0.1));
    });
  });
}
