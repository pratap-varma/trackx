import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';

class AppLockState {
  final bool isBiometricsEnabled;
  final bool isPinEnabled;
  final bool hasPin;
  final bool isLocked;
  final bool isBiometricAvailable;

  const AppLockState({
    required this.isBiometricsEnabled,
    required this.isPinEnabled,
    required this.hasPin,
    required this.isLocked,
    required this.isBiometricAvailable,
  });

  AppLockState copyWith({
    bool? isBiometricsEnabled,
    bool? isPinEnabled,
    bool? hasPin,
    bool? isLocked,
    bool? isBiometricAvailable,
  }) {
    return AppLockState(
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      hasPin: hasPin ?? this.hasPin,
      isLocked: isLocked ?? this.isLocked,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
    );
  }
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  final SharedPreferences _prefs;
  final LocalAuthentication _localAuth;

  static const String _keyBiometrics = 'sec_biometrics_enabled';
  static const String _keyPinEnabled = 'sec_pin_enabled';
  static const String _keyPinCode = 'sec_user_pin_code';

  AppLockNotifier(this._prefs, this._localAuth)
      : super(
          AppLockState(
            isBiometricsEnabled: _prefs.getBool(_keyBiometrics) ?? false,
            isPinEnabled: _prefs.getBool(_keyPinEnabled) ?? false,
            hasPin: (_prefs.getString(_keyPinCode) ?? '').isNotEmpty,
            isLocked: (_prefs.getBool(_keyBiometrics) ?? false) ||
                ((_prefs.getBool(_keyPinEnabled) ?? false) &&
                    (_prefs.getString(_keyPinCode) ?? '').isNotEmpty),
            isBiometricAvailable: false,
          ),
        ) {
    _initBiometricsCheck();
  }

  Future<void> _initBiometricsCheck() async {
    try {
      final canAuthWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuth = canAuthWithBiometrics || await _localAuth.isDeviceSupported();
      state = state.copyWith(isBiometricAvailable: canAuth);
    } catch (_) {
      state = state.copyWith(isBiometricAvailable: false);
    }
  }

  /// Authenticate user using biometric fingerprint / Face ID
  Future<bool> authenticateBiometric({String reason = 'Authenticate to access TrackX'}) async {
    try {
      final available = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
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

  /// Set / Update the user's 4-digit PIN
  Future<void> setPin(String pin) async {
    await _prefs.setString(_keyPinCode, pin);
    await _prefs.setBool(_keyPinEnabled, true);
    state = state.copyWith(
      hasPin: true,
      isPinEnabled: true,
    );
  }

  /// Verify entered PIN against stored PIN
  bool verifyPin(String enteredPin) {
    final storedPin = _prefs.getString(_keyPinCode) ?? '';
    if (storedPin.isNotEmpty && storedPin == enteredPin) {
      unlock();
      return true;
    }
    return false;
  }

  /// Toggle Biometrics On/Off
  Future<bool> toggleBiometrics(bool enabled) async {
    if (enabled) {
      // First verify that biometrics work on this device
      final success = await authenticateBiometric(reason: 'Verify biometric identity to enable Biometric Lock');
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

  /// Remove stored PIN
  Future<void> removePin() async {
    await _prefs.remove(_keyPinCode);
    await _prefs.setBool(_keyPinEnabled, false);
    state = state.copyWith(
      hasPin: false,
      isPinEnabled: false,
    );
  }

  void lock() {
    if (state.isBiometricsEnabled || (state.isPinEnabled && state.hasPin)) {
      state = state.copyWith(isLocked: true);
    }
  }

  void unlock() {
    state = state.copyWith(isLocked: false);
  }
}

final appLockProvider = StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final localAuth = LocalAuthentication();
  return AppLockNotifier(prefs, localAuth);
});
