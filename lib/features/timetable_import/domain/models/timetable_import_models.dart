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
  final String type; // e.g. class, break, lab
  final double confidence; // e.g. 0.95

  DetectedTimetableEntry({
    required this.weekday,
    required this.period,
    required this.startTime,
    required this.endTime,
    required this.subjectName,
    required this.faculty,
    required this.room,
    this.type = 'class',
    this.confidence = 1.0,
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
      'type': type,
      'confidence': confidence,
    };
  }

  factory DetectedTimetableEntry.fromMap(Map<String, dynamic> map) {
    return DetectedTimetableEntry(
      weekday: map['weekday'] ?? map['day'] ?? 'Monday',
      period: map['period'] ?? 1,
      startTime: map['startTime'] ?? '09:15',
      endTime: map['endTime'] ?? '10:15',
      subjectName: map['subjectName'] ?? map['subject'] ?? '',
      faculty: map['faculty'] ?? '',
      room: map['room'] ?? '',
      type: map['type'] ?? 'class',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
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

class DetectedExamEntry {
  final String title;
  final String subjectName;
  final String examType; // Midterm, Final, Quiz, Practical, Internal
  final DateTime examDate;
  final String startTime;
  final String endTime;
  final String room;
  final String syllabus;

  DetectedExamEntry({
    required this.title,
    required this.subjectName,
    this.examType = 'Midterm',
    required this.examDate,
    required this.startTime,
    this.endTime = '',
    this.room = '',
    this.syllabus = 'Chapters 1-5 / Syllabus Units',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subjectName': subjectName,
      'examType': examType,
      'examDate': examDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'syllabus': syllabus,
    };
  }

  factory DetectedExamEntry.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(map['examDate'] ?? '');
    } catch (_) {
      parsedDate = DateTime.now().add(const Duration(days: 7));
    }

    return DetectedExamEntry(
      title: map['title'] ?? 'Exam',
      subjectName: map['subjectName'] ?? 'Subject',
      examType: map['examType'] ?? 'Midterm',
      examDate: parsedDate,
      startTime: map['startTime'] ?? '10:00 AM',
      endTime: map['endTime'] ?? '01:00 PM',
      room: map['room'] ?? '',
      syllabus: map['syllabus'] ?? 'Complete Syllabus',
    );
  }
}

class DetectedAttendanceEntry {
  final String subjectName;
  final String status;
  final int? periodNumber;
  final DateTime? date;

  DetectedAttendanceEntry({
    required this.subjectName,
    required this.status,
    this.periodNumber,
    this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'status': status,
      'periodNumber': periodNumber,
      'date': date?.toIso8601String(),
    };
  }

  factory DetectedAttendanceEntry.fromMap(Map<String, dynamic> map) {
    DateTime? parsedDate;
    if (map['date'] != null) {
      try {
        parsedDate = DateTime.parse(map['date'].toString());
      } catch (_) {}
    }

    return DetectedAttendanceEntry(
      subjectName: map['subjectName'] ?? map['course_name'] ?? 'Unknown Subject',
      status: map['status'] ?? 'present',
      periodNumber: map['periodNumber'] is int 
          ? map['periodNumber'] 
          : int.tryParse('${map['periodNumber']}'),
      date: parsedDate,
    );
  }
}
