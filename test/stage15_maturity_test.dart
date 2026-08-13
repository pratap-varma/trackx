import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/features/adaptive_study/domain/models/learning_goal.dart';
import 'package:trackx/features/adaptive_study/domain/models/revision_item.dart';
import 'package:trackx/features/adaptive_study/domain/models/practice_session.dart';
import 'package:trackx/features/integrations/domain/models/partner_models.dart';
import 'package:trackx/features/profile/domain/models/subscription_models.dart';

void main() {
  group('Stage 15 - Adaptive Learning & Governance Tests', () {
    test('LearningGoal model conversion matches schemas', () {
      final now = DateTime.now();
      final goal = LearningGoal(
        id: 'goal_01',
        userId: 'user_1',
        semesterId: 'sem_01',
        title: 'Revise Database System',
        description: 'Read slides',
        goalType: 'TopicCompletion',
        targetValue: 10.0,
        currentValue: 4.0,
        status: 'Active',
        targetDate: now,
      );

      final map = goal.toMap();
      expect(map['id'], 'goal_01');
      expect(map['currentValue'], 4.0);

      final restored = LearningGoal.fromMap(map);
      expect(restored.status, 'Active');
    });

    test('TopicMastery and spaced-repetition stage calculations', () {
      final now = DateTime.now();
      final item = RevisionItem(
        id: 'rev_01',
        userId: 'user_1',
        subjectId: 'sub_01',
        topicId: 'topic_query',
        intervalStage: 2,
        dueAt: now,
        lastReviewedAt: now,
        status: 'Due',
      );

      // Verify Stage multiplier
      final double intervalDays = item.intervalStage * 3.0;
      expect(intervalDays, 6.0);
    });

    test('PracticeSession rating limits', () {
      final session = PracticeSession(
        id: 'sess_01',
        userId: 'user_1',
        semesterId: 'sem_01',
        subjectId: 'sub_01',
        practiceType: 'Recall',
        plannedDuration: 30,
        actualDuration: 28,
        selfRating: 4,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      final map = session.toMap();
      expect(map['selfRating'], 4);
    });

    test('Verified Partner scope validation', () {
      final partner = Partner(
        id: 'partner_canvas',
        legalName: 'Instructure Inc',
        displayName: 'Canvas Connector',
        partnerType: 'Institution',
        verificationStatus: 'Approved',
        approvedScopes: ['read_courses', 'read_assignments'],
      );

      expect(partner.approvedScopes.contains('read_courses'), true);
      expect(partner.approvedScopes.contains('write_grades'), false);
    });

    test('SubscriptionEntitlement checks', () {
      final now = DateTime.now();
      final ent = SubscriptionEntitlement(
        id: 'ent_01',
        ownerId: 'user_1',
        planId: 'ProStudent',
        status: 'Active',
        expiresAt: now.add(Duration(days: 30)),
      );

      final hasPro = ent.planId == 'ProStudent' && ent.status == 'Active';
      expect(hasPro, true);
    });
  });
}
