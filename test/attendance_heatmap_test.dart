import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/attendance/domain/models/attendance_heatmap_models.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/attendance/providers/attendance_heatmap_provider.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';

void main() {
  group('DayAttendanceSummary Status & Calculations', () {
    test('100% Present day calculation', () {
      final date = DateTime(2026, 8, 25);
      final records = [
        AttendanceRecord(
          id: 'r1',
          userId: 'u1',
          semesterId: 's1',
          subjectId: 'sub-math',
          date: date,
          periodNumber: 1,
          status: 'present',
          source: 'manual',
          createdAt: 0,
          updatedAt: 0,
        ),
        AttendanceRecord(
          id: 'r2',
          userId: 'u1',
          semesterId: 's1',
          subjectId: 'sub-phys',
          date: date,
          periodNumber: 2,
          status: 'present',
          source: 'manual',
          createdAt: 0,
          updatedAt: 0,
        ),
      ];

      final summary = DayAttendanceSummary.fromRecords(date, records);

      expect(summary.totalClasses, equals(2));
      expect(summary.presentClasses, equals(2));
      expect(summary.absentClasses, equals(0));
      expect(summary.status, equals(DayAttendanceStatus.fullPresent));
      expect(summary.percentage, equals(100.0));
      expect(summary.statusColor, equals(const Color(0xFF10B981)));
    });

    test('Partial Attendance day calculation', () {
      final date = DateTime(2026, 8, 25);
      final records = [
        AttendanceRecord(
          id: 'r1',
          userId: 'u1',
          semesterId: 's1',
          subjectId: 'sub-math',
          date: date,
          periodNumber: 1,
          status: 'present',
          source: 'manual',
          createdAt: 0,
          updatedAt: 0,
        ),
        AttendanceRecord(
          id: 'r2',
          userId: 'u1',
          semesterId: 's1',
          subjectId: 'sub-phys',
          date: date,
          periodNumber: 2,
          status: 'absent',
          source: 'manual',
          createdAt: 0,
          updatedAt: 0,
        ),
      ];

      final summary = DayAttendanceSummary.fromRecords(date, records);

      expect(summary.totalClasses, equals(2));
      expect(summary.presentClasses, equals(1));
      expect(summary.absentClasses, equals(1));
      expect(summary.status, equals(DayAttendanceStatus.partial));
      expect(summary.percentage, equals(50.0));
      expect(summary.statusColor, equals(const Color(0xFF3B82F6)));
    });

    test('100% Absent day calculation', () {
      final date = DateTime(2026, 8, 25);
      final records = [
        AttendanceRecord(
          id: 'r1',
          userId: 'u1',
          semesterId: 's1',
          subjectId: 'sub-math',
          date: date,
          periodNumber: 1,
          status: 'absent',
          source: 'manual',
          createdAt: 0,
          updatedAt: 0,
        ),
      ];

      final summary = DayAttendanceSummary.fromRecords(date, records);

      expect(summary.totalClasses, equals(1));
      expect(summary.presentClasses, equals(0));
      expect(summary.absentClasses, equals(1));
      expect(summary.status, equals(DayAttendanceStatus.fullAbsent));
      expect(summary.percentage, equals(0.0));
      expect(summary.statusColor, equals(const Color(0xFFEF4444)));
    });

    test('Cancelled / Holiday day calculation', () {
      final date = DateTime(2026, 8, 25);
      final records = [
        AttendanceRecord(
          id: 'r1',
          userId: 'u1',
          semesterId: 's1',
          subjectId: 'sub-math',
          date: date,
          periodNumber: 1,
          status: 'cancelled',
          source: 'manual',
          createdAt: 0,
          updatedAt: 0,
        ),
      ];

      final summary = DayAttendanceSummary.fromRecords(date, records);

      expect(summary.totalClasses, equals(1));
      expect(summary.cancelledClasses, equals(1));
      expect(summary.status, equals(DayAttendanceStatus.holidayOrCancelled));
      expect(summary.statusColor, equals(const Color(0xFF8151EB)));
    });

    test('Empty day (no classes scheduled)', () {
      final date = DateTime(2026, 8, 25);
      final summary = DayAttendanceSummary.fromRecords(date, []);

      expect(summary.totalClasses, equals(0));
      expect(summary.status, equals(DayAttendanceStatus.noClasses));
      expect(summary.percentage, equals(0.0));
    });

    test('Heatmap provider correctly filters subject by ID and case-insensitive matching', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          attendanceRepositoryProvider.overrideWith((ref) => _FakeAttendanceRepository([
                AttendanceRecord(
                  id: 'rec-1',
                  userId: 'u1',
                  semesterId: 'sem-1',
                  subjectId: 'sub-tp',
                  date: DateTime(2026, 8, 20),
                  periodNumber: 1,
                  status: 'present',
                  source: 'manual',
                  createdAt: 0,
                  updatedAt: 0,
                ),
                AttendanceRecord(
                  id: 'rec-2',
                  userId: 'u1',
                  semesterId: 'sem-1',
                  subjectId: 'sub-tp',
                  date: DateTime(2026, 8, 21),
                  periodNumber: 1,
                  status: 'absent',
                  source: 'manual',
                  createdAt: 0,
                  updatedAt: 0,
                ),
                AttendanceRecord(
                  id: 'rec-3',
                  userId: 'u1',
                  semesterId: 'sem-1',
                  subjectId: 'sub-other',
                  date: DateTime(2026, 8, 21),
                  periodNumber: 2,
                  status: 'present',
                  source: 'manual',
                  createdAt: 0,
                  updatedAt: 0,
                ),
              ])),
          subjectRepositoryProvider.overrideWith((ref) => _FakeSubjectRepository([
                Subject(
                  id: 'sub-tp',
                  userId: 'u1',
                  semesterId: 'sem-1',
                  name: 'T&P',
                  code: 'TP-101',
                  facultyName: 'Prof. Sharma',
                  type: 'Theory',
                  status: 'Active',
                  expectedDifficulty: 'Moderate',
                  colorValue: 4283060450,
                  presentClasses: 1,
                  absentClasses: 1,
                  targetAttendance: 75.0,
                  createdAt: 0,
                  updatedAt: 0,
                ),
              ])),
        ],
      );

      final dataset = container.read(attendanceHeatmapProvider('sub-tp'));
      expect(dataset.totalClassesAttended, 1);
      expect(dataset.totalClassesMissed, 1);
      expect(dataset.totalDaysLogged, 2);

      // Verify name match also works seamlessly
      final datasetByName = container.read(attendanceHeatmapProvider('T&P'));
      expect(datasetByName.totalClassesAttended, 1);
      expect(datasetByName.totalClassesMissed, 1);
      expect(datasetByName.totalDaysLogged, 2);
    });
  });
}

class _FakeAttendanceRepository extends StateNotifier<List<AttendanceRecord>>
    implements AttendanceRepository {
  _FakeAttendanceRepository(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubjectRepository extends StateNotifier<List<Subject>>
    implements SubjectRepository {
  _FakeSubjectRepository(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
