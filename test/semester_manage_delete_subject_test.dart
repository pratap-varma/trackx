import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/core/services/persistence_service.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/semesters/domain/semester_model.dart';
import 'package:trackx/features/semesters/presentation/semester_manage_screen.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';

class _FakeSemesterRepository extends StateNotifier<List<Semester>>
    implements SemesterRepository {
  _FakeSemesterRepository(super.state);

  @override
  Future<void> deleteSemester(String id) async {
    state = state.where((s) => s.id != id).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubjectRepository extends StateNotifier<List<Subject>>
    implements SubjectRepository {
  _FakeSubjectRepository(super.state);

  @override
  Future<void> deleteSubject(String id) async {
    state = state.where((s) => s.id != id).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SemesterManageScreen displays subjects and allows deleting individual subject', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final profile = UserProfile(
      id: 'test-user',
      name: 'Test Student',
      email: 'test@trackx.app',
      branch: 'CSE',
      semester: 4,
      globalTarget: 75.0,
      themeMode: 'dark',
      themeColorPack: 'purple',
      onboardingCompleted: true,
      createdTimestamp: 0,
      updatedTimestamp: 0,
    );
    await PersistenceService(prefs).saveUserProfile(profile);
    await PersistenceService(prefs).saveAuthToken('token');

    final testSemester = Semester(
      id: 'sem-test-1',
      userId: 'test-user',
      programmeId: 'prog-1',
      name: 'Spring 2026',
      semesterNumber: 4,
      academicYear: '2025-2026',
      startDate: DateTime.now(),
      status: 'Active',
      plannedCredits: 20,
      completedCredits: 0,
      attendanceTarget: 75.0,
      notes: '',
      createdAt: 0,
      updatedAt: 0,
    );

    final testSubject = Subject(
      id: 'sub-test-1',
      userId: 'test-user',
      semesterId: 'sem-test-1',
      name: 'Distributed Systems',
      facultyName: 'Dr. Alan',
      colorValue: 0xFF5B5FEF,
      type: 'Theory',
      status: 'Active',
      expectedDifficulty: 'Moderate',
      presentClasses: 0,
      absentClasses: 0,
      targetAttendance: 80.0,
      code: 'CS401',
      createdAt: 0,
      updatedAt: 0,
    );

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        semesterRepositoryProvider.overrideWith((ref) => _FakeSemesterRepository([testSemester])),
        subjectRepositoryProvider.overrideWith((ref) => _FakeSubjectRepository([testSubject])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SemesterManageScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify semester and subject name are visible
    expect(find.text('Spring 2026'), findsOneWidget);
    expect(find.text('Distributed Systems'), findsOneWidget);
    expect(find.textContaining('CS401'), findsOneWidget);
    expect(find.textContaining('Dr. Alan'), findsOneWidget);

    // Tap delete subject icon
    final deleteSubjectBtn = find.byTooltip('Delete Distributed Systems');
    expect(deleteSubjectBtn, findsOneWidget);
    await tester.tap(deleteSubjectBtn);
    await tester.pumpAndSettle();

    // Verify confirmation modal opened
    expect(find.text('Delete Subject'), findsOneWidget);
    expect(
      find.textContaining('Are you sure you want to delete "Distributed Systems"'),
      findsOneWidget,
    );

    // Tap Confirm Delete Subject
    final confirmBtn = find.widgetWithText(ElevatedButton, 'Delete');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Verify subject is deleted from state and UI updates
    final subjects = container.read(subjectRepositoryProvider);
    expect(subjects.isEmpty, isTrue);
    expect(find.text('Distributed Systems'), findsNothing);
    expect(find.text('No subjects enrolled in this semester yet.'), findsOneWidget);
  });
}
