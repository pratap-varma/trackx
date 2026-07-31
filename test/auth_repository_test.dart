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

    test('UserProfile mapping converts to and from map correctly', () {
      final profile = UserProfile(
        id: '123',
        name: 'Test Student',
        email: 'test@example.com',
        branch: 'CSE',
        semester: 4,
        globalTarget: 80.0,
        themeMode: 'dark',
        themeColorPack: 'purple',
        onboardingCompleted: true,
        createdTimestamp: 1000,
        updatedTimestamp: 2000,
      );

      final map = profile.toMap();
      final fromMap = UserProfile.fromMap(map);

      expect(fromMap.id, '123');
      expect(fromMap.name, 'Test Student');
      expect(fromMap.email, 'test@example.com');
      expect(fromMap.semester, 4);
      expect(fromMap.globalTarget, 80.0);
      expect(fromMap.onboardingCompleted, true);
    });

    test(
      'Login with mock credentials registers authentication state',
      () async {
        final authRepo = AuthRepository(persistenceService);

        // Verify initial state is unauthenticated since shared_prefs is empty
        expect(authRepo.state.status, AuthStatus.unauthenticated);

        // Perform login
        await authRepo.login('test@example.com', 'password123');

        // Verify authenticated state
        expect(authRepo.state.status, AuthStatus.authenticated);
        expect(authRepo.state.userProfile?.name, 'Rohan Sharma');
        expect(authRepo.state.userProfile?.email, 'test@example.com');
      },
    );

    test('Logout clears session states', () async {
      final authRepo = AuthRepository(persistenceService);

      // Log in first
      await authRepo.login('test@example.com', 'password123');
      expect(authRepo.state.status, AuthStatus.authenticated);

      // Log out
      await authRepo.logout();
      expect(authRepo.state.status, AuthStatus.unauthenticated);
      expect(authRepo.state.userProfile, null);
    });
  });
}
