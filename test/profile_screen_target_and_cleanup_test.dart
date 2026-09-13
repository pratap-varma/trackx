import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/core/services/persistence_service.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/profile/presentation/profile_screen.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ProfileScreen top AppBar icons are removed and target initializes properly',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'global_attendance_target': 78.0,
    });
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs);

    final profile = UserProfile(
      id: 'test-user-id',
      name: 'Pratap Varma',
      email: 'pratap@example.com',
      branch: 'Computer Science',
      semester: 5,
      globalTarget: 78.0,
      themeMode: 'dark',
      themeColorPack: 'purple',
      onboardingCompleted: true,
      createdTimestamp: 1000,
      updatedTimestamp: 2000,
    );
    await persistence.saveUserProfile(profile);
    await persistence.saveAuthToken('auth-token');

    final authRepo = AuthRepository(persistence);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWith((ref) => authRepo),
          activeSemesterProvider.overrideWithValue(null),
          subjectRepositoryProvider.overrideWith((ref) => SubjectRepository(prefs)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ProfileScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Top-Left Settings icon is removed from AppBar
    expect(find.byIcon(Icons.settings_outlined), findsNothing);

    // 2. Verify Top-Right Edit icon is removed from AppBar
    expect(find.byIcon(Icons.edit_outlined), findsNothing);

    // 3. Verify Global Attendance Target shows 78% (not hardcoded 85%)
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('85%'), findsNothing);
  });
}
