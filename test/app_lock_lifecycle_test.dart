import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/services/app_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLock Cold Launch & Background Lifecycle Tests', () {
    test('1. Cold launch is unlocked if no PIN or biometrics are configured', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = AppLockNotifier(prefs, LocalAuthentication());

      expect(notifier.state.isLocked, isFalse);
      expect(notifier.state.hasPin, isFalse);
      expect(notifier.state.isBiometricsEnabled, isFalse);
    });

    test('2. Cold launch is immediately locked if PIN is configured', () async {
      SharedPreferences.setMockInitialValues({
        'sec_pin_enabled': true,
        'sec_user_pin_code': '1234',
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = AppLockNotifier(prefs, LocalAuthentication());

      expect(notifier.state.hasPin, isTrue);
      expect(notifier.state.isPinEnabled, isTrue);
      expect(notifier.state.isLocked, isTrue);

      // Verify unlocking with PIN
      final verified = notifier.verifyPin('1234');
      expect(verified, isTrue);
      expect(notifier.state.isLocked, isFalse);
    });

    test('3. Calling lock() when backgrounded locks the app again', () async {
      SharedPreferences.setMockInitialValues({
        'sec_pin_enabled': true,
        'sec_user_pin_code': '1234',
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = AppLockNotifier(prefs, LocalAuthentication());

      // Unlock
      notifier.verifyPin('1234');
      expect(notifier.state.isLocked, isFalse);

      // App goes to background
      notifier.lock();
      expect(notifier.state.isLocked, isTrue);
    });
  });
}
