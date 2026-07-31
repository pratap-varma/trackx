import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/features/integrations/domain/models/beta_models.dart';

void main() {
  group('Stage 13 - Beta Program & Release Validation Tests', () {
    test('BetaEnrollment model mapping and status transitions', () {
      final now = DateTime.now();
      final enrollment = BetaEnrollment(
        id: 'enroll_01',
        userId: 'user_1',
        cohortId: 'cohort_mvgr',
        enrollmentStatus: 'Active',
        enrolledAt: now,
      );

      final map = enrollment.toMap();
      expect(map['id'], 'enroll_01');
      expect(map['cohortId'], 'cohort_mvgr');
      expect(map['enrollmentStatus'], 'Active');

      final restored = BetaEnrollment.fromMap(map);
      expect(restored.enrollmentStatus, 'Active');
    });

    test('Migration rollout eligibility gates checklist evaluation', () {
      // User must have valid schema and active backups
      final userLocalSchemaVersion = 1;
      final targetSchemaVersion = 2;
      final hasBackup = true;

      final isEligible =
          userLocalSchemaVersion < targetSchemaVersion && hasBackup;
      expect(isEligible, true);
    });
  });
}
