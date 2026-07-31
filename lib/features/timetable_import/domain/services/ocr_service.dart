import 'package:trackx/features/timetable_import/domain/models/timetable_import_models.dart';

class OcrService {
  List<DetectedTimetableEntry> parseTimetableText(String rawText) {
    final List<DetectedTimetableEntry> entries = [];
    final lines = rawText.split('\n');

    String currentDay = 'Monday';

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Detect Day Header
      final dayPattern = RegExp(
        r'\b(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|Mon|Tue|Wed|Thu|Fri|Sat|Sun)\b',
        caseSensitive: false,
      );
      final dayMatch = dayPattern.firstMatch(trimmed);
      if (dayMatch != null) {
        final dayStr = dayMatch.group(0)!.toLowerCase();
        if (dayStr.startsWith('mon')) currentDay = 'Monday';
        if (dayStr.startsWith('tue')) currentDay = 'Tuesday';
        if (dayStr.startsWith('wed')) currentDay = 'Wednesday';
        if (dayStr.startsWith('thu')) currentDay = 'Thursday';
        if (dayStr.startsWith('fri')) currentDay = 'Friday';
        if (dayStr.startsWith('sat')) currentDay = 'Saturday';
        if (dayStr.startsWith('sun')) currentDay = 'Sunday';
        continue;
      }

      // Detect class entry: e.g. "P1 09:15-10:15 Math LH2 Prof. Kumar"
      // Or simply "09:15-10:15 DBMS"
      final timePattern = RegExp(
        r'(\d{1,2}[:.]\d{2})\s*(?:-|to)\s*(\d{1,2}[:.]\d{2})',
        caseSensitive: false,
      );
      final timeMatch = timePattern.firstMatch(trimmed);

      if (timeMatch != null) {
        final startTime = timeMatch.group(1)!.replaceAll('.', ':');
        final endTime = timeMatch.group(2)!.replaceAll('.', ':');

        // Extract subject: look for words after the time match
        final afterTime = trimmed.substring(timeMatch.end).trim();
        if (afterTime.isNotEmpty) {
          final words = afterTime.split(RegExp(r'\s+'));
          final subject =
              words[0]; // First word is typically the subject name or abbreviation
          final room = words.length > 1 ? words[1] : 'LH-1';
          final faculty = words.length > 2 ? words.sublist(2).join(' ') : 'TBD';

          entries.add(
            DetectedTimetableEntry(
              weekday: currentDay,
              period: entries.length + 1,
              startTime: startTime,
              endTime: endTime,
              subjectName: subject,
              faculty: faculty,
              room: room,
            ),
          );
        }
      }
    }

    return entries;
  }
}
