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

    test('calculateIfBunk and calculateIfAttend calculate exact projected percentage', () {
      // Current: 15 attended out of 20 total (75.0%)
      // If Bunk (1 class): (15 / 21) * 100 = 71.42857...% -> 71.4%
      final ifBunk = AttendanceCalculator.calculateIfBunk(15, 20);
      expect(ifBunk.toStringAsFixed(1), '71.4');

      // If Attend (1 class): (16 / 21) * 100 = 76.19047...% -> 76.2%
      final ifAttend = AttendanceCalculator.calculateIfAttend(15, 20);
      expect(ifAttend.toStringAsFixed(1), '76.2');
    });

    test('calculateIfBunk and calculateIfAttend handle 0 total classes gracefully', () {
      final ifBunk = AttendanceCalculator.calculateIfBunk(0, 0);
      expect(ifBunk.toStringAsFixed(1), '0.0');

      final ifAttend = AttendanceCalculator.calculateIfAttend(0, 0);
      expect(ifAttend.toStringAsFixed(1), '100.0');
    });

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
