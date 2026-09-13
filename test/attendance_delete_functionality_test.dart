import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('Deleting previously marked attendance removes record and decrements subject count with Undo support', () async {
    final subjectRepo = container.read(subjectRepositoryProvider.notifier);
    final attendanceRepo = container.read(attendanceRepositoryProvider.notifier);

    await subjectRepo.addSubject(
      'sem-1',
      'Mobile Systems',
      'Prof. Smith',
      0xFF5B5FEF,
      75.0,
      code: 'CS401',
    );

    final sub = container.read(subjectRepositoryProvider).first;
    expect(sub.presentClasses, 0);

    // Mark attendance for yesterday (previously marked)
    final pastDate = DateTime.now().subtract(const Duration(days: 2));
    final error = await attendanceRepo.markAttendance(
      userId: 'test_user',
      semesterId: 'sem-1',
      subjectId: sub.id,
      date: pastDate,
      periodNumber: 1,
      status: 'present',
    );
    expect(error, isNull);

    // Verify record exists in state and subject updated
    var records = container.read(attendanceRepositoryProvider);
    expect(records.length, 1);
    final markedRecord = records.first;
    expect(markedRecord.status, 'present');

    var updatedSub = container.read(subjectRepositoryProvider).first;
    expect(updatedSub.presentClasses, 1);

    // User triggers delete on previously marked attendance
    await attendanceRepo.deleteAttendance(markedRecord.id);

    // Verify record is removed from attendance state
    records = container.read(attendanceRepositoryProvider);
    expect(records.where((r) => r.id == markedRecord.id).toList(), isEmpty);

    // Verify subject present classes decremented back to 0
    updatedSub = container.read(subjectRepositoryProvider).first;
    expect(updatedSub.presentClasses, 0);

    // Verify Undo restores the record and count
    await attendanceRepo.insertRecord(markedRecord);
    records = container.read(attendanceRepositoryProvider);
    expect(records.length, 1);
    expect(records.first.id, markedRecord.id);

    updatedSub = container.read(subjectRepositoryProvider).first;
    expect(updatedSub.presentClasses, 1);
  });
}
