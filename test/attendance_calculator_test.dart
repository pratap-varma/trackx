import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/core/utils/attendance_calculator.dart';

void main() {
  group('Attendance Calculator Tests', () {
    test('calculateSafeBunks returns 0 when attendance is below target', () {
      final bunks = AttendanceCalculator.calculateSafeBunks(5, 10, 75.0); // 50%
      expect(bunks, 0);
    });

    test(
      'calculateSafeBunks calculates correct bunk count when above target',
      () {
        final bunks = AttendanceCalculator.calculateSafeBunks(
          12,
          12,
          75.0,
        ); // 100%
        expect(bunks, 4);
      },
    );

    test(
      'calculateRequiredRecovery returns correct class count to reach target',
      () {
        final recovery = AttendanceCalculator.calculateRequiredRecovery(
          6,
          10,
          75.0,
        ); // 60%
        expect(recovery, 6);
      },
    );

    test('getRiskClassification returns correct classifications', () {
      expect(
        AttendanceCalculator.getRiskClassification(95.0, 75.0),
        'Excellent',
      );
      expect(
        AttendanceCalculator.getRiskClassification(78.0, 75.0),
        'On Track',
      );
      expect(
        AttendanceCalculator.getRiskClassification(72.0, 75.0),
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
