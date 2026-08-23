import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/planner/data/repositories/productivity_repository.dart';
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

    test('Automatic deletion of expired tasks and events after scheduled day passes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = ProductivityRepository(prefs);

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      final pastTask = Task(
        id: 'past-t1',
        userId: 'u1',
        semesterId: 's1',
        title: 'Past Task',
        category: 'Assignment',
        priority: 'High',
        dueDate: yesterday,
        isCompleted: false,
        recurrenceRule: 'None',
        createdAt: 0,
        updatedAt: 0,
      );

      final futureTask = Task(
        id: 'future-t2',
        userId: 'u1',
        semesterId: 's1',
        title: 'Future Task',
        category: 'Assignment',
        priority: 'High',
        dueDate: tomorrow,
        isCompleted: false,
        recurrenceRule: 'None',
        createdAt: 0,
        updatedAt: 0,
      );

      final pastExam = Exam(
        id: 'past-ex1',
        userId: 'u1',
        semesterId: 's1',
        subjectId: 'sub1',
        title: 'Past Exam',
        examType: 'Midterm',
        examDate: yesterday,
        startTime: '10:00 AM',
        syllabus: 'Module 1',
        preparationProgress: 100,
        createdAt: 0,
        updatedAt: 0,
      );

      final futureExam = Exam(
        id: 'future-ex2',
        userId: 'u1',
        semesterId: 's1',
        subjectId: 'sub1',
        title: 'Future Exam',
        examType: 'Final',
        examDate: tomorrow,
        startTime: '10:00 AM',
        syllabus: 'Module 1-5',
        preparationProgress: 40,
        createdAt: 0,
        updatedAt: 0,
      );

      // Save raw tasks & exams including past ones
      await repo.saveTasks([pastTask, futureTask], 'u1');
      await repo.saveExams([pastExam, futureExam], 'u1');

      // Retrieval automatically prunes expired items
      final retrievedTasks = repo.getTasks('u1');
      final retrievedExams = repo.getExams('u1');

      expect(retrievedTasks.length, 1);
      expect(retrievedTasks.first.id, 'future-t2');

      expect(retrievedExams.length, 1);
      expect(retrievedExams.first.id, 'future-ex2');
    });
  });
}
