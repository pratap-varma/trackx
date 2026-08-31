import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/notifications/domain/daily_digest_model.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';

void main() {
  final sampleSubject1 = Subject(
    id: 'sub-dbms',
    userId: 'u1',
    semesterId: 'sem-1',
    name: 'DBMS',
    code: 'CS301',
    facultyName: 'Dr. Rao',
    colorValue: 0xFF5B5FEF,
    type: 'Theory',
    targetAttendance: 75.0,
    presentClasses: 6,
    absentClasses: 4,
    status: 'Active',
    expectedDifficulty: 'Moderate',
    createdAt: 0,
    updatedAt: 0,
  );

  final sampleSubject2 = Subject(
    id: 'sub-os',
    userId: 'u1',
    semesterId: 'sem-1',
    name: 'Operating Systems',
    code: 'CS302',
    facultyName: 'Dr. Kumar',
    colorValue: 0xFF10B981,
    type: 'Theory',
    targetAttendance: 75.0,
    presentClasses: 15,
    absentClasses: 5,
    status: 'Active',
    expectedDifficulty: 'Challenging',
    createdAt: 0,
    updatedAt: 0,
  );

  final sampleEntry = TimetableEntry(
    id: 'entry-1',
    userId: 'u1',
    semesterId: 'sem-1',
    subjectId: 'sub-dbms',
    dayOfWeek: 2,
    startTime: 9 * 60, // 09:00 AM
    endTime: 10 * 60, // 10:00 AM
    room: 'Lab 3',
    periodNumber: 1,
    isEnabled: true,
    createdAt: 0,
    updatedAt: 0,
  );

  group('DailyDigestComposer Content Generation', () {
    test('New user with no subjects configured receives onboarding prompt', () {
      final message = DailyDigestComposer.compose(
        todayClasses: [],
        allSubjectStats: [],
        todayTasks: [],
        upcomingExams: [],
        hasSubjectsConfigured: false,
      );

      expect(message.title, contains('Welcome'));
      expect(message.body, contains('Set up your timetable'));
      expect(message.isUrgent, isFalse);
    });

    test('Critical attendance deficit leads with urgent recovery warning', () {
      final stats = [
        SubjectStats(
          subject: sampleSubject1,
          presentCount: 6,
          absentCount: 4,
          totalCount: 10,
          percentage: 60.0,
          safeBunks: 0,
          requiredRecovery: 6,
          riskLevel: 'critical',
          target: 75.0,
        ),
      ];

      final message = DailyDigestComposer.compose(
        todayClasses: [sampleEntry],
        allSubjectStats: stats,
        todayTasks: [],
        upcomingExams: [],
        hasSubjectsConfigured: true,
      );

      expect(message.isUrgent, isTrue);
      expect(message.title, contains('Attendance Alert'));
      expect(message.body, contains('DBMS is at 60%'));
      expect(message.body, contains('Attend 6 more'));
      expect(message.body, contains('1 class today'));
    });

    test('Threshold warning (0 safe bunks) warns before dropping below target', () {
      final stats = [
        SubjectStats(
          subject: sampleSubject2,
          presentCount: 15,
          absentCount: 5,
          totalCount: 20,
          percentage: 75.0,
          safeBunks: 0,
          requiredRecovery: 0,
          riskLevel: 'warning',
          target: 75.0,
        ),
      ];

      final message = DailyDigestComposer.compose(
        todayClasses: [sampleEntry],
        allSubjectStats: stats,
        todayTasks: [],
        upcomingExams: [],
        hasSubjectsConfigured: true,
      );

      expect(message.isUrgent, isTrue);
      expect(message.title, contains('Attendance Heads-Up'));
      expect(message.body, contains('1 more miss and you drop below 75%'));
    });

    test('Healthy attendance day gives calm summary with class count', () {
      final stats = [
        SubjectStats(
          subject: sampleSubject1,
          presentCount: 18,
          absentCount: 2,
          totalCount: 20,
          percentage: 90.0,
          safeBunks: 3,
          requiredRecovery: 0,
          riskLevel: 'safe',
          target: 75.0,
        ),
      ];

      final message = DailyDigestComposer.compose(
        todayClasses: [sampleEntry],
        allSubjectStats: stats,
        todayTasks: [],
        upcomingExams: [],
        hasSubjectsConfigured: true,
      );

      expect(message.isUrgent, isFalse);
      expect(message.title, contains('Daily Morning Digest'));
      expect(message.body, contains('1 class today'));
      expect(message.body, contains('targets are healthy'));
    });

    test('Weekend / No classes day shows relaxed message', () {
      final message = DailyDigestComposer.compose(
        todayClasses: [],
        allSubjectStats: [],
        todayTasks: [],
        upcomingExams: [],
        hasSubjectsConfigured: true,
      );

      expect(message.isUrgent, isFalse);
      expect(message.title, contains('Free Day'));
      expect(message.body, contains('No classes or pending tasks'));
    });
  });
}
