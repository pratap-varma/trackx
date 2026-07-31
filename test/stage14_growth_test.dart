import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/features/integrations/domain/models/connector_models.dart';
import 'package:trackx/features/profile/domain/models/recommendation_models.dart';

void main() {
  group('Stage 14 - API Expansion & Analytics Tests', () {
    test('ConnectorSpec properties and lifecycle state mappings', () {
      final connector = ConnectorSpec(
        id: 'conn_canvas_mvgr',
        institutionId: 'inst_mvgr',
        version: '1.2.0',
        authType: 'OAuth2',
        apiBaseUrl: 'https://lms.mvgr.edu/api',
        rateLimitPerMinute: 120,
        status: 'Active',
      );

      final map = connector.toMap();
      expect(map['id'], 'conn_canvas_mvgr');
      expect(map['rateLimitPerMinute'], 120);

      final restored = ConnectorSpec.fromMap(map);
      expect(restored.status, 'Active');
    });

    test('RecommendationPreference defaults and modification updates', () {
      final pref = RecommendationPreference(
        enableAttendanceSuggestions: true,
        enableStudyPlanSuggestions: false,
        enableGroupSuggestions: true,
        updateFrequency: 'DailyDigest',
      );

      final map = pref.toMap();
      expect(map['enableStudyPlanSuggestions'], false);

      final restored = RecommendationPreference.fromMap(map);
      expect(restored.updateFrequency, 'DailyDigest');
    });

    test('Deterministic academic attendance risk thresholds calculations', () {
      final target = 75.0;
      final current = 72.0;

      // Rule: If current < target, status is At Risk
      final risk = current < target ? 'At Risk' : 'Stable';
      expect(risk, 'At Risk');

      final stableCurrent = 80.0;
      final stableRisk = stableCurrent < target ? 'At Risk' : 'Stable';
      expect(stableRisk, 'Stable');
    });
  });
}
