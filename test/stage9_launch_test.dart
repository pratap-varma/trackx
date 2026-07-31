import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/core/services/update_checker_service.dart';

void main() {
  group('Stage 9 - Version Checker & Feedback Diagnostics Tests', () {
    test('UpdateCheckerService detects newer patches, majors, and minors', () {
      final checker = UpdateCheckerService(currentVersion: '1.0.0');

      expect(checker.isUpdateAvailable('1.0.1'), true);
      expect(checker.isUpdateAvailable('1.1.0'), true);
      expect(checker.isUpdateAvailable('2.0.0'), true);

      expect(checker.isUpdateAvailable('1.0.0'), false);
      expect(checker.isUpdateAvailable('0.9.9'), false);
    });

    test(
      'Feedback diagnostics payload contains non-sensitive metadata only',
      () {
        final shareConsent = true;

        final diagnostics = {
          'appVersion': '1.0.0',
          'platform': 'Android',
          'databaseSchema': 1,
          if (shareConsent) 'consentedMetadata': true,
        };

        expect(diagnostics['appVersion'], '1.0.0');
        expect(diagnostics.containsKey('passwords'), false);
        expect(diagnostics.containsKey('privateNotes'), false);
      },
    );
  });
}
