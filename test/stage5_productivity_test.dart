import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';

void main() {
  group('Stage 5 - CGPA & Productivity Logic Tests', () {
    test('CourseGrade model converts to and from map correctly', () {
      final course = CourseGrade(
        id: 'c1',
        semesterId: 's1',
        subjectName: 'DBMS',
        credits: 4,
        grade: 'A+',
        gradePoints: 9.0,
      );

      final map = course.toMap();
      final fromMap = CourseGrade.fromMap(map);

      expect(fromMap.id, 'c1');
      expect(fromMap.credits, 4);
      expect(fromMap.grade, 'A+');
      expect(fromMap.gradePoints, 9.0);
    });

    test('SGPA and CGPA formula matches standards', () {
      final grades = [
        CourseGrade(
          id: '1',
          semesterId: 's1',
          subjectName: 'Math',
          credits: 4,
          grade: 'O',
          gradePoints: 10.0,
        ),
        CourseGrade(
          id: '2',
          semesterId: 's1',
          subjectName: 'Physics',
          credits: 3,
          grade: 'A',
          gradePoints: 8.0,
        ),
      ];

      double totalPoints = 0;
      int totalCredits = 0;
      for (final g in grades) {
        totalPoints += g.gradePoints * g.credits;
        totalCredits += g.credits;
      }

      final gpa = totalPoints / totalCredits;
      // (10.0 * 4 + 8.0 * 3) / 7 = 64 / 7 = 9.1428...
      expect(gpa, closeTo(9.14, 0.01));
    });

    test('Task completion status updates correctly', () {
      final task = Task(
        id: 't1',
        userId: 'u1',
        semesterId: 's1',
        title: 'Submit DBMS Lab',
        category: 'Assignment',
        priority: 'High',
        dueDate: DateTime.now(),
        isCompleted: false,
        recurrenceRule: 'None',
        createdAt: 0,
        updatedAt: 0,
      );

      final completed = task.copyWith(
        isCompleted: true,
        completedAt: 100,
        updatedAt: 100,
      );

      expect(completed.isCompleted, true);
      expect(completed.completedAt, 100);
    });

    test('AcademicHoliday model serialization', () {
      final holiday = AcademicHoliday(
        id: 'h1',
        semesterId: 's1',
        title: 'Christmas',
        description: 'Winter Holiday',
        date: DateTime(2026, 12, 25),
        eventType: 'holiday',
      );

      final map = holiday.toMap();
      final fromMap = AcademicHoliday.fromMap(map);

      expect(fromMap.id, 'h1');
      expect(fromMap.title, 'Christmas');
      expect(fromMap.date.year, 2026);
    });
  });
}
