import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';

class AppLockState {
  final bool isBiometricsEnabled;
  final bool isPinEnabled;
  final bool hasPin;
  final bool isLocked;
  final bool isBiometricAvailable;
  final int failedAttempts;
  final DateTime? lockoutUntil;

  const AppLockState({
    required this.isBiometricsEnabled,
    required this.isPinEnabled,
    required this.hasPin,
    required this.isLocked,
    required this.isBiometricAvailable,
    this.failedAttempts = 0,
    this.lockoutUntil,
  });

  bool get isTemporarilyLockedOut {
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil!);
  }

  int get remainingLockoutSeconds {
    if (lockoutUntil == null) return 0;
    final diff = lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  AppLockState copyWith({
    bool? isBiometricsEnabled,
    bool? isPinEnabled,
    bool? hasPin,
    bool? isLocked,
    bool? isBiometricAvailable,
    int? failedAttempts,
    DateTime? Function()? lockoutUntil,
  }) {
    return AppLockState(
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      hasPin: hasPin ?? this.hasPin,
      isLocked: isLocked ?? this.isLocked,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil:
          lockoutUntil != null ? lockoutUntil() : this.lockoutUntil,
    );
  }
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  final SharedPreferences _prefs;
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  static const String _keyBiometrics = 'sec_biometrics_enabled';
  static const String _keyPinEnabled = 'sec_pin_enabled';
  static const String _keyPinCode = 'sec_user_pin_code';

  static AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  static IOSOptions _getIOSOptions() => const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      );

  AppLockNotifier(
    this._prefs,
    this._localAuth, {
    this._secureStorage = const FlutterSecureStorage(),
  }) : super(
          AppLockState(
            isBiometricsEnabled: _prefs.getBool(_keyBiometrics) ?? false,
            isPinEnabled: _prefs.getBool(_keyPinEnabled) ?? false,
            hasPin: false,
            isLocked: (_prefs.getBool(_keyBiometrics) ?? false) ||
                (_prefs.getBool(_keyPinEnabled) ?? false),
            isBiometricAvailable: false,
          ),
        ) {
    _init();
  }

  Future<void> _init() async {
    // 1. Legacy Migration: If plaintext PIN was stored in SharedPreferences,
    // move it directly into hardware-backed FlutterSecureStorage and purge from SharedPreferences.
    final legacyPin = _prefs.getString(_keyPinCode);
    if (legacyPin != null && legacyPin.isNotEmpty) {
      await _secureStorage.write(
        key: _keyPinCode,
        value: legacyPin,
        aOptions: _getAndroidOptions(),
        iOptions: _getIOSOptions(),
      );
      await _prefs.remove(_keyPinCode);
    }

    // 2. Check if PIN exists in Hardware Keystore / Keychain secure storage
    final securePin = await _secureStorage.read(
      key: _keyPinCode,
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
    final hasSecurePin = securePin != null && securePin.isNotEmpty;

    // 3. Check biometric capability
    bool canAuth = false;
    try {
      final canAuthWithBiometrics = await _localAuth.canCheckBiometrics;
      canAuth = canAuthWithBiometrics || await _localAuth.isDeviceSupported();
    } catch (_) {
      canAuth = false;
    }

    final isLocked =
        (state.isBiometricsEnabled) || (state.isPinEnabled && hasSecurePin);

    state = state.copyWith(
      hasPin: hasSecurePin,
      isBiometricAvailable: canAuth,
      isLocked: isLocked,
    );
  }

  /// Authenticate user using biometric fingerprint / Face ID
  Future<bool> authenticateBiometric(
      {String reason = 'Authenticate to access TrackX'}) async {
    if (state.isTemporarilyLockedOut) return false;

    try {
      final available = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!available) return false;

      final didAuth = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
      if (didAuth) {
        unlock();
      }
      return didAuth;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Set / Update the user's 4-digit PIN into Hardware Keystore / Keychain
  Future<void> setPin(String pin) async {
    await _secureStorage.write(
      key: _keyPinCode,
      value: pin,
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
    await _prefs.setBool(_keyPinEnabled, true);
    // Ensure no legacy plaintext key exists in SharedPreferences
    await _prefs.remove(_keyPinCode);
    state = state.copyWith(
      hasPin: true,
      isPinEnabled: true,
      failedAttempts: 0,
      lockoutUntil: () => null,
    );
  }

  /// Verify entered PIN against Hardware Keystore / Keychain stored PIN with rate limiting
  Future<bool> verifyPin(String enteredPin) async {
    if (state.isTemporarilyLockedOut) {
      return false;
    }

    final storedPin = await _secureStorage.read(
      key: _keyPinCode,
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );

    if (storedPin != null && storedPin.isNotEmpty && storedPin == enteredPin) {
      unlock();
      return true;
    }

    final newAttempts = state.failedAttempts + 1;
    if (newAttempts >= 5) {
      // 30 seconds temporary lockout after 5 consecutive failed attempts
      state = state.copyWith(
        failedAttempts: newAttempts,
        lockoutUntil: () => DateTime.now().add(const Duration(seconds: 30)),
      );
    } else {
      state = state.copyWith(failedAttempts: newAttempts);
    }

    return false;
  }

  /// Toggle Biometrics On/Off
  Future<bool> toggleBiometrics(bool enabled) async {
    if (enabled) {
      final success = await authenticateBiometric(
          reason: 'Verify biometric identity to enable Biometric Lock');
      if (success) {
        await _prefs.setBool(_keyBiometrics, true);
        state = state.copyWith(isBiometricsEnabled: true);
        return true;
      } else {
        return false;
      }
    } else {
      await _prefs.setBool(_keyBiometrics, false);
      state = state.copyWith(isBiometricsEnabled: false);
      return true;
    }
  }

  /// Toggle PIN protection On/Off
  Future<void> togglePinEnabled(bool enabled) async {
    await _prefs.setBool(_keyPinEnabled, enabled);
    state = state.copyWith(isPinEnabled: enabled);
  }

  /// Remove stored PIN from Hardware Keystore / Keychain
  Future<void> removePin() async {
    await _secureStorage.delete(
      key: _keyPinCode,
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
    await _prefs.remove(_keyPinCode);
    await _prefs.setBool(_keyPinEnabled, false);
    state = state.copyWith(
      hasPin: false,
      isPinEnabled: false,
      failedAttempts: 0,
      lockoutUntil: () => null,
    );
  }

  void lock() {
    if (state.isBiometricsEnabled || (state.isPinEnabled && state.hasPin)) {
      state = state.copyWith(isLocked: true);
    }
  }

  void unlock() {
    state = state.copyWith(
      isLocked: false,
      failedAttempts: 0,
      lockoutUntil: () => null,
    );
  }
}

final appLockProvider =
    StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final localAuth = LocalAuthentication();
  return AppLockNotifier(prefs, localAuth);
});
