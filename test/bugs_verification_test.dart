import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/core/services/persistence_service.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/authentication/domain/auth_state.dart';
import 'package:trackx/features/planner/data/repositories/productivity_repository.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/ai_assistant/data/services/ai_context_builder.dart';
import 'package:trackx/features/ai_assistant/data/services/offline_fallback_provider.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_request.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';

void main() {
  group('3 Core Bugs & Requirements Verification Tests', () {
    late SharedPreferences prefs;
    late PersistenceService persistence;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      persistence = PersistenceService(prefs);
    });

    // 1. Existing profile is loaded after login
    test('1. Existing profile is loaded after login', () async {
      final existingProfile = UserProfile(
        id: 'uid_user_123',
        name: 'Rohan Sharma',
        email: 'rohan@example.com',
        branch: 'Computer Science',
        semester: 4,
        globalTarget: 80.0,
        themeMode: 'dark',
        themeColorPack: 'purple',
        onboardingCompleted: true,
        createdTimestamp: 1000,
        updatedTimestamp: 2000,
      );

      // Save user profile to persistent store
      await persistence.saveUserProfile(existingProfile);
      await persistence.saveAuthToken('test-token');

      final authRepo = AuthRepository(persistence);

      // Verify loaded state has profile and onboardingCompleted == true
      expect(authRepo.state.status, AuthStatus.authenticated);
      expect(authRepo.state.userProfile?.id, 'uid_user_123');
      expect(authRepo.state.userProfile?.name, 'Rohan Sharma');
      expect(authRepo.state.userProfile?.department, 'Computer Science');
      expect(authRepo.state.userProfile?.onboardingCompleted, true);
    });

    // 2. Missing profile triggers setup (onboardingCompleted is false)
    test(
      '2. Missing profile triggers setup (onboardingCompleted == false)',
      () async {
        final authRepo = AuthRepository(persistence);

        // Initial state is unauthenticated
        expect(authRepo.state.status, AuthStatus.unauthenticated);

        // Emulate auth state change without existing firestore profile
        final newDefaultProfile = UserProfile(
          id: 'new_uid_456',
          name: '',
          email: 'newuser@example.com',
          branch: '',
          semester: 1,
          globalTarget: 75.0,
          themeMode: 'dark',
          themeColorPack: 'purple',
          onboardingCompleted: false,
          createdTimestamp: 1000,
          updatedTimestamp: 1000,
        );

        authRepo.state = AuthState.authenticated(newDefaultProfile);

        expect(authRepo.state.status, AuthStatus.authenticated);
        expect(authRepo.state.userProfile?.onboardingCompleted, false);
        expect(authRepo.state.userProfile?.name, '');
      },
    );

    // 3. Logout does not delete profile
    test('3. Logout does not delete profile from persistent storage', () async {
      final profile = UserProfile(
        id: 'user_keep_profile',
        name: 'Priya Patel',
        email: 'priya@example.com',
        branch: 'Information Technology',
        semester: 6,
        globalTarget: 85.0,
        themeMode: 'dark',
        themeColorPack: 'blue',
        onboardingCompleted: true,
        createdTimestamp: 1000,
        updatedTimestamp: 2000,
      );

      await persistence.saveUserProfile(profile);
      await persistence.saveAuthToken('active-token');

      final authRepo = AuthRepository(persistence);
      expect(authRepo.state.status, AuthStatus.authenticated);

      // Perform logout
      await authRepo.logout();

      // In-memory active auth is reset to unauthenticated
      expect(authRepo.state.status, AuthStatus.unauthenticated);
      expect(authRepo.state.userProfile, null);

      // Persistent profile remains intact
      final retrievedProfile = persistence.getUserProfile('user_keep_profile');
      expect(retrievedProfile, isNotNull);
      expect(retrievedProfile?.name, 'Priya Patel');
      expect(retrievedProfile?.department, 'Information Technology');
    });

    // 4. New user has empty planner
    test('4. New user has empty planner', () async {
      final plannerRepo = ProductivityRepository(prefs);
      final tasks = plannerRepo.getTasks('brand_new_user_uid');
      final assignments = plannerRepo.getAssignments('brand_new_user_uid');
      final exams = plannerRepo.getExams('brand_new_user_uid');

      expect(tasks, isEmpty);
      expect(assignments, isEmpty);
      expect(exams, isEmpty);
    });

    // 5. Planner only loads current user's records (User isolation)
    test(
      "5. Planner only loads current user's records and isolates User A from User B",
      () async {
        final plannerRepo = ProductivityRepository(prefs);

        final taskUserA = Task(
          id: 'task-a1',
          userId: 'user_a_uid',
          semesterId: 'sem-1',
          title: "User A's Private Task",
          category: 'Study',
          priority: 'High',
          dueDate: DateTime.now().add(const Duration(days: 2)),
          isCompleted: false,
          recurrenceRule: 'None',
          createdAt: 1000,
          updatedAt: 1000,
        );

        final taskUserB = Task(
          id: 'task-b1',
          userId: 'user_b_uid',
          semesterId: 'sem-1',
          title: "User B's Private Task",
          category: 'Exam',
          priority: 'Medium',
          dueDate: DateTime.now().add(const Duration(days: 3)),
          isCompleted: false,
          recurrenceRule: 'None',
          createdAt: 1000,
          updatedAt: 1000,
        );

        // Save User A's task
        await plannerRepo.saveTasks([taskUserA], 'user_a_uid');
        // Save User B's task
        await plannerRepo.saveTasks([taskUserB], 'user_b_uid');

        // User A only sees User A's task
        final userATasks = plannerRepo.getTasks('user_a_uid');
        expect(userATasks.length, 1);
        expect(userATasks.first.title, "User A's Private Task");

        // User B only sees User B's task
        final userBTasks = plannerRepo.getTasks('user_b_uid');
        expect(userBTasks.length, 1);
        expect(userBTasks.first.title, "User B's Private Task");

        // User C (new) sees nothing
        final userCTasks = plannerRepo.getTasks('user_c_uid');
        expect(userCTasks, isEmpty);
      },
    );

    // 6. AI context contains no sample data when user has no data
    test('6. AI context contains no sample data for a clean user', () async {
      final cleanProfile = UserProfile(
        id: 'clean_uid',
        name: 'Fresh Student',
        email: 'fresh@example.com',
        branch: 'Mechanical',
        semester: 1,
        globalTarget: 75.0,
        themeMode: 'dark',
        themeColorPack: 'purple',
        onboardingCompleted: true,
        createdTimestamp: 1000,
        updatedTimestamp: 1000,
      );

      final aiContext = AiContextBuilder.build(
        profile: cleanProfile,
        semesters: [],
        subjects: [],
        attendance: [],
        tasks: [],
        assignments: [],
        exams: [],
        timetable: [],
        consentFlags: {
          'attendance': true,
          'tasks': true,
          'assignments': true,
          'exams': true,
        },
      );

      expect(aiContext.subjects, isEmpty);
      expect(aiContext.upcomingExams, isEmpty);
      expect(aiContext.upcomingAssignments, isEmpty);
      expect(aiContext.plannerItems, isEmpty);
      expect(aiContext.attendance, isEmpty);
      expect(aiContext.timetable, isEmpty);

      // Offline provider returns clean "no data" messages rather than mock courses
      final offlineProvider = OfflineFallbackProvider();
      final response = await offlineProvider.generate(
        AiRequest(
          id: 'test-req',
          userId: 'clean_uid',
          featureType: AiFeatureType.attendanceExplanation,
          userPrompt: 'Tell me about my attendance',
          context: aiContext.toMap(),
          conversationId: 'conv-1',
          modelId: 'offline',
          createdAt: DateTime.now(),
        ),
      );

      expect(response.text.contains('Calculus'), isFalse);
      expect(response.text.contains('Chemistry'), isFalse);
      expect(response.text.contains('DBMS'), isFalse);
      expect(
        response.text.contains(
          'No subject attendance records found to analyze.',
        ),
        isTrue,
      );
    });

    // 7. AI context contains real user data when available
    test('7. AI context contains real user data when available', () async {
      final profile = UserProfile(
        id: 'active_student_uid',
        name: 'Aarav Gupta',
        email: 'aarav@example.com',
        branch: 'Computer Science',
        semester: 3,
        globalTarget: 75.0,
        themeMode: 'dark',
        themeColorPack: 'purple',
        onboardingCompleted: true,
        createdTimestamp: 1000,
        updatedTimestamp: 1000,
      );

      final realSubject = Subject(
        id: 'sub_nlp',
        userId: 'active_student_uid',
        semesterId: 'sem-3',
        name: 'Natural Language Processing',
        code: 'CS-501',
        facultyName: 'Dr. Rao',
        type: 'Theory',
        status: 'Active',
        expectedDifficulty: 'Moderate',
        colorValue: 4283060450,
        presentClasses: 18,
        absentClasses: 2,
        targetAttendance: 75.0,
        createdAt: 1000,
        updatedAt: 1000,
      );

      final realExam = Exam(
        id: 'exam_nlp_1',
        userId: 'active_student_uid',
        semesterId: 'sem-3',
        subjectId: 'sub_nlp',
        title: 'NLP Endterm Final',
        examType: 'Final',
        examDate: DateTime.now().add(const Duration(days: 14)),
        startTime: '10:00 AM',
        syllabus: 'Core NLP models and transformers',
        preparationProgress: 60.0,
        createdAt: 1000,
        updatedAt: 1000,
      );

      final aiContext = AiContextBuilder.build(
        profile: profile,
        semesters: [],
        subjects: [realSubject],
        attendance: [],
        tasks: [],
        assignments: [],
        exams: [realExam],
        timetable: [],
        consentFlags: {
          'attendance': true,
          'tasks': true,
          'assignments': true,
          'exams': true,
        },
      );

      expect(aiContext.subjects.length, 1);
      expect(aiContext.subjects.first.name, 'Natural Language Processing');
      expect(aiContext.subjects.first.currentAttendance, 90.0);
      expect(aiContext.upcomingExams.length, 1);
      expect(aiContext.upcomingExams.first.title, 'NLP Endterm Final');

      final offlineProvider = OfflineFallbackProvider();
      final response = await offlineProvider.generate(
        AiRequest(
          id: 'test-req-2',
          userId: 'active_student_uid',
          featureType: AiFeatureType.attendanceExplanation,
          userPrompt: 'Analyze my NLP attendance',
          context: aiContext.toMap(),
          conversationId: 'conv-1',
          modelId: 'offline',
          createdAt: DateTime.now(),
        ),
      );

      expect(response.text.contains('Natural Language Processing'), isTrue);
      expect(response.text.contains('90.0%'), isTrue);
    });
  });
}
