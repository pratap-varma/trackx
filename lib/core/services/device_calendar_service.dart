import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trackx/features/calendar/domain/models/calendar_event_model.dart';

class DeviceCalendarService {
  final DeviceCalendarPlugin _deviceCalendarPlugin;

  DeviceCalendarService() : _deviceCalendarPlugin = DeviceCalendarPlugin();

  /// Request device calendar permissions
  Future<bool> requestCalendarAccess() async {
    try {
      final pluginRes = await _deviceCalendarPlugin.requestPermissions();
      if (pluginRes.isSuccess == true && pluginRes.data == true) {
        return true;
      }
    } catch (_) {}

    try {
      final fullStatus = await Permission.calendarFullAccess.request();
      if (fullStatus.isGranted) return true;
    } catch (_) {}

    try {
      final writeStatus = await Permission.calendarWriteOnly.request();
      if (writeStatus.isGranted) return true;
    } catch (_) {}

    return await hasCalendarAccess();
  }

  /// Check if calendar access is granted
  Future<bool> hasCalendarAccess() async {
    try {
      final hasPerms = await _deviceCalendarPlugin.hasPermissions();
      if (hasPerms.isSuccess == true && hasPerms.data == true) {
        return true;
      }
    } catch (_) {}

    try {
      if (await Permission.calendarFullAccess.isGranted ||
          await Permission.calendarWriteOnly.isGranted) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Disconnect (No-op for native calendar, but clears cached connection state)
  Future<void> disconnect() async {
    // Native calendar doesn't need explicit sign-out
  }

  /// Retrieve the user's available device Calendars with intelligent deduplication
  Future<List<UserCalendarInfo>> getUserCalendars() async {
    final hasPerms = await hasCalendarAccess();
    if (!hasPerms) {
      final granted = await requestCalendarAccess();
      if (!granted) return [];
    }

    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      final results = <UserCalendarInfo>[];
      final seenKeys = <String>{};
      
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        for (final cal in calendarsResult.data!) {
          final rawName = (cal.name ?? '').trim();
          final rawAccount = (cal.accountName ?? '').trim();
          if (rawName.isEmpty && rawAccount.isEmpty) continue;

          final lowerName = rawName.toLowerCase();
          final lowerAccount = rawAccount.toLowerCase();

          // Filter out internal system noise (contacts birthdays, reminders, phone local artifacts)
          if (lowerName == 'birthdays' ||
              lowerName == 'contacts' ||
              lowerName == 'reminders' ||
              lowerName == 'tasks' ||
              lowerName == 'phone' ||
              (lowerAccount == 'phone' && lowerName == 'my calendar')) {
            continue;
          }

          final isHoliday = lowerName.contains('holiday') ||
              lowerName.contains('festival') ||
              lowerName.contains('observance') ||
              lowerName.contains('vacation') ||
              lowerName.contains('public') ||
              lowerAccount.contains('holiday') ||
              lowerAccount.contains('festival') ||
              lowerAccount.contains('observance');

          // Clean display name
          String displayName = rawName.isNotEmpty ? rawName : rawAccount;
          if (displayName.contains('@') && !displayName.toLowerCase().contains('holiday')) {
            displayName = 'Personal Calendar (${displayName.split('@').first})';
          } else if (isHoliday && !displayName.toLowerCase().contains('holiday') && !displayName.toLowerCase().contains('festival')) {
            displayName = 'Holidays & Observances';
          }

          // Deduplicate identical calendar names
          final dedupeKey = '${displayName.toLowerCase()}_${rawAccount.toLowerCase()}';
          if (seenKeys.contains(dedupeKey)) continue;
          seenKeys.add(dedupeKey);

          results.add(UserCalendarInfo(
            id: cal.id ?? '',
            name: displayName,
            description: rawAccount.isNotEmpty ? rawAccount : null,
            isPrimary: cal.isDefault ?? false,
            isHolidayCalendar: isHoliday,
            backgroundColor: cal.color?.toString(),
            isSelected: true,
          ));
        }
      }

      // Sort: Primary first, then Holidays, then others
      results.sort((a, b) {
        if (a.isPrimary && !b.isPrimary) return -1;
        if (!a.isPrimary && b.isPrimary) return 1;
        if (a.isHolidayCalendar && !b.isHolidayCalendar) return -1;
        if (!a.isHolidayCalendar && b.isHolidayCalendar) return 1;
        return a.name.compareTo(b.name);
      });

      return results;
    } catch (_) {
      return [];
    }
  }

  /// Retrieve the holiday calendar ID
  Future<String> resolveHolidayCalendarId({String countryCode = 'indian'}) async {
    final cals = await getUserCalendars();
    final holidayCal = cals.where((c) => c.isHolidayCalendar).firstOrNull;
    return holidayCal?.id ?? '';
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
    final start = startDate ?? now.subtract(const Duration(days: 60));
    final end = endDate ?? now.add(const Duration(days: 365));
    
    final allEvents = <CalendarEvent>[];
    final seenKeys = <String>{};
    
    for (final cal in calendars.where((c) => c.isSelected && c.id.isNotEmpty)) {
      try {
        final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
          cal.id,
          RetrieveEventsParams(startDate: start, endDate: end),
        );
        
        if (eventsResult.isSuccess && eventsResult.data != null) {
          for (final event in eventsResult.data!) {
            final title = event.title ?? 'Event';
            final lowerTitle = title.toLowerCase();
            
            final isKnownHolidayName = lowerTitle.contains('holiday') ||
                lowerTitle.contains('festival') ||
                lowerTitle.contains('observance') ||
                lowerTitle.contains('diwali') ||
                lowerTitle.contains('deepavali') ||
                lowerTitle.contains('pongal') ||
                lowerTitle.contains('sankranti') ||
                lowerTitle.contains('makar sankranti') ||
                lowerTitle.contains('christmas') ||
                lowerTitle.contains('eid') ||
                lowerTitle.contains('ramzan') ||
                lowerTitle.contains('independence day') ||
                lowerTitle.contains('republic day') ||
                lowerTitle.contains('gandhi') ||
                lowerTitle.contains('new year') ||
                lowerTitle.contains('good friday') ||
                lowerTitle.contains('easter') ||
                lowerTitle.contains('muharram') ||
                lowerTitle.contains('dussehra') ||
                lowerTitle.contains('dasara') ||
                lowerTitle.contains('durga puja') ||
                lowerTitle.contains('navratri') ||
                lowerTitle.contains('holi') ||
                lowerTitle.contains('ganesh') ||
                lowerTitle.contains('vinayaka') ||
                lowerTitle.contains('ugadi') ||
                lowerTitle.contains('gudi padwa') ||
                lowerTitle.contains('onam') ||
                lowerTitle.contains('raksha bandhan') ||
                lowerTitle.contains('janmashtami') ||
                lowerTitle.contains('bakrid') ||
                lowerTitle.contains('shivaratri') ||
                lowerTitle.contains('mahashivratri') ||
                lowerTitle.contains('maha shivaratri') ||
                lowerTitle.contains('guru nanak') ||
                lowerTitle.contains('buddha purnima') ||
                lowerTitle.contains('ambedkar') ||
                lowerTitle.contains('mahavir') ||
                lowerTitle.contains('ayudha puja') ||
                lowerTitle.contains('kannada rajyotsava') ||
                lowerTitle.contains('telangana formation') ||
                lowerTitle.contains('andhra pradesh formation') ||
                lowerTitle.contains('day off') ||
                lowerTitle.contains('jayanti');

            final isHoliday = cal.isHolidayCalendar ||
                (event.allDay == true && isKnownHolidayName) ||
                isKnownHolidayName;
                
            final resolvedType = isHoliday
                ? (lowerTitle.contains('festival') ||
                        lowerTitle.contains('puja') ||
                        lowerTitle.contains('diwali') ||
                        lowerTitle.contains('pongal') ||
                        lowerTitle.contains('holi')
                    ? 'festival'
                    : 'holiday')
                : 'personal';
                    
            final eventId = event.eventId ??
                '${cal.id}_${event.title}_${event.start?.millisecondsSinceEpoch}';
            final dedupeKey = '${cal.id}_$eventId';
            if (!seenKeys.contains(dedupeKey)) {
              seenKeys.add(dedupeKey);
              
              final sDate = event.start != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      event.start!.millisecondsSinceEpoch,
                    )
                  : start;
              final eDate = event.end != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      event.end!.millisecondsSinceEpoch,
                    )
                  : (event.allDay == true
                      ? sDate.add(const Duration(days: 1))
                      : sDate.add(const Duration(hours: 1)));

              allEvents.add(CalendarEvent(
                id: eventId,
                calendarId: cal.id,
                calendarName: cal.name,
                title: title,
                description: event.description,
                startDateTime: sDate,
                endDateTime: eDate,
                isAllDay: event.allDay ?? isHoliday,
                location: event.location,
                source: cal.name,
                eventType: resolvedType,
              ));
            }
          }
        }
      } catch (_) {}
    }
    
    allEvents.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return allEvents;
  }
}
