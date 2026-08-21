import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/core/services/persistence_service.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/main.dart';
import 'package:trackx/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  testWidgets('Smoke test verifying dashboard loads', (
    WidgetTester tester,
  ) async {
    // Initialize Mock User Profile
    final profile = UserProfile(
      id: 'test-user',
      name: 'Rohan Sharma',
      email: 'test@example.com',
      branch: 'CSE',
      semester: 5,
      globalTarget: 75.0,
      themeMode: 'dark',
      themeColorPack: 'purple',
      onboardingCompleted: true,
      createdTimestamp: 0,
      updatedTimestamp: 0,
    );

    // Initialize Mock SharedPreferences with active session
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await PersistenceService(prefs).saveUserProfile(profile);
    await PersistenceService(prefs).saveAuthToken('test-token');

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TrackXApp(),
      ),
    );

    // Process all animations and router redirection frames
    await tester.pumpAndSettle();

    // Verify that DashboardScreen is rendered
    expect(find.textContaining('Rohan'), findsOneWidget);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
