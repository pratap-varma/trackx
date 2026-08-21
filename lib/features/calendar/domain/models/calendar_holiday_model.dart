import 'package:trackx/features/calendar/domain/models/calendar_event_model.dart';

class CalendarHoliday {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final bool isAllDay;
  final String calendarId;
  final String source;
  final String? location;

  CalendarHoliday({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.isAllDay,
    required this.calendarId,
    required this.source,
    this.location,
  });

  CalendarEvent toCalendarEvent() {
    return CalendarEvent(
      id: id,
      calendarId: calendarId,
      calendarName: 'Public Holidays',
      title: title,
      description: description,
      startDateTime: startDate,
      endDateTime: endDate,
      isAllDay: isAllDay,
      location: location,
      source: source,
      eventType: 'holiday',
    );
  }

  factory CalendarHoliday.fromCalendarEvent(CalendarEvent event) {
    return CalendarHoliday(
      id: event.id,
      title: event.title,
      description: event.description,
      startDate: event.startDateTime,
      endDate: event.endDateTime,
      isAllDay: event.isAllDay,
      calendarId: event.calendarId,
      source: event.source,
      location: event.location,
    );
  }

  /// Check if this holiday occurs on a specific calendar day
  bool occursOn(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (start.isAtSameMomentAs(end)) {
      return target.isAtSameMomentAs(start);
    }
    if (isAllDay) {
      return !target.isBefore(start) && target.isBefore(end);
    }
    return !target.isBefore(start) && !target.isAfter(end);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isAllDay': isAllDay,
      'calendarId': calendarId,
      'source': source,
      'location': location,
    };
  }

  factory CalendarHoliday.fromMap(Map<String, dynamic> map) {
    return CalendarHoliday(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
      isAllDay: map['isAllDay'] ?? true,
      calendarId: map['calendarId'] ?? '',
      source: map['source'] ?? 'Google Calendar',
      location: map['location'],
    );
  }
}
