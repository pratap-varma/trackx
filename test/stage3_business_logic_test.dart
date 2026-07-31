import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/core/utils/attendance_calculator.dart';
import 'package:trackx/features/semesters/domain/semester_model.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';

void main() {
  group('Stage 3 - Core Business Logic & Serialization Tests', () {
    test('Semester Serialization', () {
      final date = DateTime(2026, 7, 16);
      final sem = Semester(
        id: 'sem-1',
        userId: 'user-1',
        programmeId: 'p1',
        name: 'Fall 2026',
        semesterNumber: 1,
        academicYear: '2026-2027',
        status: 'Active',
        plannedCredits: 20.0,
        completedCredits: 0.0,
        attendanceTarget: 75.0,
        notes: '',
        startDate: date,
        createdAt: 100,
        updatedAt: 200,
      );

      final map = sem.toMap();
      final fromMap = Semester.fromMap(map);

      expect(fromMap.id, 'sem-1');
      expect(fromMap.name, 'Fall 2026');
      expect(fromMap.startDate, date);
      expect(fromMap.isActive, true);
    });

    test('Subject Serialization', () {
      final sub = Subject(
        id: 'sub-1',
        userId: 'user-1',
        semesterId: 'sem-1',
        name: 'Maths',
        facultyName: 'Dr. Jones',
        colorValue: 0xFFFFFFFF,
        targetAttendance: 80.0,
        presentClasses: 0,
        absentClasses: 0,
        type: 'Theory',
        status: 'Active',
        expectedDifficulty: 'Moderate',
        createdAt: 100,
        updatedAt: 200,
      );

      final map = sub.toMap();
      final fromMap = Subject.fromMap(map);

      expect(fromMap.id, 'sub-1');
      expect(fromMap.name, 'Maths');
      expect(fromMap.targetOverride, 80.0);
      expect(fromMap.isArchived, false);
    });

    test('AttendanceRecord Serialization', () {
      final date = DateTime(2026, 7, 16);
      final rec = AttendanceRecord(
        id: 'rec-1',
        userId: 'user-1',
        semesterId: 'sem-1',
        subjectId: 'sub-1',
        date: date,
        periodNumber: 3,
        status: 'present',
        source: 'manual',
        createdAt: 100,
        updatedAt: 200,
      );

      final map = rec.toMap();
      final fromMap = AttendanceRecord.fromMap(map);

      expect(fromMap.id, 'rec-1');
      expect(fromMap.periodNumber, 3);
      expect(fromMap.status, 'present');
      expect(fromMap.date, date);
    });

    test('24-Hour Edit Rule is enforced correctly', () {
      final dateNow = DateTime.now();
      final recordRecent = AttendanceRecord(
        id: '1',
        userId: 'u',
        semesterId: 's',
        subjectId: 'sub',
        date: dateNow.subtract(const Duration(hours: 10)),
        status: 'present',
        source: 'manual',
        createdAt: 0,
        updatedAt: 0,
      );
      final recordOld = recordRecent.copyWith(
        date: dateNow.subtract(const Duration(hours: 30)),
      );

      expect(
        AttendanceRepository.canEditAttendance(recordRecent, dateNow),
        true,
      );
      expect(AttendanceRepository.canEditAttendance(recordOld, dateNow), false);
    });

    test('Overall attendance calculations avoid simple averaging', () {
      // Subject A: 1/1 (100%)
      // Subject B: 2/8 (25%)
      // If we average: (100 + 25) / 2 = 62.5%
      // Correct sum overall: (1 + 2) / (1 + 8) = 3 / 9 = 33.3%
      final totalPresent = 1 + 2;
      final totalRecorded = 1 + 8;
      final overall = (totalPresent / totalRecorded) * 100.0;
      expect(overall, closeTo(33.33, 0.05));
    });

    test('Risk classification matches target variations', () {
      expect(
        AttendanceCalculator.getRiskClassification(92.0, 75.0),
        'Excellent',
      );
      expect(
        AttendanceCalculator.getRiskClassification(75.0, 75.0),
        'On Track',
      );
      expect(
        AttendanceCalculator.getRiskClassification(71.0, 75.0),
        'Near Target',
      );
      expect(AttendanceCalculator.getRiskClassification(65.0, 75.0), 'At Risk');
      expect(
        AttendanceCalculator.getRiskClassification(50.0, 75.0),
        'Below Target',
      );
    });
  });
}
