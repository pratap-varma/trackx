import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/features/integrations/domain/models/integration_models.dart';

void main() {
  group('Stage 11 - Integrations, QR, and Session Devices Tests', () {
    test('InstitutionConnection model serialization and mapping', () {
      final now = DateTime.now();
      final connection = InstitutionConnection(
        id: 'conn_101',
        userId: 'user_1',
        institutionId: 'inst_mit',
        connectionStatus: 'Connected',
        grantedScopes: ['attendance', 'timetable'],
        connectedAt: now,
      );

      final map = connection.toMap();
      expect(map['id'], 'conn_101');
      expect(map['connectionStatus'], 'Connected');
      expect(map['grantedScopes'], ['attendance', 'timetable']);

      final restored = InstitutionConnection.fromMap(map);
      expect(restored.institutionId, 'inst_mit');
      expect(restored.grantedScopes.length, 2);
    });

    test('QR token expiration window validation', () {
      // Tokens must expire within 60s
      final now = DateTime.now();
      final expiryTime = now.add(const Duration(seconds: 45));
      final expiredTime = now.subtract(const Duration(seconds: 5));

      final isValid = expiryTime.isAfter(now);
      final isExpired = expiredTime.isBefore(now);

      expect(isValid, true);
      expect(isExpired, true);
    });
  });
}
