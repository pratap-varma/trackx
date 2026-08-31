import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/features/admin/domain/models/admin_models.dart';
import 'package:trackx/features/admin/providers/admin_providers.dart';
import 'package:trackx/core/services/activity_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Admin Models & Serialization Tests', () {
    test('1. AdminUserSummary serialization matches schema', () {
      final summary = AdminUserSummary(
        uid: 'adm_u1',
        name: 'Alex Student',
        email: 'alex@college.edu',
        branch: 'Computer Science',
        semester: 4,
        createdTimestamp: 1725000000000,
        lastActiveTimestamp: 1725005000000,
        isSuspended: false,
        totalSubjects: 6,
        totalAttendanceRecords: 42,
        totalTasks: 12,
      );

      final map = summary.toMap();
      final fromMap = AdminUserSummary.fromMap(map);

      expect(fromMap.uid, 'adm_u1');
      expect(fromMap.name, 'Alex Student');
      expect(fromMap.email, 'alex@college.edu');
      expect(fromMap.branch, 'Computer Science');
      expect(fromMap.semester, 4);
      expect(fromMap.isSuspended, false);
      expect(fromMap.totalSubjects, 6);
      expect(fromMap.totalAttendanceRecords, 42);
      expect(fromMap.totalTasks, 12);
    });

    test('2. ActivityLogEntry serialization matches schema', () {
      final log = ActivityLogEntry(
        id: 'log-1',
        uid: 'user-123',
        event: 'attendance_marked',
        timestamp: 1725000000000,
        parameters: {'subjectId': 'sub-os', 'status': 'present'},
      );

      final map = log.toMap();
      final fromMap = ActivityLogEntry.fromMap(map);

      expect(fromMap.id, 'log-1');
      expect(fromMap.uid, 'user-123');
      expect(fromMap.event, 'attendance_marked');
      expect(fromMap.parameters['subjectId'], 'sub-os');
      expect(fromMap.parameters['status'], 'present');
    });

    test('3. AdminUserTask model parses completed and pending tasks accurately', () {
      final task = AdminUserTask(
        id: 'task-101',
        title: 'Submit OS Lab Report',
        description: 'Complete memory allocation algorithms',
        category: 'Assignment',
        priority: 'High',
        dueDate: DateTime.fromMillisecondsSinceEpoch(1725000000000),
        isCompleted: true,
        completedAt: 1724995000000,
        createdAt: 1724900000000,
      );

      final map = task.toMap();
      final fromMap = AdminUserTask.fromMap(map);

      expect(fromMap.id, 'task-101');
      expect(fromMap.title, 'Submit OS Lab Report');
      expect(fromMap.category, 'Assignment');
      expect(fromMap.priority, 'High');
      expect(fromMap.isCompleted, true);
      expect(fromMap.completedAt, 1724995000000);
    });

    test('4. AdminAnalyticsOverview calculations & empty fallback', () {
      final overview = AdminAnalyticsOverview(
        totalUsers: 150,
        activeUsersToday: 45,
        activeUsersThisWeek: 110,
        suspendedUsersCount: 3,
        totalAiQueries: 420,
        totalOcrScans: 85,
        totalAttendanceLogs: 1200,
        featureUsageBreakdown: {
          'Attendance': 1200,
          'AI Assistant': 420,
          'OCR & Timetable Import': 85,
        },
      );

      expect(overview.totalUsers, 150);
      expect(overview.activeUsersToday, 45);
      expect(overview.suspendedUsersCount, 3);
      expect(overview.featureUsageBreakdown['Attendance'], 1200);

      final empty = AdminAnalyticsOverview.empty();
      expect(empty.totalUsers, 0);
      expect(empty.activeUsersToday, 0);
      expect(empty.featureUsageBreakdown, isEmpty);
    });
  });

  group('Admin Auth State & Provider State Tests', () {
    test('4. AdminAuthState transitions and status helpers', () {
      final initial = AdminAuthState.initial();
      expect(initial.status, AdminAuthStatus.initial);
      expect(initial.isAuthenticated, false);

      final loading = AdminAuthState.loading();
      expect(loading.status, AdminAuthStatus.loading);
      expect(loading.isAuthenticated, false);

      final adminSummary = AdminUserSummary(
        uid: 'adm-001',
        name: 'Chief Admin',
        email: 'admin@trackx.app',
        branch: 'Administration',
        semester: 0,
        createdTimestamp: 0,
      );

      final authenticated = AdminAuthState.authenticated(adminSummary);
      expect(authenticated.status, AdminAuthStatus.authenticated);
      expect(authenticated.isAuthenticated, true);
      expect(authenticated.admin?.email, 'admin@trackx.app');

      final unauthenticated = AdminAuthState.unauthenticated('Logged out');
      expect(unauthenticated.status, AdminAuthStatus.unauthenticated);
      expect(unauthenticated.isAuthenticated, false);
      expect(unauthenticated.errorMessage, 'Logged out');

      final error = AdminAuthState.error('Access denied');
      expect(error.status, AdminAuthStatus.error);
      expect(error.errorMessage, 'Access denied');
    });

    test('5. User profile handles suspension flag and serialization', () {
      final profile = UserProfile(
        id: 'u-suspended',
        name: 'Test Suspended',
        email: 'suspended@college.edu',
        branch: 'Mechanical',
        semester: 2,
        globalTarget: 75.0,
        themeMode: 'dark',
        themeColorPack: 'purple',
        onboardingCompleted: true,
        createdTimestamp: 1000,
        updatedTimestamp: 2000,
        isSuspended: true,
        lastActiveTimestamp: 1500,
      );

      final map = profile.toMap();
      final fromMap = UserProfile.fromMap(map);

      expect(fromMap.id, 'u-suspended');
      expect(fromMap.isSuspended, true);
      expect(fromMap.lastActiveTimestamp, 1500);

      final copy = fromMap.copyWith(isSuspended: false);
      expect(copy.isSuspended, false);
    });

    test('6. ActivityLogger service instantiates safely without crashing in test environment', () async {
      final logger = ActivityLogger();
      await expectLater(
        logger.logEvent(
          'test_event',
          userId: 'test-uid',
          parameters: {'category': 'unit_test'},
        ),
        completes,
      );
    });

    test('7. AdminUserDetail accurately holds 6 AI features breakdown metrics', () {
      final summary = AdminUserSummary(
        uid: 'u-ai-test',
        name: 'AI Test User',
        email: 'ai@college.edu',
        branch: 'AI & DS',
        semester: 3,
        createdTimestamp: 1000,
      );

      final detail = AdminUserDetail(
        summary: summary,
        attendanceCount: 15,
        subjectsCount: 5,
        tasksCount: 8,
        aiFeatureBreakdown: {
          'Timetable Grid OCR': 4,
          'Exam Datesheet OCR': 2,
          'Attendance Screenshot OCR': 3,
          'Document Analyzer': 1,
          'AI Flashcard Generator': 12,
          'Academic Assistant Chat': 30,
        },
      );

      expect(detail.aiFeatureBreakdown['Timetable Grid OCR'], 4);
      expect(detail.aiFeatureBreakdown['AI Flashcard Generator'], 12);
      expect(detail.aiFeatureBreakdown['Academic Assistant Chat'], 30);
      expect(detail.aiFeatureBreakdown.length, 6);
    });
  });
}
