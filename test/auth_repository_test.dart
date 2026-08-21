import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/core/services/persistence_service.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/authentication/domain/auth_state.dart';

void main() {
  group('AuthRepository and UserProfile Tests', () {
    late PersistenceService persistenceService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      persistenceService = PersistenceService(prefs);
    });

    test(
      'UserProfile mapping converts to and from map correctly with department support',
      () {
        final profile = UserProfile(
          id: 'uid-123',
          name: 'Test Student',
          email: 'test@example.com',
          branch: 'Computer Science',
          semester: 4,
          globalTarget: 80.0,
          themeMode: 'dark',
          themeColorPack: 'purple',
          onboardingCompleted: true,
          createdTimestamp: 1000,
          updatedTimestamp: 2000,
        );

        final map = profile.toMap();
        expect(map['department'], 'Computer Science');
        expect(map['branch'], 'Computer Science');

        final fromMap = UserProfile.fromMap(map);
        expect(fromMap.id, 'uid-123');
        expect(fromMap.name, 'Test Student');
        expect(fromMap.department, 'Computer Science');
        expect(fromMap.branch, 'Computer Science');
        expect(fromMap.email, 'test@example.com');
        expect(fromMap.semester, 4);
        expect(fromMap.globalTarget, 80.0);
        expect(fromMap.onboardingCompleted, true);
      },
    );

    test('PersistenceService isolates user-specific profile caching', () async {
      final profileUserA = UserProfile(
        id: 'user_a',
        name: 'Alice',
        email: 'alice@example.com',
        branch: 'CSE',
        semester: 2,
        globalTarget: 85.0,
        themeMode: 'dark',
        themeColorPack: 'purple',
        onboardingCompleted: true,
        createdTimestamp: 1000,
        updatedTimestamp: 2000,
      );

      final profileUserB = UserProfile(
        id: 'user_b',
        name: 'Bob',
        email: 'bob@example.com',
        branch: 'ECE',
        semester: 6,
        globalTarget: 75.0,
        themeMode: 'dark',
        themeColorPack: 'blue',
        onboardingCompleted: false,
        createdTimestamp: 1000,
        updatedTimestamp: 2000,
      );

      await persistenceService.saveUserProfile(profileUserA);
      expect(persistenceService.getUserProfile('user_a')?.name, 'Alice');

      await persistenceService.saveUserProfile(profileUserB);
      expect(persistenceService.getUserProfile('user_b')?.name, 'Bob');
      expect(persistenceService.getUserProfile('user_a')?.name, 'Alice');

      // Clearing session does not wipe user cache
      await persistenceService.clearSession();
      expect(persistenceService.getUserProfile('user_a')?.name, 'Alice');
      expect(persistenceService.getUserProfile('user_b')?.name, 'Bob');
    });

    test(
      'AuthRepository initializes unauthenticated when storage is empty',
      () {
        final authRepo = AuthRepository(persistenceService);
        expect(authRepo.state.status, AuthStatus.unauthenticated);
      },
    );

    test('Logout transitions state to unauthenticated', () async {
      final authRepo = AuthRepository(persistenceService);
      await authRepo.logout();
      expect(authRepo.state.status, AuthStatus.unauthenticated);
      expect(authRepo.state.userProfile, null);
    });
  });
}
