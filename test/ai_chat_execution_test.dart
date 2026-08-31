import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/features/semesters/domain/semester_model.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_request.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_response.dart';
import 'package:trackx/features/ai_assistant/data/services/ai_context_builder.dart';
import 'package:trackx/features/ai_assistant/data/services/gemini_provider.dart';
import 'package:trackx/features/ai_assistant/data/services/offline_fallback_provider.dart';

void main() {
  group('AI Assistant Live & Offline Chat Execution Tests', () {
    late UserProfile mockProfile;
    late List<Semester> mockSemesters;
    late List<Subject> mockSubjects;
    late List<AttendanceRecord> mockAttendance;
    late List<Task> mockTasks;
    late List<Assignment> mockAssignments;
    late List<Exam> mockExams;
    late List<TimetableEntry> mockTimetable;

    setUp(() {
      mockProfile = UserProfile(
        id: 'u-101',
        name: 'Jordan Sparks',
        email: 'jordan@college.edu',
        branch: 'Information Technology',
        semester: 3,
        globalTarget: 80.0,
        themeMode: 'dark',
        themeColorPack: 'purple',
        onboardingCompleted: true,
        createdTimestamp: DateTime.now().millisecondsSinceEpoch,
        updatedTimestamp: DateTime.now().millisecondsSinceEpoch,
        currentSemesterId: 'sem-3',
        preferredTimezone: 'Asia/Kolkata',
      );

      mockSemesters = [
        Semester(
          id: 'sem-3',
          userId: 'u-101',
          programmeId: 'p1',
          name: 'Semester 3',
          semesterNumber: 3,
          academicYear: '2026-2027',
          status: 'Active',
          plannedCredits: 22.0,
          completedCredits: 0.0,
          attendanceTarget: 80.0,
          notes: '',
          startDate: DateTime.now().subtract(const Duration(days: 40)),
          endDate: DateTime.now().add(const Duration(days: 80)),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      mockSubjects = [
        Subject(
          id: 'sub-dbms',
          userId: 'u-101',
          semesterId: 'sem-3',
          name: 'Database Management Systems',
          facultyName: 'Dr. Evelyn',
          colorValue: 0xFF5B5FEF,
          targetAttendance: 80.0,
          presentClasses: 15,
          absentClasses: 3,
          credits: 4.0,
          type: 'Theory',
          status: 'Active',
          expectedDifficulty: 'Moderate',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      mockAttendance = [
        AttendanceRecord(
          id: 'att-1',
          userId: 'u-101',
          semesterId: 'sem-3',
          subjectId: 'sub-dbms',
          date: DateTime.now().subtract(const Duration(days: 1)),
          periodNumber: 1,
          status: 'present',
          source: 'manual',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      mockTasks = [];
      mockAssignments = [];
      mockExams = [
        Exam(
          id: 'exam-1',
          userId: 'u-101',
          semesterId: 'sem-3',
          subjectId: 'sub-dbms',
          title: 'DBMS Midterm',
          examType: 'Midterm',
          examDate: DateTime.now().add(const Duration(days: 7)),
          startTime: '10:00 AM',
          syllabus: 'Relational Algebra & Normalization',
          preparationProgress: 35.0,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      mockTimetable = [
        TimetableEntry(
          id: 'tt-1',
          userId: 'u-101',
          semesterId: 'sem-3',
          subjectId: 'sub-dbms',
          dayOfWeek: 1,
          periodNumber: 1,
          startTime: 540,
          endTime: 600,
          room: 'Room 402',
          isEnabled: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];
    });

    test('Context builder correctly compiles profile and subject information', () {
      final context = AiContextBuilder.build(
        profile: mockProfile,
        semesters: mockSemesters,
        subjects: mockSubjects,
        attendance: mockAttendance,
        tasks: mockTasks,
        assignments: mockAssignments,
        exams: mockExams,
        timetable: mockTimetable,
        consentFlags: {'attendance': true, 'timetable': true, 'planner': true},
      );

      final map = context.toMap();
      expect(map['activeSemesterId'], equals('sem-3'));
      expect(map['subjects'].length, equals(1));
      expect(map['attendance'].length, equals(1));
      expect(map['upcomingExams'].length, equals(1));
    });

    test('Gemini provider without API key falls back smoothly to offline engine', () async {
      final context = AiContextBuilder.build(
        profile: mockProfile,
        semesters: mockSemesters,
        subjects: mockSubjects,
        attendance: mockAttendance,
        tasks: mockTasks,
        assignments: mockAssignments,
        exams: mockExams,
        timetable: mockTimetable,
        consentFlags: {'attendance': true, 'timetable': true, 'planner': true},
      );

      final request = AiRequest(
        id: 'req-test-1',
        userId: mockProfile.id,
        featureType: AiFeatureType.attendanceExplanation,
        userPrompt: 'How many classes can I miss in DBMS?',
        context: context.toMap(),
        conversationId: 'default',
        modelId: 'gemini-1.5-flash',
        createdAt: DateTime.now(),
      );

      // Testing provider with empty/null override
      final provider = GeminiAiProvider(overrideApiKey: '');
      final response = await provider.generate(request);

      expect(response.text.isNotEmpty, isTrue);
      expect(response.sources.isNotEmpty, isTrue);
      expect(response.limitations.any((l) => l.contains('No Gemini API Key')), isTrue);
    });

    test('OfflineFallbackProvider handles study planning and generates actionable suggestions', () async {
      final context = AiContextBuilder.build(
        profile: mockProfile,
        semesters: mockSemesters,
        subjects: mockSubjects,
        attendance: mockAttendance,
        tasks: mockTasks,
        assignments: mockAssignments,
        exams: mockExams,
        timetable: mockTimetable,
        consentFlags: {'attendance': true, 'timetable': true, 'planner': true},
      );

      final request = AiRequest(
        id: 'req-test-2',
        userId: mockProfile.id,
        featureType: AiFeatureType.studyPlanning,
        userPrompt: 'Help me plan my study schedule for DBMS Midterm',
        context: context.toMap(),
        conversationId: 'default',
        modelId: 'offline',
        createdAt: DateTime.now(),
      );

      final provider = OfflineFallbackProvider();
      final response = await provider.generate(request);

      expect(response.text.contains('Database Management Systems'), isTrue);
      expect(response.suggestedActions.isNotEmpty, isTrue);
      final firstAction = response.suggestedActions.first;
      expect(firstAction.type, equals('CreateStudySession'));
      expect(firstAction.title.contains('Schedule'), isTrue);
    });

    test('AiSuggestedAction serializes and deserializes cleanly', () {
      final action = AiSuggestedAction(
        type: 'CreatePlannerTask',
        title: 'Review Chapter 3 Indexing',
        parameters: {
          'title': 'Review Chapter 3 Indexing',
          'category': 'Revision',
          'durationMinutes': 60,
        },
      );

      final map = action.toMap();
      final restored = AiSuggestedAction.fromMap(map);

      expect(restored.type, equals(action.type));
      expect(restored.title, equals(action.title));
      expect(restored.parameters['durationMinutes'], equals(60));
    });
  });
}
