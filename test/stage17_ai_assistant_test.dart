import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/features/semesters/domain/semester_model.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_request.dart';
import 'package:trackx/features/ai_assistant/domain/validators/ai_action_validator.dart';
import 'package:trackx/features/ai_assistant/data/services/ai_context_builder.dart';
import 'package:trackx/features/ai_assistant/data/services/offline_fallback_provider.dart';

void main() {
  group('Stage 17 - AI Assistant Core & Validation Tests', () {
    late UserProfile mockProfile;
    late List<Semester> mockSemesters;
    late List<Subject> mockSubjects;
    late List<AttendanceRecord> mockAttendance;
    late List<Task> mockTasks;
    late List<Assignment> mockAssignments;
    late List<Exam> mockExams;

    setUp(() {
      mockProfile = UserProfile(
        id: 'u1',
        name: 'Alex Student',
        email: 'alex@college.edu',
        branch: 'CSE',
        semester: 1,
        globalTarget: 75.0,
        themeMode: 'dark',
        themeColorPack: 'purple',
        onboardingCompleted: true,
        createdTimestamp: DateTime.now().millisecondsSinceEpoch,
        updatedTimestamp: DateTime.now().millisecondsSinceEpoch,
        currentSemesterId: 'sem-1',
        preferredTimezone: 'Asia/Kolkata',
      );

      mockSemesters = [
        Semester(
          id: 'sem-1',
          userId: 'u1',
          programmeId: 'p1',
          name: 'Semester 1',
          semesterNumber: 1,
          academicYear: '2026-2027',
          status: 'Active',
          plannedCredits: 20.0,
          completedCredits: 0.0,
          attendanceTarget: 75.0,
          notes: '',
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now().add(const Duration(days: 60)),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        )
      ];

      mockSubjects = [
        Subject(
          id: 'sub-dbms',
          userId: 'u1',
          semesterId: 'sem-1',
          name: 'Database Management Systems',
          facultyName: 'Dr. Smith',
          colorValue: 0xFF4A90E2,
          targetAttendance: 75.0,
          presentClasses: 15,
          absentClasses: 5,
          credits: 4.0,
          type: 'Theory',
          status: 'Active',
          expectedDifficulty: 'Moderate',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
        Subject(
          id: 'sub-daa',
          userId: 'u1',
          semesterId: 'sem-1',
          name: 'Design and Analysis of Algorithms',
          facultyName: 'Dr. Brown',
          colorValue: 0xFF50E3C2,
          targetAttendance: 75.0,
          presentClasses: 8,
          absentClasses: 4,
          credits: 4.0,
          type: 'Theory',
          status: 'Active',
          expectedDifficulty: 'Moderate',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      mockAttendance = [];
      mockTasks = [];
      mockAssignments = [
        Assignment(
          id: 'assign-1',
          userId: 'u1',
          semesterId: 'sem-1',
          subjectId: 'sub-dbms',
          title: 'DBMS Project 1',
          assignedDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 5)),
          status: 'In progress',
          priority: 'Medium',
          attachmentPaths: const [],
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        )
      ];
      
      mockExams = [
        Exam(
          id: 'exam-1',
          userId: 'u1',
          semesterId: 'sem-1',
          subjectId: 'sub-dbms',
          title: 'DBMS Midterm',
          examType: 'Midterm',
          startTime: '09:00 AM',
          syllabus: '',
          preparationProgress: 0.0,
          examDate: DateTime.now().add(const Duration(days: 10)),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        )
      ];
    });

    test('Context Builder selectively honors consent flags', () {
      // 1. Consent true for everything
      final contextAll = AiContextBuilder.build(
        profile: mockProfile,
        semesters: mockSemesters,
        subjects: mockSubjects,
        attendance: mockAttendance,
        tasks: mockTasks,
        assignments: mockAssignments,
        exams: mockExams,
        timetable: const [],
        consentFlags: {
          'attendance': true,
          'tasks': true,
          'assignments': true,
          'exams': true,
          'cgpa': true,
        },
      );

      expect(contextAll.subjects.length, equals(2));
      expect(contextAll.upcomingExams.length, equals(1));
      expect(contextAll.upcomingAssignments.length, equals(1));

      // 2. Consent false for exams
      final contextNoExams = AiContextBuilder.build(
        profile: mockProfile,
        semesters: mockSemesters,
        subjects: mockSubjects,
        attendance: mockAttendance,
        tasks: mockTasks,
        assignments: mockAssignments,
        exams: mockExams,
        timetable: const [],
        consentFlags: {
          'attendance': true,
          'tasks': true,
          'assignments': true,
          'exams': false,
          'cgpa': true,
        },
      );

      expect(contextNoExams.upcomingExams.length, equals(0));
      expect(contextNoExams.upcomingAssignments.length, equals(1));
    });

    test('Action Validator detects past dates and task/deadline conflicts', () {
      final validTask = Task(
        id: 't-1',
        userId: 'u1',
        semesterId: 'sem-1',
        title: 'Review DBMS project requirements',
        category: 'Study',
        priority: 'High',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        isCompleted: false,
        recurrenceRule: 'None',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final resultValid = AiActionValidator.validatePlannerTask(
        validTask,
        exams: mockExams,
        assignments: mockAssignments,
      );
      expect(resultValid.isValid, isTrue);

      // Task scheduled past related exam date
      final invalidTask = Task(
        id: 't-2',
        userId: 'u1',
        semesterId: 'sem-1',
        title: 'Study for DBMS Midterm',
        category: 'Study',
        priority: 'High',
        dueDate: DateTime.now().add(const Duration(days: 12)), // Exam is in 10 days
        isCompleted: false,
        recurrenceRule: 'None',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final resultInvalid = AiActionValidator.validatePlannerTask(
        invalidTask,
        exams: mockExams,
        assignments: mockAssignments,
      );
      expect(resultInvalid.isValid, isFalse);
      expect(resultInvalid.reason, contains('scheduled after the related exam date'));
    });

    test('Offline fallback generates attendance forecast summaries without internet', () async {
      final provider = OfflineFallbackProvider();
      
      final builderContext = AiContextBuilder.build(
        profile: mockProfile,
        semesters: mockSemesters,
        subjects: mockSubjects,
        attendance: mockAttendance,
        tasks: mockTasks,
        assignments: mockAssignments,
        exams: mockExams,
        timetable: const [],
        consentFlags: {
          'attendance': true,
          'tasks': true,
          'assignments': true,
          'exams': true,
        },
      );

      final request = AiRequest(
        id: 'req-1',
        userId: 'u1',
        featureType: AiFeatureType.attendanceExplanation,
        userPrompt: 'Can I miss tomorrow?',
        context: builderContext.toMap(),
        modelId: 'offline',
        createdAt: DateTime.now(),
      );

      final response = await provider.generate(request);

      expect(response.modelId, equals('offline-deterministic-fallback'));
      expect(response.text, contains('Forecast'));
      expect(response.text, contains('Database Management Systems'));
      expect(response.sources.length, equals(2));
    });
  });
}
