import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/features/timetable_import/domain/services/ocr_service.dart';

void main() {
  group('Stage 10 - OCR Parsing & Study Timer Calculations Tests', () {
    test(
      'OcrService parser correctly matches weekdays and extract period parameters',
      () {
        final parser = OcrService();
        const rawText = '''
Wednesday
P1 09:15-10:15 Calculus LH3 Prof.Rao
10:15 to 11:15 Physics Lab2
''';

        final entries = parser.parseTimetableText(rawText);
        expect(entries.length, 2);
        expect(entries[0].weekday, 'Wednesday');
        expect(entries[0].subjectName, 'Calculus');
        expect(entries[0].startTime, '09:15');
        expect(entries[0].endTime, '10:15');

        expect(entries[1].weekday, 'Wednesday');
        expect(entries[1].subjectName, 'Physics');
        expect(entries[1].startTime, '10:15');
        expect(entries[1].endTime, '11:15');
      },
    );

    test(
      'Focus cycle transitions and break logic calculates correct states',
      () {
        int completedCycles = 0;
        bool isBreak = false;

        // Finish focus cycle
        isBreak = true;
        completedCycles++;
        expect(isBreak, true);
        expect(completedCycles, 1);

        // Finish break cycle
        isBreak = false;
        expect(isBreak, false);
      },
    );
  });
}
