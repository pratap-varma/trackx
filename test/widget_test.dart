import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/authentication/domain/auth_state.dart';
import 'package:trackx/main.dart';
import 'package:trackx/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  testWidgets('Smoke test verifying dashboard loads', (
    WidgetTester tester,
  ) async {
    // Initialize Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TrackXApp(),
      ),
    );

    // Mock Login trigger to display Dashboard screen (MainShell)
    final element = tester.element(find.byType(TrackXApp));
    final container = ProviderScope.containerOf(element);

    // Authenticate user with completed onboarding to bypass splash/login redirections
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

    container.read(authRepositoryProvider.notifier).state =
        AuthState.authenticated(profile);

    // Re-trigger build frame to process redirect changes
    await tester.pumpAndSettle();

    // Verify that DashboardScreen is rendered
    expect(find.text('Rohan Sharma'), findsOneWidget);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
