import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/services/widget_data_service.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Widget Auto-Refresh Interval & Background Sync Tests', () {
    late SharedPreferences prefs;
    late WidgetDataService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = WidgetDataService(prefs);
    });

    test('WidgetDataService defaults to 30 minutes refresh interval', () {
      expect(service.getRefreshIntervalMinutes(), equals(30));
    });

    test('setRefreshIntervalMinutes persists and returns updated value', () async {
      await service.setRefreshIntervalMinutes(15);
      expect(service.getRefreshIntervalMinutes(), equals(15));
      expect(prefs.getInt(WidgetDataService.refreshIntervalKey), equals(15));

      await service.setRefreshIntervalMinutes(60);
      expect(service.getRefreshIntervalMinutes(), equals(60));
      expect(prefs.getInt(WidgetDataService.refreshIntervalKey), equals(60));
    });

    test('updateWidgetsData saves refreshIntervalMinutes and lastUpdatedAt', () async {
      await service.setRefreshIntervalMinutes(15);

      await service.updateWidgetsData(
        overallAttendance: '88%',
        attendanceBadge: 'ON TRACK',
        attendanceBunkInfo: 'Safe to Bunk: 3',
        attendanceTargetInfo: 'Target: 80%',
        attendanceRatio: '22 / 25',
        scheduleDay: 'WEDNESDAY',
        scheduleBadge: '4 CLASSES',
        nextClassMeta: 'LECTURE',
        nextClassName: 'Data Structures',
        nextClassRoom: 'Room 302',
        scheduleSummary: '4 classes scheduled',
        classesToday: 4,
        scheduleSlotsJson: jsonEncode([
          {
            'badge': 'P1',
            'name': 'Data Structures',
            'time': '09:00 - 10:00',
            'status': 'NOW',
            'startMinutes': '540',
            'endMinutes': '600',
          }
        ]),
        examsHeader: 'EXAMS',
        examsBadge: '1 UPCOMING',
        nextExamMeta: 'EXAM',
        nextExamTitle: 'Midterm',
        nextExamDateTime: 'Tomorrow 10 AM',
        examsSummary: '1 exam upcoming',
        upcomingExamsCount: 1,
        examsSlotsJson: '[]',
      );

      final data = service.getWidgetData();
      expect(data['refreshIntervalMinutes'], equals(15));
      expect(data['overallAttendance'], equals('88%'));
      expect(data['lastUpdatedAt'], isNotNull);
      expect((data['lastUpdatedAt'] as num) > 0, isTrue);

      final slots = jsonDecode(data['scheduleSlotsJson'] as String) as List;
      expect(slots.first['startMinutes'], equals('540'));
      expect(slots.first['endMinutes'], equals('600'));
    });

    test('startPeriodicSync and stopPeriodicSync start and cancel timer cleanly', () {
      // Mock ref that does nothing
      final dummyRef = _DummyRef();
      service.startPeriodicSync(dummyRef);
      service.stopPeriodicSync();
    });

    test('syncWithAppData accurately records statsProvider percentage and overall safe bunks', () async {
      final mockStats = SemesterStats(
        totalPresent: 32,
        totalRecorded: 40,
        overallPercentage: 80.0,
        globalTarget: 75.0,
        subjectsBelowTarget: [],
        allSubjectStats: [],
        overallSafeBunks: 2,
        overallRequiredRecovery: 0,
      );

      final dummyRef = _MockStatsRef(mockStats);
      await service.syncWithAppData(dummyRef);

      final data = service.getWidgetData();
      expect(data['overallAttendance'], equals('80.0%'));
      expect(data['attendanceBadge'], equals('SAFE'));
      expect(data['attendanceBunkInfo'], contains('Safe to Miss: 2 classes'));
      expect(data['attendanceTargetInfo'], equals('Target: 75%'));
      expect(data['attendanceRatio'], equals('32 / 40 Conducted'));
    });
  });
}

class _DummyRef {
  dynamic read(dynamic provider) => null;
}

class _MockStatsRef {
  final SemesterStats stats;
  _MockStatsRef(this.stats);

  dynamic read(dynamic provider) {
    if (provider == statsProvider) {
      return stats;
    }
    return [];
  }
}
