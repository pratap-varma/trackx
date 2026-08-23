import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trackx/features/calendar/domain/models/calendar_event_model.dart';


class DeviceCalendarService {
  final DeviceCalendarPlugin _deviceCalendarPlugin;

  DeviceCalendarService() : _deviceCalendarPlugin = DeviceCalendarPlugin();

  /// Request device calendar permissions
  Future<bool> requestCalendarAccess() async {
    final status = await Permission.calendarFullAccess.request();
    if (status.isGranted) return true;
    final statusReadOnly = await Permission.calendar.request();
    return statusReadOnly.isGranted;
  }

  /// Check if calendar access is granted
  Future<bool> hasCalendarAccess() async {
    final hasPerms = await _deviceCalendarPlugin.hasPermissions();
    return hasPerms?.isSuccess == true && hasPerms?.data == true;
  }

  /// Disconnect (No-op for native calendar, but clears cached connection state)
  Future<void> disconnect() async {
    // Native calendar doesn't need explicit sign-out
  }

  /// Retrieve the user's available device Calendars
  Future<List<UserCalendarInfo>> getUserCalendars() async {
    final hasPerms = await hasCalendarAccess();
    if (!hasPerms) return [];

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    final results = <UserCalendarInfo>[];
    
    if (calendarsResult.isSuccess && calendarsResult.data != null) {
      for (final cal in calendarsResult.data!) {
        final name = cal.name ?? 'Calendar';
        final isHoliday = name.toLowerCase().contains('holiday') || name.toLowerCase().contains('festival');
        
        results.add(UserCalendarInfo(
          id: cal.id ?? '',
          name: name,
          description: cal.accountName,
          isPrimary: cal.isDefault ?? false,
          isHolidayCalendar: isHoliday,
          backgroundColor: cal.color?.toString(),
          isSelected: true,
        ));
      }
    }
    return results;
  }

  /// Retrieve the holiday calendar ID
  Future<String> resolveHolidayCalendarId({String countryCode = 'indian'}) async {
    final cals = await getUserCalendars();
    final holidayCal = cals.where((c) => c.isHolidayCalendar).firstOrNull;
    return holidayCal?.id ?? 'default_holiday';
  }

  /// Fetch events from multiple selected calendars
  Future<List<CalendarEvent>> fetchMultipleCalendarEvents({
    required List<UserCalendarInfo> calendars,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final hasPerms = await hasCalendarAccess();
    if (!hasPerms) return [];

    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 7));
    final end = endDate ?? now.add(const Duration(days: 365));
    
    final allEvents = <CalendarEvent>[];
    final seenKeys = <String>{};
    
    for (final cal in calendars.where((c) => c.isSelected)) {
      final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
        cal.id,
        RetrieveEventsParams(startDate: start, endDate: end),
      );
      
      if (eventsResult.isSuccess && eventsResult.data != null) {
        for (final event in eventsResult.data!) {
          final isHoliday = cal.isHolidayCalendar;
          final title = event.title ?? 'Event';
          final resolvedType = isHoliday
                  ? (title.toLowerCase().contains('festival') ? 'festival' : 'holiday')
                  : 'personal';
                  
          final dedupeKey = '${cal.id}_${event.eventId}';
          if (!seenKeys.contains(dedupeKey)) {
            seenKeys.add(dedupeKey);
            

            allEvents.add(CalendarEvent(
              id: event.eventId ?? dedupeKey,
              calendarId: cal.id,
              calendarName: cal.name ?? 'Calendar',
              title: title,
              description: event.description,
              startDateTime: event.start ?? start,
              endDateTime: event.end ?? end,
              isAllDay: event.allDay ?? false,
              location: event.location,
              source: 'Device Calendar',
              eventType: resolvedType,
            ));
          }
        }
      }
    }
    
    allEvents.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return allEvents;
  }
}
