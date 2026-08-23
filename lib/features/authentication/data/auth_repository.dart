import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/core/services/persistence_service.dart';
import 'package:trackx/features/authentication/domain/auth_state.dart';
import 'package:trackx/core/services/sync_service.dart';
import 'package:trackx/features/calendar/providers/calendar_provider.dart';

// SharedPreferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main()');
});

// PersistenceService Provider
final persistenceServiceProvider = Provider<PersistenceService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PersistenceService(prefs);
});

// AuthRepository implementation
class AuthRepository extends StateNotifier<AuthState> {
  final PersistenceService _persistence;
  final Ref? _ref;
  fb.FirebaseAuth? _firebaseAuth;
  FirebaseFirestore? _firestore;

  AuthRepository(this._persistence, [this._ref]) : super(AuthState.initial()) {
    _init();
  }

  void _init() {
    try {
      _firebaseAuth = fb.FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;

      _firebaseAuth!.authStateChanges().listen((fbUser) async {
        if (fbUser != null) {
          _ref?.read(syncServiceProvider).setActiveUser(fbUser.uid);
          await _loadUserProfileFromFirestoreOrCache(fbUser);
        } else {
          _ref?.read(syncServiceProvider).setActiveUser(null);
          final token = _persistence.getAuthToken();
          final profile = _persistence.getUserProfile();

          if (token != null && profile != null) {
            state = AuthState.authenticated(profile);
          } else {
            state = AuthState.unauthenticated();
          }
        }
      });
    } catch (_) {
      // Offline / Test environment fallback
      final token = _persistence.getAuthToken();
      final profile = _persistence.getUserProfile();
      if (token != null && profile != null) {
        state = AuthState.authenticated(profile);
      } else {
        state = AuthState.unauthenticated();
      }
    }
  }

  Future<void> _loadUserProfileFromFirestoreOrCache(fb.User fbUser) async {
    // 1. Instant Cache-First: If profile is cached locally, authenticate immediately!
    final cachedProfile = _persistence.getUserProfile(fbUser.uid);
    if (cachedProfile != null) {
      await _persistence.saveAuthToken(fbUser.uid);
      state = AuthState.authenticated(cachedProfile);
    } else {
      // 2. Instant Optimistic Profile: Don't block UI on Firestore roundtrips
      final initialProfile = UserProfile(
        id: fbUser.uid,
        name: fbUser.displayName ?? '',
        email: fbUser.email ?? '',
        branch: '',
        semester: 1,
        globalTarget: 75.0,
        themeMode: 'dark',
        themeColorPack: 'purple',
        onboardingCompleted: false,
        createdTimestamp: DateTime.now().millisecondsSinceEpoch,
        updatedTimestamp: DateTime.now().millisecondsSinceEpoch,
      );
      await _persistence.saveAuthToken(fbUser.uid);
      await _persistence.saveUserProfile(initialProfile);
      state = AuthState.authenticated(initialProfile);
    }

    // 3. Fast background sync with Firestore (non-blocking)
    _syncProfileFromFirestoreBackground(fbUser);
  }

  Future<void> _syncProfileFromFirestoreBackground(fb.User fbUser) async {
    try {
      if (_firestore == null) return;
      final doc = await _firestore!
          .collection('users')
          .doc(fbUser.uid)
          .get()
          .timeout(const Duration(seconds: 3));

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final String name = data['name']?.toString() ?? '';
        final String department =
            data['department']?.toString() ??
            data['branch']?.toString() ??
            '';
        final bool isOnboarded =
            data['onboardingCompleted'] == true ||
            (name.isNotEmpty && department.isNotEmpty);

        final profile = UserProfile(
          id: fbUser.uid,
          name: name.isNotEmpty ? name : (fbUser.displayName ?? ''),
          email: data['email']?.toString() ?? fbUser.email ?? '',
          branch: department,
          semester: (data['semester'] as num?)?.toInt() ?? 1,
          globalTarget: (data['globalTarget'] as num?)?.toDouble() ?? 75.0,
          themeMode: data['themeMode']?.toString() ?? 'dark',
          themeColorPack: data['themeColorPack']?.toString() ?? 'purple',
          onboardingCompleted: isOnboarded,
          createdTimestamp: data['createdTimestamp'] is int
              ? data['createdTimestamp']
              : (data['createdAt'] is Timestamp
                    ? (data['createdAt'] as Timestamp).millisecondsSinceEpoch
                    : DateTime.now().millisecondsSinceEpoch),
          updatedTimestamp: data['updatedTimestamp'] is int
              ? data['updatedTimestamp']
              : (data['updatedAt'] is Timestamp
                    ? (data['updatedAt'] as Timestamp).millisecondsSinceEpoch
                    : DateTime.now().millisecondsSinceEpoch),
          collegeName: data['collegeName']?.toString(),
          registrationNumber: data['registrationNumber']?.toString(),
          programmeName: data['programmeName']?.toString(),
          joiningYear: (data['joiningYear'] as num?)?.toInt(),
          expectedGraduationYear: (data['expectedGraduationYear'] as num?)
              ?.toInt(),
          currentSemesterId: data['currentSemesterId']?.toString(),
          defaultAttendanceTarget: (data['defaultAttendanceTarget'] as num?)
              ?.toDouble(),
          preferredLanguage: data['preferredLanguage']?.toString() ?? 'en',
          preferredTimezone: data['preferredTimezone']?.toString() ?? 'UTC',
          preferredStudySessionMinutes:
              (data['preferredStudySessionMinutes'] as num?)?.toInt() ?? 25,
          cloudSyncEnabled: data['cloudSyncEnabled'] ?? true,
        );

        await _persistence.saveUserProfile(profile);
        state = AuthState.authenticated(profile);
      }
    } catch (_) {
      // Ignored for background sync; local state is already loaded
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading();
    try {
      if (_firebaseAuth == null) {
        state = AuthState.error('Authentication service is not available.');
        return;
      }
      final cred = await _firebaseAuth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = cred.user;
      if (fbUser != null) {
        await _loadUserProfileFromFirestoreOrCache(fbUser);
        return;
      }
      state = AuthState.error('No user account returned from sign-in.');
    } on fb.FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found with this email.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Incorrect email or password. Please verify your credentials.';
          break;
        case 'invalid-email':
          msg = 'The email address is invalid.';
          break;
        case 'user-disabled':
          msg = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          msg = 'Too many failed attempts. Please wait a moment and try again.';
          break;
        case 'network-request-failed':
          msg = 'Network connection failed. Please check your internet connection.';
          break;
        default:
          msg = e.message ?? 'Login failed (${e.code}).';
      }
      state = AuthState.error(msg);
    } catch (e) {
      state = AuthState.error('Login failed: ${e.toString()}');
    }
  }

  Future<void> register(String email, String password) async {
    state = AuthState.loading();
    try {
      if (_firebaseAuth == null) {
        state = AuthState.error('Authentication service is not available.');
        return;
      }
      final cred = await _firebaseAuth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = cred.user;
      if (fbUser != null) {
        await _loadUserProfileFromFirestoreOrCache(fbUser);
        return;
      }
      state = AuthState.error('Failed to create user account.');
    } on fb.FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          msg = 'The email address is invalid.';
          break;
        case 'weak-password':
          msg = 'Password is too weak. Please use at least 6 characters.';
          break;
        case 'operation-not-allowed':
          msg = 'Email/password sign-in is not enabled in Firebase Console.';
          break;
        case 'network-request-failed':
          msg = 'Network connection failed. Please check your internet connection.';
          break;
        default:
          msg = e.message ?? 'Registration failed (${e.code}).';
      }
      state = AuthState.error(msg);
    } catch (e) {
      state = AuthState.error('Registration failed: ${e.toString()}');
    }
  }



  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      if (_firebaseAuth != null) {
        await _firebaseAuth!.sendPasswordResetEmail(email: email.trim());
        return true;
      }
      return false;
    } on fb.FirebaseAuthException catch (e) {
      state = AuthState.error(e.message ?? 'Failed to send password reset email.');
      return false;
    } catch (e) {
      state = AuthState.error('Failed to send reset email: ${e.toString()}');
      return false;
    }
  }

  Future<void> completeOnboarding(
    String name,
    String branch,
    int semester,
    double target,
  ) async {
    final currentProfile = state.userProfile;
    final uid = currentProfile?.id ?? _firebaseAuth?.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final updated =
        (currentProfile ??
                UserProfile(
                  id: uid,
                  name: name,
                  email: _firebaseAuth?.currentUser?.email ?? '',
                  branch: branch,
                  semester: semester,
                  globalTarget: target,
                  themeMode: 'dark',
                  themeColorPack: 'purple',
                  onboardingCompleted: true,
                  createdTimestamp: DateTime.now().millisecondsSinceEpoch,
                  updatedTimestamp: DateTime.now().millisecondsSinceEpoch,
                ))
            .copyWith(
              id: uid,
              name: name,
              branch: branch,
              semester: semester,
              globalTarget: target,
              onboardingCompleted: true,
              updatedTimestamp: DateTime.now().millisecondsSinceEpoch,
            );

    await _persistence.saveUserProfile(updated);
    state = AuthState.authenticated(updated);

    // Save permanently to Firestore users/{uid}
    try {
      if (_firestore != null) {
        _firestore!.collection('users').doc(uid).set({
          'id': uid,
          'name': name,
          'department': branch,
          'branch': branch,
          'email': updated.email,
          'semester': semester,
          'globalTarget': target,
          'themeMode': updated.themeMode,
          'themeColorPack': updated.themeColorPack,
          'onboardingCompleted': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).catchError((_) {
          _ref
              ?.read(syncServiceProvider)
              .addToQueue('profile', uid, 'update', updated.toMap());
        });
      }
    } catch (_) {
      // Enqueue to sync service if offline
      _ref
          ?.read(syncServiceProvider)
          .addToQueue('profile', uid, 'update', updated.toMap());
    }
  }

  Future<void> updateProfile(
    String name,
    String branch,
    int semester,
    double target, {
    String? collegeName,
    String? registrationNumber,
    String? programmeName,
    int? joiningYear,
    int? expectedGraduationYear,
    String? currentSemesterId,
    double? defaultAttendanceTarget,
    String? preferredLanguage,
    String? preferredTimezone,
    int? preferredStudySessionMinutes,
    bool? cloudSyncEnabled,
  }) async {
    final currentProfile = state.userProfile;
    if (currentProfile == null) return;
    final uid = currentProfile.id;

    final updated = currentProfile.copyWith(
      name: name,
      branch: branch,
      semester: semester,
      globalTarget: target,
      collegeName: collegeName,
      registrationNumber: registrationNumber,
      programmeName: programmeName,
      joiningYear: joiningYear,
      expectedGraduationYear: expectedGraduationYear,
      currentSemesterId: currentSemesterId,
      defaultAttendanceTarget: defaultAttendanceTarget,
      preferredLanguage: preferredLanguage,
      preferredTimezone: preferredTimezone,
      preferredStudySessionMinutes: preferredStudySessionMinutes,
      cloudSyncEnabled: cloudSyncEnabled,
      updatedTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await _persistence.saveUserProfile(updated);
    state = AuthState.authenticated(updated);

    try {
      if (_firestore != null) {
        _firestore!.collection('users').doc(uid).set({
          'name': name,
          'department': branch,
          'branch': branch,
          'semester': semester,
          'globalTarget': target,
          'collegeName': collegeName,
          'registrationNumber': registrationNumber,
          'programmeName': programmeName,
          'joiningYear': joiningYear,
          'expectedGraduationYear': expectedGraduationYear,
          'currentSemesterId': currentSemesterId,
          'defaultAttendanceTarget': defaultAttendanceTarget,
          'preferredLanguage': preferredLanguage,
          'preferredTimezone': preferredTimezone,
          'preferredStudySessionMinutes': preferredStudySessionMinutes,
          'cloudSyncEnabled': cloudSyncEnabled,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).catchError((_) {
          _ref
              ?.read(syncServiceProvider)
              .addToQueue('profile', updated.id, 'update', updated.toMap());
        });
      }
    } catch (_) {
      _ref
          ?.read(syncServiceProvider)
          .addToQueue('profile', updated.id, 'update', updated.toMap());
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth?.signOut();
    } catch (_) {}
    try {
      await _ref?.read(calendarRepositoryProvider.notifier).disconnect();
    } catch (_) {}
    _ref?.read(syncServiceProvider).setActiveUser(null);
    await _persistence.clearSession();
    state = AuthState.unauthenticated();
  }
}

// AuthRepository Provider
final authRepositoryProvider = StateNotifierProvider<AuthRepository, AuthState>(
  (ref) {
    final persistence = ref.watch(persistenceServiceProvider);
    return AuthRepository(persistence, ref);
  },
);
