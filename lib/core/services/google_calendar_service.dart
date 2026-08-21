import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:trackx/features/calendar/domain/models/calendar_event_model.dart';
import 'package:trackx/features/calendar/domain/models/calendar_holiday_model.dart';

class GoogleCalendarService {
  static const String calendarReadOnlyScope =
      'https://www.googleapis.com/auth/calendar.events.readonly';
  static const String defaultIndiaHolidayCalendarId =
      'en.indian#holiday@group.v.calendar.google.com';

  final GoogleSignIn _googleSignIn;
  final http.Client _client;

  GoogleCalendarService({GoogleSignIn? googleSignIn, http.Client? client})
    : _googleSignIn =
          googleSignIn ?? GoogleSignIn(scopes: [calendarReadOnlyScope]),
      _client = client ?? http.Client();

  /// Request Google Calendar read-only permissions and ensure user is signed in
  Future<GoogleSignInAccount?> requestCalendarAccess() async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account != null) {
        try {
          final hasScope = await _googleSignIn.canAccessScopes([
            calendarReadOnlyScope,
          ]);
          if (!hasScope) {
            await _googleSignIn.requestScopes([calendarReadOnlyScope]);
          }
        } catch (_) {
          // If canAccessScopes is not supported on this platform version, continue with account
        }
      }
      return account;
    } catch (_) {
      return null;
    }
  }

  /// Check if calendar scope is currently granted
  Future<bool> hasCalendarAccess() async {
    try {
      final account =
          _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      if (account == null) return false;
      return await _googleSignIn.canAccessScopes([calendarReadOnlyScope]);
    } catch (_) {
      return false;
    }
  }

  /// Disconnect / Sign out from calendar
  Future<void> disconnect() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Retrieve the user's available Google Calendars
  Future<List<UserCalendarInfo>> getUserCalendars({
    String? accessTokenOverride,
  }) async {
    try {
      final token = accessTokenOverride ?? await _getValidAccessToken();
      if (token == null) {
        return [];
      }

      final uri = Uri.parse(
        'https://www.googleapis.com/calendar/v3/users/me/calendarList',
      );
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];
        final results = <UserCalendarInfo>[];

        for (final item in items) {
          final id = item['id']?.toString() ?? '';
          final summary = item['summary']?.toString() ?? 'Calendar';
          final description = item['description']?.toString();
          final isPrimary = item['primary'] == true;
          final isHoliday =
              id.contains('holiday') ||
              summary.toLowerCase().contains('holiday') ||
              summary.toLowerCase().contains('festival');
          final bg = item['backgroundColor']?.toString();

          results.add(
            UserCalendarInfo(
              id: id,
              name: summary,
              description: description,
              isPrimary: isPrimary,
              isHolidayCalendar: isHoliday,
              backgroundColor: bg,
              isSelected: true,
            ),
          );
        }
        return results;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Retrieve the holiday calendar ID from the user's Google Calendar list or fallback to India holiday calendar
  Future<String> resolveHolidayCalendarId({
    String countryCode = 'indian',
    String? accessTokenOverride,
  }) async {
    try {
      final token = accessTokenOverride ?? await _getValidAccessToken();
      if (token == null) {
        return 'en.$countryCode#holiday@group.v.calendar.google.com';
      }

      final uri = Uri.parse(
        'https://www.googleapis.com/calendar/v3/users/me/calendarList',
      );
      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final id = item['id']?.toString() ?? '';
          final summary = item['summary']?.toString().toLowerCase() ?? '';
          if (id.contains('holiday') ||
              summary.contains('holiday') ||
              summary.contains('festival')) {
            if (id.contains(countryCode)) {
              return id;
            }
          }
        }
      }
    } catch (_) {}
    return 'en.$countryCode#holiday@group.v.calendar.google.com';
  }

  /// Fetch events for a specific calendar
  Future<List<CalendarEvent>> fetchCalendarEvents({
    required String calendarId,
    required String calendarName,
    DateTime? startDate,
    DateTime? endDate,
    String? accessTokenOverride,
    String? eventTypeOverride,
  }) async {
    final now = DateTime.now();
    final timeMin = (startDate ?? now.subtract(const Duration(days: 7)))
        .toUtc()
        .toIso8601String();
    final timeMax = (endDate ?? now.add(const Duration(days: 365)))
        .toUtc()
        .toIso8601String();

    final encodedCalendarId = Uri.encodeComponent(calendarId);

    try {
      final token = accessTokenOverride ?? await _getValidAccessToken();
      if (token == null) {
        return [];
      }

      final url =
          'https://www.googleapis.com/calendar/v3/calendars/$encodedCalendarId/events?'
          'timeMin=$timeMin&timeMax=$timeMax&singleEvents=true&orderBy=startTime';

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];
        final isHolidayCal =
            calendarId.contains('holiday') ||
            calendarName.toLowerCase().contains('holiday') ||
            calendarName.toLowerCase().contains('festival');

        return items.map((item) {
          final id = item['id']?.toString() ?? '';
          final summary = item['summary']?.toString() ?? 'Calendar Event';
          final description = item['description']?.toString();
          final location = item['location']?.toString();

          final startMap = item['start'] as Map<String, dynamic>? ?? {};
          final endMap = item['end'] as Map<String, dynamic>? ?? {};

          final isAllDay = startMap.containsKey('date');
          final startStr = startMap['date'] ?? startMap['dateTime'];
          final endStr = endMap['date'] ?? endMap['dateTime'];

          final parsedStart =
              DateTime.tryParse(startStr?.toString() ?? '')?.toLocal() ??
              DateTime.now();
          final parsedEnd =
              DateTime.tryParse(endStr?.toString() ?? '')?.toLocal() ??
              parsedStart;

          final resolvedType =
              eventTypeOverride ??
              (isHolidayCal
                  ? (summary.toLowerCase().contains('festival')
                        ? 'festival'
                        : 'holiday')
                  : 'personal');

          return CalendarEvent(
            id: id,
            calendarId: calendarId,
            calendarName: calendarName,
            title: summary,
            description: description,
            startDateTime: parsedStart,
            endDateTime: parsedEnd,
            isAllDay: isAllDay,
            location: location,
            source: 'Google Calendar',
            eventType: resolvedType,
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Backward compatible helper for holidays
  Future<List<CalendarHoliday>> fetchHolidays({
    String? calendarId,
    DateTime? startDate,
    DateTime? endDate,
    String? accessTokenOverride,
  }) async {
    final targetId = calendarId ?? defaultIndiaHolidayCalendarId;
    final events = await fetchCalendarEvents(
      calendarId: targetId,
      calendarName: 'Public Holidays',
      startDate: startDate,
      endDate: endDate,
      accessTokenOverride: accessTokenOverride,
      eventTypeOverride: 'holiday',
    );
    return events.map((e) => CalendarHoliday.fromCalendarEvent(e)).toList();
  }

  /// Fetch events from multiple selected calendars with deduplication
  Future<List<CalendarEvent>> fetchMultipleCalendarEvents({
    required List<UserCalendarInfo> calendars,
    DateTime? startDate,
    DateTime? endDate,
    String? accessTokenOverride,
  }) async {
    final allEvents = <CalendarEvent>[];
    final seenKeys = <String>{};

    for (final cal in calendars.where((c) => c.isSelected)) {
      final events = await fetchCalendarEvents(
        calendarId: cal.id,
        calendarName: cal.name,
        startDate: startDate,
        endDate: endDate,
        accessTokenOverride: accessTokenOverride,
      );

      for (final event in events) {
        final dedupeKey = '${event.calendarId}_${event.id}';
        if (!seenKeys.contains(dedupeKey)) {
          seenKeys.add(dedupeKey);
          allEvents.add(event);
        }
      }
    }

    allEvents.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return allEvents;
  }

  Future<String?> _getValidAccessToken() async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      if (account == null) return null;

      final auth = await account.authentication;
      return auth.accessToken;
    } catch (_) {
      return null;
    }
  }
}
