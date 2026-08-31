import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/core/models/user_role.dart';
import 'package:trackx/core/services/activity_logger.dart';
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

  /// Read the Firebase Custom Claim role for [fbUser] without forcing a token refresh.
  /// Returns [UserRole.student] if claims are unavailable or malformed.
  Future<UserRole> _readRoleFromClaims(fb.User fbUser) async {
    try {
      final tokenResult = await fbUser.getIdTokenResult();
      return parseUserRole(tokenResult.claims?['role']);
    } catch (_) {
      return UserRole.student;
    }
  }

  Future<void> _loadUserProfileFromFirestoreOrCache(fb.User fbUser) async {
    // Read Firebase Custom Claim role (non-blocking best-effort)
    final role = await _readRoleFromClaims(fbUser);

    // 1. Instant Cache-First: If profile is cached locally, check suspension & authenticate immediately!
    final cachedProfile = _persistence.getUserProfile(fbUser.uid);
    if (cachedProfile != null) {
      if (cachedProfile.isSuspended) {
        await _firebaseAuth?.signOut();
        await _persistence.clearSession();
        state = AuthState.error(
          'Your account has been suspended by an administrator. Please contact support.',
        );
        return;
      }
      await _persistence.saveAuthToken(fbUser.uid);
      state = AuthState.authenticated(cachedProfile, role: role);
      ActivityLogger().logEvent('user_login', userId: fbUser.uid);
      
      // Fast background sync with Firestore (non-blocking)
      _syncProfileFromFirestoreBackground(fbUser);
      return;
    }
    
    // 2. Fetch from Firestore (blocking, for returning users on fresh install)
    try {
      final fetchedProfile = await _fetchProfileFromFirestore(fbUser);
      if (fetchedProfile != null) {
        if (fetchedProfile.isSuspended) {
          await _firebaseAuth?.signOut();
          await _persistence.clearSession();
          state = AuthState.error(
            'Your account has been suspended by an administrator. Please contact support.',
          );
          return;
        }
        await _persistence.saveAuthToken(fbUser.uid);
        await _persistence.saveUserProfile(fetchedProfile);
        state = AuthState.authenticated(fetchedProfile, role: role);
        ActivityLogger().logEvent('user_login', userId: fbUser.uid);

        // Immediately pull all user data (semesters, subjects, tasks, notes, etc.)
        try {
          _ref?.read(syncServiceProvider).triggerSync();
        } catch (_) {}
        return;
      }

      // 3. Fallback or New User: Initial Optimistic Profile
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
      state = AuthState.authenticated(initialProfile, role: role);
    } catch (e) {
      // Network error or timeout - do not create a blank profile!
      state = AuthState.error(
        'Network error while loading profile. Please check your connection and try again.',
      );
    }
  }

  Future<void> _syncProfileFromFirestoreBackground(fb.User fbUser) async {
    final profile = await _fetchProfileFromFirestore(fbUser);
    if (profile != null) {
      if (profile.isSuspended) {
        await _firebaseAuth?.signOut();
        await _persistence.clearSession();
        state = AuthState.error(
          'Your account has been suspended by an administrator. Please contact support.',
        );
        return;
      }
      await _persistence.saveUserProfile(profile);
      // Preserve existing role — background sync should not downgrade role
      state = AuthState.authenticated(profile, role: state.role);
    }
    try {
      _ref?.read(syncServiceProvider).triggerSync();
    } catch (_) {}
  }

  // ─── Role & Claims API ──────────────────────────────────────────────────

  /// Returns the current user's role from Firebase ID Token claims.
  /// Always returns [UserRole.student] if unauthenticated or claims unavailable.
  /// Does NOT force a token refresh — use [refreshUserClaims] for that.
  Future<UserRole> getCurrentUserRole() async {
    try {
      final fbUser = _firebaseAuth?.currentUser;
      if (fbUser == null) return UserRole.student;
      final tokenResult = await fbUser.getIdTokenResult();
      return parseUserRole(tokenResult.claims?['role']);
    } catch (_) {
      return UserRole.student;
    }
  }

  /// Returns true only if the current user's Firebase Custom Claim contains
  /// `{ "role": "admin" }`. Reads from the current token without forcing refresh.
  Future<bool> isAdmin() async {
    return (await getCurrentUserRole()) == UserRole.admin;
  }

  /// Forces a Firebase ID Token refresh so newly assigned Custom Claims become
  /// visible in the app without requiring sign-out.
  ///
  /// Call this after an admin role has been assigned via the backend script.
  /// Do NOT call this on every widget rebuild.
  Future<void> refreshUserClaims() async {
    try {
      final fbUser = _firebaseAuth?.currentUser;
      if (fbUser == null) return;

      // Force token refresh from Firebase servers
      await fbUser.getIdToken(true);

      // Read updated role
      final role = await _readRoleFromClaims(fbUser);

      // Update state with fresh role (profile stays the same)
      final currentProfile = state.userProfile;
      if (currentProfile != null) {
        state = AuthState.authenticated(currentProfile, role: role);
      }
    } catch (_) {
      // Refresh failure is non-fatal; keep existing state
    }
  }

  Future<bool> _checkUserHasCloudData(String uid) async {
    if (_firestore == null) return false;
    final collections = [
      'semesters',
      'subjects',
      'attendances',
      'tasks',
      'timetables',
      'notes',
      'flashcardDecks',
      'cgpaCourses',
      'programmes',
    ];
    for (final col in collections) {
      try {
        final snap = await _firestore!
            .collection('users')
            .doc(uid)
            .collection(col)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 4));
        if (snap.docs.isNotEmpty) return true;
      } catch (_) {}
    }
    return false;
  }

  Future<UserProfile?> _fetchProfileFromFirestore(fb.User fbUser) async {
    try {
      if (_firestore == null) return null;

      // 1. Check direct document: users/{uid}
      var doc = await _firestore!
          .collection('users')
          .doc(fbUser.uid)
          .get()
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic>? data = doc.exists ? doc.data() : null;

      // 2. Fallback: Search by email if direct UID document is absent
      if (data == null && fbUser.email != null && fbUser.email!.isNotEmpty) {
        try {
          final querySnap = await _firestore!
              .collection('users')
              .where('email', isEqualTo: fbUser.email)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 5));
          if (querySnap.docs.isNotEmpty) {
            data = querySnap.docs.first.data();
          }
        } catch (_) {}
      }

      if (data != null) {
        final String name = data['name']?.toString() ?? fbUser.displayName ?? '';
        final String department =
            data['department']?.toString() ??
            data['branch']?.toString() ??
            '';

        bool isOnboarded = data['onboardingCompleted'] == true ||
            data['onboardingCompleted'] == 'true' ||
            data['onboarded'] == true ||
            data['onboarded'] == 'true' ||
            department.isNotEmpty ||
            (data['semester'] != null && (data['semester'] as num) > 0) ||
            (data['globalTarget'] != null && (data['globalTarget'] as num) > 0) ||
            data['currentSemesterId'] != null ||
            data['programmeName'] != null;

        // If not explicitly flagged as onboarded, check if user has existing subcollections
        if (!isOnboarded) {
          final hasData = await _checkUserHasCloudData(fbUser.uid);
          if (hasData) {
            isOnboarded = true;
          }
        }

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

        // Auto-heal / repair Firestore doc if onboarding flag was missing in cloud
        if (isOnboarded && data['onboardingCompleted'] != true) {
          _firestore!.collection('users').doc(fbUser.uid).set({
            'onboardingCompleted': true,
            'onboarded': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)).catchError((_) {});
        }

        return profile;
      } else {
        // Document didn't exist at root: check if user has existing subcollections in cloud
        final hasData = await _checkUserHasCloudData(fbUser.uid);
        if (hasData) {
          final recoveredProfile = UserProfile(
            id: fbUser.uid,
            name: fbUser.displayName ?? '',
            email: fbUser.email ?? '',
            branch: 'General',
            semester: 1,
            globalTarget: 75.0,
            themeMode: 'dark',
            themeColorPack: 'purple',
            onboardingCompleted: true,
            createdTimestamp: DateTime.now().millisecondsSinceEpoch,
            updatedTimestamp: DateTime.now().millisecondsSinceEpoch,
          );
          await _firestore!.collection('users').doc(fbUser.uid).set({
            'id': fbUser.uid,
            'name': fbUser.displayName ?? '',
            'email': fbUser.email ?? '',
            'onboardingCompleted': true,
            'onboarded': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)).catchError((_) {});
          return recoveredProfile;
        }
      }
    } catch (e) {
      // Rethrow so the caller knows this was a network issue, not a missing profile
      rethrow;
    }
    return null;
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
        // Let authStateChanges listener handle profile loading
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

  Future<void> signInWithGoogle() async {
    state = AuthState.loading();
    try {
      if (_firebaseAuth == null) {
        state = AuthState.error('Authentication service is not available.');
        return;
      }
      final googleSignIn = GoogleSignIn();
      try {
        await googleSignIn.signOut();
      } catch (_) {}
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = AuthState.unauthenticated();
        return; // The user canceled the sign-in
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final fb.AuthCredential credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final fb.UserCredential userCredential =
          await _firebaseAuth!.signInWithCredential(credential);
      final fb.User? fbUser = userCredential.user;
      if (fbUser != null) {
        // Let authStateChanges listener handle profile loading
        return;
      }
      state = AuthState.error('No user account returned from sign-in.');
    } catch (e) {
      state = AuthState.error('Google Sign-In failed: ${e.toString()}');
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
        // Let authStateChanges listener handle profile loading
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
        await _firestore!.collection('users').doc(uid).set({
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
          'onboarded': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      // Enqueue to sync service if offline or timeout
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
        await _firestore!.collection('users').doc(uid).set({
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
          'onboardingCompleted': true,
          'onboarded': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      _ref
          ?.read(syncServiceProvider)
          .addToQueue('profile', updated.id, 'update', updated.toMap());
    }
  }

  Future<void> saveFullProfile(UserProfile updated) async {
    await _persistence.saveUserProfile(updated);
    state = AuthState.authenticated(updated);

    try {
      if (_firestore != null) {
        await _firestore!.collection('users').doc(updated.id).set({
          'themeMode': updated.themeMode,
          'themeColorPack': updated.themeColorPack,
          'onboardingCompleted': updated.onboardingCompleted,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth?.signOut();
    } catch (_) {}
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await googleSignIn.disconnect();
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
