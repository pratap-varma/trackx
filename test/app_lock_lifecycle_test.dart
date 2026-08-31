import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/services/app_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLock Cold Launch & Background Lifecycle Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('1. Cold launch is unlocked if no PIN or biometrics are configured', () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = AppLockNotifier(prefs, LocalAuthentication());
      await pumpEventQueue();

      expect(notifier.state.isLocked, isFalse);
      expect(notifier.state.hasPin, isFalse);
      expect(notifier.state.isBiometricsEnabled, isFalse);
    });

    test('2. Cold launch is immediately locked if PIN is configured in SecureStorage', () async {
      SharedPreferences.setMockInitialValues({
        'sec_pin_enabled': true,
      });
      FlutterSecureStorage.setMockInitialValues({
        'sec_user_pin_code': '1234',
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = AppLockNotifier(prefs, LocalAuthentication());
      await pumpEventQueue();

      expect(notifier.state.hasPin, isTrue);
      expect(notifier.state.isPinEnabled, isTrue);
      expect(notifier.state.isLocked, isTrue);

      // Verify unlocking with PIN
      final verified = await notifier.verifyPin('1234');
      expect(verified, isTrue);
      expect(notifier.state.isLocked, isFalse);
    });

    test('3. Legacy SharedPreferences PIN is automatically migrated into SecureStorage and purged from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'sec_pin_enabled': true,
        'sec_user_pin_code': '5678', // Legacy plaintext in SharedPreferences
      });
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = AppLockNotifier(prefs, LocalAuthentication());
      await pumpEventQueue();

      // Ensure purged from SharedPreferences
      expect(prefs.containsKey('sec_user_pin_code'), isFalse);
      expect(notifier.state.hasPin, isTrue);
      expect(notifier.state.isLocked, isTrue);

      // Verify unlocking with migrated PIN
      final verified = await notifier.verifyPin('5678');
      expect(verified, isTrue);
      expect(notifier.state.isLocked, isFalse);
    });

    test('4. Calling lock() when backgrounded locks the app again', () async {
      SharedPreferences.setMockInitialValues({
        'sec_pin_enabled': true,
      });
      FlutterSecureStorage.setMockInitialValues({
        'sec_user_pin_code': '1234',
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = AppLockNotifier(prefs, LocalAuthentication());
      await pumpEventQueue();

      // Unlock
      await notifier.verifyPin('1234');
      expect(notifier.state.isLocked, isFalse);

      // App goes to background
      notifier.lock();
      expect(notifier.state.isLocked, isTrue);
    });
  });
}
