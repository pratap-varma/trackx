enum ImportSessionStatus {
  created,
  processing,
  reviewRequired,
  validated,
  imported,
  failed,
}

class DetectedTimetableEntry {
  final String weekday; // e.g. Monday
  final int period; // e.g. 1
  final String startTime; // e.g. 09:15
  final String endTime; // e.g. 10:15
  final String subjectName; // e.g. DBMS
  final String faculty;
  final String room;

  DetectedTimetableEntry({
    required this.weekday,
    required this.period,
    required this.startTime,
    required this.endTime,
    required this.subjectName,
    required this.faculty,
    required this.room,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekday': weekday,
      'period': period,
      'startTime': startTime,
      'endTime': endTime,
      'subjectName': subjectName,
      'faculty': faculty,
      'room': room,
    };
  }

  factory DetectedTimetableEntry.fromMap(Map<String, dynamic> map) {
    return DetectedTimetableEntry(
      weekday: map['weekday'] ?? 'Monday',
      period: map['period'] ?? 1,
      startTime: map['startTime'] ?? '09:15',
      endTime: map['endTime'] ?? '10:15',
      subjectName: map['subjectName'] ?? '',
      faculty: map['faculty'] ?? '',
      room: map['room'] ?? '',
    );
  }
}

class TimetableImportSession {
  final String id;
  final String sourceType;
  final ImportSessionStatus status;
  final List<DetectedTimetableEntry> detectedEntries;

  TimetableImportSession({
    required this.id,
    required this.sourceType,
    required this.status,
    required this.detectedEntries,
  });
}
