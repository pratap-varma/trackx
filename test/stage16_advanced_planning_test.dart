import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/features/subjects/domain/topic_model.dart';
import 'package:trackx/features/subjects/domain/subject_dependency_model.dart';
import 'package:trackx/features/subjects/data/dependency_repository.dart';
import 'package:trackx/features/planner/domain/services/revision_scheduler.dart';
import 'package:trackx/core/services/timezone_service.dart';

void main() {
  group('Stage 16 Spaced Repetition Revision Scheduling Tests', () {
    test('Suggests shorter interval for low confidence, high difficulty topics', () {
      final topic = Topic(
        id: 't1',
        userId: 'u1',
        subjectId: 'sub1',
        title: 'Quantum Mechanics Intro',
        description: 'Basic introduction',
        status: 'In Progress',
        difficulty: 'Very Challenging',
        confidence: 'Low',
        estimatedMinutes: 60,
        completedMinutes: 0,
        sortOrder: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = RevisionScheduler.scheduleRevision(
        topic: topic,
        examDate: DateTime.now().add(const Duration(days: 10)),
        preferredStudySessionMinutes: 45,
        existingCommitmentDates: [],
      );

      // Should recommend reviewing almost daily (1 day gap) due to high complexity and low confidence
      expect(result.suggestedDate.day, equals(DateTime.now().add(const Duration(days: 1)).day));
      expect(result.suggestedDurationMinutes, greaterThan(45));
    });

    test('Suggests longer interval for high confidence topics', () {
      final topic = Topic(
        id: 't2',
        userId: 'u1',
        subjectId: 'sub1',
        title: 'Basic Mathematics',
        status: 'In Progress',
        difficulty: 'Easy',
        confidence: 'Strong',
        estimatedMinutes: 30,
        completedMinutes: 0,
        sortOrder: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = RevisionScheduler.scheduleRevision(
        topic: topic,
        examDate: DateTime.now().add(const Duration(days: 30)),
        preferredStudySessionMinutes: 45,
        existingCommitmentDates: [],
      );

      // Easy + Strong confidence -> review in 14 days
      expect(result.suggestedDate.difference(DateTime.now()).inDays, greaterThanOrEqualTo(13));
      expect(result.suggestedDurationMinutes, lessThan(45));
    });
  });

  group('Stage 16 Dependency cycle checks', () {
    test('Recursive DFS cycle checking stops circular prerequisites', () {
      final list = <SubjectDependency>[
        SubjectDependency(id: 'd1', userId: 'u1', subjectId: 'subB', requiredSubjectId: 'subA', type: 'Prerequisite', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        SubjectDependency(id: 'd2', userId: 'u1', subjectId: 'subC', requiredSubjectId: 'subB', type: 'Prerequisite', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      // We want to make subA depend on subC. That would create a cycle: subA -> subC -> subB -> subA.
      final hasCycle = DependencyRepository.hasCycleStatic(
        subjectId: 'subA',
        requiredSubjectId: 'subC',
        dependencies: list,
      );

      expect(hasCycle, isTrue);
    });

    test('Allow adding valid dependencies without cycles', () {
      final list = <SubjectDependency>[
        SubjectDependency(id: 'd1', userId: 'u1', subjectId: 'subB', requiredSubjectId: 'subA', type: 'Prerequisite', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      // Making subC depend on subB is perfectly valid.
      final hasCycle = DependencyRepository.hasCycleStatic(
        subjectId: 'subC',
        requiredSubjectId: 'subB',
        dependencies: list,
      );

      expect(hasCycle, isFalse);
    });
  });

  group('Stage 16 Timezone Service Tests', () {
    test('Midnight deadline comparison checks', () {
      final timezone = 'America/New_York';
      final nowInTZ = TimezoneService.nowInTimezone(timezone);
      
      // Tomorrow morning is after midnight
      final tomorrow = nowInTZ.add(const Duration(days: 1));
      final isBefore = TimezoneService.isBeforeMidnight(tomorrow, timezone);
      expect(isBefore, isFalse);
    });
  });
}
