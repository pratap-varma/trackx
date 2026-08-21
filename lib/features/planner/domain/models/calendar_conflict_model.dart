enum ConflictItemType { collegeClass, studyTask, googleEvent }

enum ConflictType {
  classAndGoogleEvent,
  classAndStudyTask,
  studyTaskAndGoogleEvent,
  googleEventAndGoogleEvent,
  multipleEvents,
}

enum ConflictSeverity { warning, high }

class ConflictScheduleItem {
  final String id;
  final String title;
  final ConflictItemType itemType;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? subtitle;
  final String? location;

  ConflictScheduleItem({
    required this.id,
    required this.title,
    required this.itemType,
    required this.startDateTime,
    required this.endDateTime,
    this.subtitle,
    this.location,
  });

  String get typeLabel {
    switch (itemType) {
      case ConflictItemType.collegeClass:
        return 'College Class';
      case ConflictItemType.studyTask:
        return 'Study Task';
      case ConflictItemType.googleEvent:
        return 'Google Calendar Event';
    }
  }

  String get typeEmoji {
    switch (itemType) {
      case ConflictItemType.collegeClass:
        return '🎓';
      case ConflictItemType.studyTask:
        return '📚';
      case ConflictItemType.googleEvent:
        return '📅';
    }
  }
}

class CalendarConflict {
  final String id;
  final ConflictScheduleItem firstEvent;
  final ConflictScheduleItem secondEvent;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final ConflictType conflictType;
  final ConflictSeverity severity;

  CalendarConflict({
    required this.id,
    required this.firstEvent,
    required this.secondEvent,
    required this.startDateTime,
    required this.endDateTime,
    required this.conflictType,
    this.severity = ConflictSeverity.warning,
  });

  int get overlapMinutes =>
      endDateTime.difference(startDateTime).inMinutes.clamp(0, 1440);

  String get summary {
    switch (conflictType) {
      case ConflictType.classAndGoogleEvent:
        return 'Calendar event overlaps with college class';
      case ConflictType.classAndStudyTask:
        return 'Study task overlaps with college class';
      case ConflictType.studyTaskAndGoogleEvent:
        return 'Study task overlaps with calendar event';
      case ConflictType.googleEventAndGoogleEvent:
        return 'Multiple calendar events overlap';
      case ConflictType.multipleEvents:
        return 'Multiple events overlap at the same time';
    }
  }

  String get description {
    switch (conflictType) {
      case ConflictType.classAndGoogleEvent:
        return '"${secondEvent.title}" overlaps with class "${firstEvent.title}".';
      case ConflictType.classAndStudyTask:
        return 'Study task "${secondEvent.title}" overlaps with class "${firstEvent.title}".';
      case ConflictType.studyTaskAndGoogleEvent:
        return 'Study task "${firstEvent.title}" overlaps with "${secondEvent.title}".';
      case ConflictType.googleEventAndGoogleEvent:
        return 'Google Calendar events "${firstEvent.title}" and "${secondEvent.title}" overlap.';
      case ConflictType.multipleEvents:
        return 'Multiple overlapping events scheduled at the same time.';
    }
  }
}
