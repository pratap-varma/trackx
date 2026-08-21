class UserCalendarInfo {
  final String id;
  final String name;
  final String? description;
  final bool isPrimary;
  final bool isHolidayCalendar;
  final String? backgroundColor;
  final bool isSelected;

  UserCalendarInfo({
    required this.id,
    required this.name,
    this.description,
    this.isPrimary = false,
    this.isHolidayCalendar = false,
    this.backgroundColor,
    this.isSelected = true,
  });

  UserCalendarInfo copyWith({
    String? id,
    String? name,
    String? description,
    bool? isPrimary,
    bool? isHolidayCalendar,
    String? backgroundColor,
    bool? isSelected,
  }) {
    return UserCalendarInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isPrimary: isPrimary ?? this.isPrimary,
      isHolidayCalendar: isHolidayCalendar ?? this.isHolidayCalendar,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isPrimary': isPrimary,
      'isHolidayCalendar': isHolidayCalendar,
      'backgroundColor': backgroundColor,
      'isSelected': isSelected,
    };
  }

  factory UserCalendarInfo.fromMap(Map<String, dynamic> map) {
    return UserCalendarInfo(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      isPrimary: map['isPrimary'] ?? false,
      isHolidayCalendar: map['isHolidayCalendar'] ?? false,
      backgroundColor: map['backgroundColor'],
      isSelected: map['isSelected'] ?? true,
    );
  }
}

class CalendarEvent {
  final String id;
  final String calendarId;
  final String calendarName;
  final String title;
  final String? description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isAllDay;
  final String? location;
  final String source;
  final String eventType; // 'personal', 'holiday', 'festival', 'other'

  CalendarEvent({
    required this.id,
    required this.calendarId,
    required this.calendarName,
    required this.title,
    this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.isAllDay,
    this.location,
    this.source = 'Google Calendar',
    this.eventType = 'personal',
  });

  /// Check if this event occurs on a specific calendar day (in local time)
  bool occursOn(DateTime date) {
    final localStart = startDateTime.toLocal();
    final localEnd = endDateTime.toLocal();

    final target = DateTime(date.year, date.month, date.day);
    final startDay = DateTime(
      localStart.year,
      localStart.month,
      localStart.day,
    );
    final endDay = DateTime(localEnd.year, localEnd.month, localEnd.day);

    if (startDay.isAtSameMomentAs(endDay)) {
      return target.isAtSameMomentAs(startDay);
    }
    if (isAllDay) {
      return !target.isBefore(startDay) && target.isBefore(endDay);
    }
    return !target.isBefore(startDay) && !target.isAfter(endDay);
  }

  bool get isHolidayOrFestival =>
      eventType == 'holiday' || eventType == 'festival';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'calendarId': calendarId,
      'calendarName': calendarName,
      'title': title,
      'description': description,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'isAllDay': isAllDay,
      'location': location,
      'source': source,
      'eventType': eventType,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] ?? '',
      calendarId: map['calendarId'] ?? '',
      calendarName: map['calendarName'] ?? 'Google Calendar',
      title: map['title'] ?? '',
      description: map['description'],
      startDateTime:
          DateTime.tryParse(map['startDateTime'] ?? '')?.toLocal() ??
          DateTime.now(),
      endDateTime:
          DateTime.tryParse(map['endDateTime'] ?? '')?.toLocal() ??
          DateTime.now(),
      isAllDay: map['isAllDay'] ?? false,
      location: map['location'],
      source: map['source'] ?? 'Google Calendar',
      eventType: map['eventType'] ?? 'personal',
    );
  }
}
