import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SampleDataLoader {
  static Future<void> loadSampleData(SharedPreferences prefs) async {
    // If a profile already exists, do not overwrite it unless requested
    if (prefs.containsKey('user_profile')) return;

    // 1. Auth Token & Profile
    await prefs.setString('auth_token', 'mock-jwt-token-alex');
    
    final profile = {
      'id': 'u1',
      'name': 'Alex Student',
      'email': 'alex@college.edu',
      'branch': 'Computer Science & Engineering',
      'semester': 1,
      'globalTarget': 75.0,
      'themeMode': 'dark',
      'themeColorPack': 'purple',
      'onboardingCompleted': true,
      'createdTimestamp': 1721660400000,
      'updatedTimestamp': 1721660400000,
      'currentSemesterId': 'sem-1',
      'preferredTimezone': 'Asia/Kolkata',
    };
    await prefs.setString('user_profile', jsonEncode(profile));

    // 2. Semester
    final semesters = [
      {
        'id': 'sem-1',
        'userId': 'u1',
        'programmeId': 'p1',
        'name': 'Semester 1',
        'semesterNumber': 1,
        'academicYear': '2026-2027',
        'status': 'Active',
        'plannedCredits': 20.0,
        'completedCredits': 0.0,
        'attendanceTarget': 75.0,
        'notes': 'Aiming for 8.5+ SGPA this semester.',
        'startDate': '2026-07-01T00:00:00.000',
        'endDate': '2026-12-15T00:00:00.000',
        'createdAt': 1721660400000,
        'updatedAt': 1721660400000,
      }
    ];
    await prefs.setString('semesters_list', jsonEncode(semesters));

    // 3. Subjects
    final subjects = [
      {
        'id': 'sub-dbms',
        'userId': 'u1',
        'semesterId': 'sem-1',
        'name': 'Database Management Systems',
        'code': 'CS-301',
        'facultyName': 'Dr. Smith',
        'colorValue': 4283060450, // blue
        'type': 'Theory',
        'credits': 4.0,
        'weeklyPeriods': 4,
        'targetAttendance': 75.0,
        'presentClasses': 15,
        'absentClasses': 3,
        'status': 'Active',
        'expectedDifficulty': 'Moderate',
        'createdAt': 1721660400000,
        'updatedAt': 1721660400000,
      },
      {
        'id': 'sub-daa',
        'userId': 'u1',
        'semesterId': 'sem-1',
        'name': 'Design and Analysis of Algorithms',
        'code': 'CS-302',
        'facultyName': 'Dr. Brown',
        'colorValue': 4283523778, // green
        'type': 'Theory',
        'credits': 4.0,
        'weeklyPeriods': 4,
        'targetAttendance': 75.0,
        'presentClasses': 12,
        'absentClasses': 5,
        'status': 'Active',
        'expectedDifficulty': 'Challenging',
        'createdAt': 1721660400000,
        'updatedAt': 1721660400000,
      },
      {
        'id': 'sub-os',
        'userId': 'u1',
        'semesterId': 'sem-1',
        'name': 'Operating Systems',
        'code': 'CS-303',
        'facultyName': 'Prof. Miller',
        'colorValue': 4293918794, // amber/orange
        'type': 'Theory',
        'credits': 4.0,
        'weeklyPeriods': 3,
        'targetAttendance': 75.0,
        'presentClasses': 10,
        'absentClasses': 2,
        'status': 'Active',
        'expectedDifficulty': 'Moderate',
        'createdAt': 1721660400000,
        'updatedAt': 1721660400000,
      }
    ];
    await prefs.setString('subjects_list', jsonEncode(subjects));

    // 4. Attendance History
    final attendance = [
      {
        'id': 'att-1',
        'userId': 'u1',
        'semesterId': 'sem-1',
        'subjectId': 'sub-dbms',
        'date': '2026-07-20T09:00:00.000',
        'periodNumber': 1,
        'status': 'present',
        'source': 'manual',
        'createdAt': 1721660400000,
        'updatedAt': 1721660400000,
      },
      {
        'id': 'att-2',
        'userId': 'u1',
        'semesterId': 'sem-1',
        'subjectId': 'sub-daa',
        'date': '2026-07-20T10:00:00.000',
        'periodNumber': 2,
        'status': 'absent',
        'source': 'manual',
        'createdAt': 1721660400000,
        'updatedAt': 1721660400000,
      }
    ];
    await prefs.setString('attendance_records_list', jsonEncode(attendance));

    // 5. Timetable
    final timetable = [
      {
        'id': 'tt-1',
        'userId': 'u1',
        'semesterId': 'sem-1',
        'subjectId': 'sub-dbms',
        'dayOfWeek': 1, // Monday
        'periodNumber': 1,
        'startTime': '09:00 AM',
        'endTime': '09:50 AM',
        'classroom': 'Room 401',
        'createdAt': 1721660400000,
        'updatedAt': 1721660400000,
      },
      {
        'id': 'tt-2',
        'userId': 'u1',
        'semesterId': 'sem-1',
        'subjectId': 'sub-daa',
        'dayOfWeek': 1, // Monday
        'periodNumber': 2,
        'startTime': '10:00 AM',
        'endTime': '10:50 AM',
        'classroom': 'Room 402',
        'createdAt': 1721660400000,
        'updatedAt': 1721660400000,
      }
    ];
    await prefs.setString('timetable_entries_list', jsonEncode(timetable));

    // 6. Tasks & Assignments & Exams
    final tasks = [
      {
        'id': 'task-1',
        'userId': 'u1',
        'semesterId': 'sem-1',
        'title': 'Read DBMS indexing chapter',
        'category': 'Study',
        'priority': 'High',
        'dueDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'isCompleted': false,
        'recurrenceRule': 'None',
        'createdAt': 1721660400000,
        'updatedAt': 1721660400000,
      }
    ];
    await prefs.setString('px_tasks_list', jsonEncode(tasks));

    final assignments = [
      {
        'id': 'assign-1',
        'userId': 'u1',
        'semesterId': 'sem-1',
        'subjectId': 'sub-dbms',
        'title': 'SQL Query Optimization Lab',
        'assignedDate': '2026-07-15T00:00:00.000',
        'dueDate': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'status': 'In progress',
        'priority': 'High',
        'attachmentPaths': [],
        'createdAt': 1721660400000,
        'updatedAt': 1721660400000,
      }
    ];
    await prefs.setString('px_assignments_list', jsonEncode(assignments));

    final exams = [
      {
        'id': 'exam-1',
        'userId': 'u1',
        'semesterId': 'sem-1',
        'subjectId': 'sub-dbms',
        'title': 'DBMS Midterm Exam',
        'examType': 'Midterm',
        'examDate': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
        'startTime': '09:00 AM',
        'syllabus': 'SQL queries, joins, and normal forms.',
        'preparationProgress': 50.0,
        'createdAt': 1721660400000,
        'updatedAt': 1721660400000,
      }
    ];
    await prefs.setString('px_exams_list', jsonEncode(exams));

    // 7. Programmes & Dependencies & Topics
    final programmes = [
      {
        'id': 'p1',
        'userId': 'u1',
        'name': 'Bachelor of Technology',
        'department': 'Computer Science & Engineering',
        'durationYears': 4,
        'totalSemesters': 8,
        'requiredCredits': 160.0,
        'minGpa': 5.0,
        'gradingSystem': '10-point',
        'status': 'Active',
        'notes': 'Engineering standard path.',
        'createdAt': 1721660400000,
        'updatedAt': 1721660400000,
      }
    ];
    await prefs.setString('px_programmes_list', jsonEncode(programmes));
    await prefs.setString('px_active_programme_id', 'p1');

    final dependencies = [
      {
        'id': 'dep-1',
        'userId': 'u1',
        'subjectId': 'sub-daa',
        'requiredSubjectId': 'sub-dbms',
        'type': 'Prerequisite',
        'minimumGrade': 'C',
        'notes': 'Query logic uses algorithmic mappings.',
        'createdAt': '2026-07-22T00:00:00.000',
        'updatedAt': '2026-07-22T00:00:00.000',
      }
    ];
    await prefs.setString('px_subject_dependencies_list', jsonEncode(dependencies));

    final topics = [
      {
        'id': 'topic-1',
        'userId': 'u1',
        'subjectId': 'sub-dbms',
        'title': 'Relational Algebra',
        'description': 'Select, Project, Join operations',
        'status': 'Completed',
        'difficulty': 'Easy',
        'confidence': 'Strong',
        'estimatedMinutes': 60,
        'completedMinutes': 60,
        'lastReviewedAt': '2026-07-15T10:00:00.000',
        'nextReviewAt': '2026-07-30T10:00:00.000',
        'sortOrder': 1,
        'createdAt': '2026-07-22T00:00:00.000',
        'updatedAt': '2026-07-22T00:00:00.000',
      },
      {
        'id': 'topic-2',
        'userId': 'u1',
        'subjectId': 'sub-dbms',
        'title': 'Database Normalization',
        'description': '1NF, 2NF, 3NF, BCNF rules',
        'status': 'Revision Needed',
        'difficulty': 'Challenging',
        'confidence': 'Developing',
        'estimatedMinutes': 120,
        'completedMinutes': 30,
        'sortOrder': 2,
        'createdAt': '2026-07-22T00:00:00.000',
        'updatedAt': '2026-07-22T00:00:00.000',
      }
    ];
    await prefs.setString('px_syllabus_topics_list', jsonEncode(topics));
  }
}
