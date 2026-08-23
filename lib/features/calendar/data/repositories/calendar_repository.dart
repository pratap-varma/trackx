import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/services/device_calendar_service.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/calendar/domain/models/calendar_event_model.dart';
import 'package:trackx/features/calendar/domain/models/calendar_holiday_model.dart';

class CalendarRepository extends StateNotifier<List<CalendarEvent>> {
  static const String _keyEvents = 'google_calendar_events_list';
  static const String _keyCalendars = 'google_calendar_user_calendars_list';
  static const String _keyConnected = 'google_calendar_connected_status';
  static const String _keyRegion = 'google_calendar_holiday_region';
  static const String _keyLastSync = 'google_calendar_last_sync_timestamp';
  static const String _keyIgnoredHolidays = 'google_calendar_ignored_holiday_dates';
  static const String _keyCustomHolidays = 'google_calendar_custom_holiday_dates';
  static const String _keyDayOfWeekOverrides = 'google_calendar_day_of_week_overrides';

  final SharedPreferences _prefs;
  final DeviceCalendarService _calendarService;
  final Ref? _ref;

  List<UserCalendarInfo> _availableCalendars = [];
  Set<String> _ignoredHolidays = {};
  Set<String> _customHolidays = {};
  Map<String, int> _dayOfWeekOverrides = {};
  DateTime? _lastSyncTime;
  bool _isRefreshing = false;

  CalendarRepository(this._prefs, this._calendarService, [this._ref])
    : super([]) {
    _init();
  }

  List<UserCalendarInfo> get availableCalendars => _availableCalendars;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isRefreshing => _isRefreshing;

  String get _currentUserId =>
      _ref?.read(authRepositoryProvider).userProfile?.id ?? '';

  String _getKey(String base) {
    final uid = _currentUserId;
    if (uid.isEmpty) return base;
    return '${uid}_$base';
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _init() {
    _load();
  }

  void _load() {
    final key = _getKey(_keyEvents);
    final raw = _prefs.getString(key);
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        state = decoded
            .map(
              (item) =>
                  CalendarEvent.fromMap(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } catch (_) {
        state = [];
      }
    } else {
      state = [];
    }

    final calsKey = _getKey(_keyCalendars);
    final calsRaw = _prefs.getString(calsKey);
    if (calsRaw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(calsRaw);
        _availableCalendars = decoded
            .map(
              (item) => UserCalendarInfo.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      } catch (_) {
        _availableCalendars = [];
      }
    } else {
      _availableCalendars = [];
    }

    final ignoredList = _prefs.getStringList(_getKey(_keyIgnoredHolidays));
    _ignoredHolidays = (ignoredList ?? []).toSet();

    final customList = _prefs.getStringList(_getKey(_keyCustomHolidays));
    _customHolidays = (customList ?? []).toSet();

    final overridesStr = _prefs.getString(_getKey(_keyDayOfWeekOverrides));
    if (overridesStr != null) {
      try {
        final decoded = jsonDecode(overridesStr) as Map<String, dynamic>;
        _dayOfWeekOverrides = decoded.map((k, v) => MapEntry(k, v as int));
      } catch (_) {
        _dayOfWeekOverrides = {};
      }
    } else {
      _dayOfWeekOverrides = {};
    }

    final syncKey = _getKey(_keyLastSync);
    final syncMillis = _prefs.getInt(syncKey);
    if (syncMillis != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(syncMillis);
    }
  }

  Future<void> _save() async {
    final key = _getKey(_keyEvents);
    final jsonStr = jsonEncode(state.map((e) => e.toMap()).toList());
    await _prefs.setString(key, jsonStr);

    final calsKey = _getKey(_keyCalendars);
    final calsJsonStr = jsonEncode(
      _availableCalendars.map((c) => c.toMap()).toList(),
    );
    await _prefs.setString(calsKey, calsJsonStr);

    await _prefs.setStringList(
      _getKey(_keyIgnoredHolidays),
      _ignoredHolidays.toList(),
    );
    await _prefs.setStringList(
      _getKey(_keyCustomHolidays),
      _customHolidays.toList(),
    );
    await _prefs.setString(
      _getKey(_keyDayOfWeekOverrides),
      jsonEncode(_dayOfWeekOverrides),
    );

    if (_lastSyncTime != null) {
      final syncKey = _getKey(_keyLastSync);
      await _prefs.setInt(syncKey, _lastSyncTime!.millisecondsSinceEpoch);
    }
  }

  bool isConnected() {
    final key = _getKey(_keyConnected);
    return _prefs.getBool(key) ?? false;
  }

  String getRegion() {
    final key = _getKey(_keyRegion);
    return _prefs.getString(key) ?? 'indian';
  }

  Future<void> setRegion(String region) async {
    final key = _getKey(_keyRegion);
    await _prefs.setString(key, region);
    if (isConnected()) {
      await refreshEvents();
    }
  }

  /// Toggle calendar active selection
  Future<void> toggleCalendarSelection(String calendarId) async {
    _availableCalendars = _availableCalendars.map((c) {
      if (c.id == calendarId) {
        return c.copyWith(isSelected: !c.isSelected);
      }
      return c;
    }).toList();

    await _save();
    if (isConnected()) {
      await refreshEvents();
    }
  }

  /// Connect Device Calendar and fetch real public holidays & personal events
  Future<bool> connectAndSync({String? countryCode}) async {
    try {
      final region = countryCode ?? getRegion();
      final granted = await _calendarService.requestCalendarAccess();
      if (!granted) {
        return false;
      }

      // Fetch user's calendars list with graceful fallback
      List<UserCalendarInfo> userCalendars = [];
      try {
        userCalendars = await _calendarService.getUserCalendars();
      } catch (_) {}

      // Ensure holiday calendar is resolved and included
      String holidayCalId = 'en.$region#holiday@group.v.calendar.google.com';
      try {
        holidayCalId = await _calendarService.resolveHolidayCalendarId(
          countryCode: region,
        );
      } catch (_) {}

      final hasHolidayCal = userCalendars.any((c) => c.id == holidayCalId);
      final combinedCalendars = List<UserCalendarInfo>.from(userCalendars);
      if (!hasHolidayCal) {
        combinedCalendars.add(
          UserCalendarInfo(
            id: holidayCalId,
            name: region == 'indian' ? 'Holidays in India' : 'Public Holidays',
            isHolidayCalendar: true,
            isSelected: true,
          ),
        );
      }

      _availableCalendars = combinedCalendars;

      // Fetch events from all selected calendars
      List<CalendarEvent> events = [];
      try {
        events = await _calendarService.fetchMultipleCalendarEvents(
          calendars: _availableCalendars,
        );
      } catch (_) {}

      state = events;
      _lastSyncTime = DateTime.now();
      await _save();

      final connKey = _getKey(_keyConnected);
      await _prefs.setBool(connKey, true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Disconnect Device Calendar and clear local cached events & settings
  Future<void> disconnect() async {
    try {
      await _calendarService.disconnect();
    } catch (_) {}

    state = [];
    _availableCalendars = [];
    _lastSyncTime = null;

    final key = _getKey(_keyEvents);
    final calsKey = _getKey(_keyCalendars);
    final connKey = _getKey(_keyConnected);
    final syncKey = _getKey(_keyLastSync);

    await _prefs.remove(key);
    await _prefs.remove(calsKey);
    await _prefs.remove(syncKey);
    await _prefs.setBool(connKey, false);
  }

  /// Refresh calendar events in background
  Future<bool> refreshEvents() async {
    if (!isConnected() || _isRefreshing) return false;
    _isRefreshing = true;

    try {
      if (_availableCalendars.isEmpty) {
        final region = getRegion();
        final holidayCalId = await _calendarService.resolveHolidayCalendarId(
          countryCode: region,
        );
        _availableCalendars = [
          UserCalendarInfo(
            id: holidayCalId,
            name: region == 'indian' ? 'Holidays in India' : 'Public Holidays',
            isHolidayCalendar: true,
            isSelected: true,
          ),
        ];
      }

      final events = await _calendarService.fetchMultipleCalendarEvents(
        calendars: _availableCalendars,
      );

      if (events.isNotEmpty) {
        state = events;
      }
      _lastSyncTime = DateTime.now();
      await _save();
      _isRefreshing = false;
      return true;
    } catch (_) {
      _isRefreshing = false;
      return false;
    }
  }

  /// Backward compatible refresh for holidays
  Future<bool> refreshHolidays() async {
    return refreshEvents();
  }

  /// Get events active on a given date
  List<CalendarEvent> getEventsForDate(DateTime date) {
    return state.where((h) => h.occursOn(date)).toList();
  }

  /// Get holiday & festival events active on a given date
  List<CalendarEvent> getHolidaysForDate(DateTime date) {
    return state
        .where((h) => h.occursOn(date) && h.isHolidayOrFestival)
        .toList();
  }

  /// Get personal/work calendar events active on a given date
  List<CalendarEvent> getPersonalEventsForDate(DateTime date) {
    return state
        .where((h) => h.occursOn(date) && !h.isHolidayOrFestival)
        .toList();
  }

  /// Check if date has a holiday (incorporating user toggle overrides)
  bool isHoliday(DateTime date) {
    return isDateEffectiveHoliday(date);
  }

  /// Check if a date is treated as an effective holiday (accounting for manual overrides)
  bool isDateEffectiveHoliday(DateTime date) {
    final k = _dateKey(date);
    if (_ignoredHolidays.contains(k)) return false;
    if (_customHolidays.contains(k)) return true;

    // Sundays are always holidays by default
    if (date.weekday == DateTime.sunday) return true;

    // Saturdays are holidays by default (with exception toggle for working Saturdays)
    if (date.weekday == DateTime.saturday) return true;

    return state.any((h) => h.occursOn(date) && h.isHolidayOrFestival);
  }

  /// Check if a date has been manually overridden by the user
  bool isHolidayOverriddenToWorking(DateTime date) =>
      _ignoredHolidays.contains(_dateKey(date));

  bool isCustomHolidayDeclared(DateTime date) =>
      _customHolidays.contains(_dateKey(date));

  /// Get effective holidays for a date accounting for manual overrides
  List<CalendarEvent> getEffectiveHolidaysForDate(DateTime date) {
    final k = _dateKey(date);
    if (_ignoredHolidays.contains(k)) return [];

    final fromCalendar = state
        .where((h) => h.occursOn(date) && h.isHolidayOrFestival)
        .toList();

    if (fromCalendar.isNotEmpty) return fromCalendar;

    if (_customHolidays.contains(k)) {
      return [
        CalendarEvent(
          id: 'custom_$k',
          calendarId: 'custom_college',
          calendarName: 'College Declared Holiday',
          title: 'College Declared Holiday',
          description: 'Marked as non-working holiday by student',
          startDateTime: DateTime(date.year, date.month, date.day),
          endDateTime: DateTime(date.year, date.month, date.day, 23, 59, 59),
          isAllDay: true,
          source: 'College Schedule',
          eventType: 'holiday',
        ),
      ];
    }

    if (date.weekday == DateTime.sunday) {
      return [
        CalendarEvent(
          id: 'sunday_$k',
          calendarId: 'weekend_sunday',
          calendarName: 'Sunday Holiday',
          title: 'Sunday Holiday (College Closed)',
          description:
              'Weekly Sunday holiday. Toggle below if college has a special class.',
          startDateTime: DateTime(date.year, date.month, date.day),
          endDateTime: DateTime(date.year, date.month, date.day, 23, 59, 59),
          isAllDay: true,
          source: 'Weekly College Schedule',
          eventType: 'holiday',
        ),
      ];
    }

    if (date.weekday == DateTime.saturday) {
      return [
        CalendarEvent(
          id: 'saturday_$k',
          calendarId: 'weekend_saturday',
          calendarName: 'Saturday Holiday',
          title: 'Saturday Holiday (Weekend Off)',
          description:
              'Default Saturday holiday. Toggle below if college is open today.',
          startDateTime: DateTime(date.year, date.month, date.day),
          endDateTime: DateTime(date.year, date.month, date.day, 23, 59, 59),
          isAllDay: true,
          source: 'Weekly College Schedule',
          eventType: 'holiday',
        ),
      ];
    }

    return [];
  }

  /// Toggle holiday status for a specific date (Working Day <-> Holiday)
  Future<bool> toggleHolidayForDate(DateTime date) async {
    final k = _dateKey(date);
    final currentlyHoliday = isDateEffectiveHoliday(date);

    if (currentlyHoliday) {
      // Switch from Holiday -> Working day
      _ignoredHolidays.add(k);
      _customHolidays.remove(k);
    } else {
      // Switch from Working day -> Holiday
      _customHolidays.add(k);
      _ignoredHolidays.remove(k);
    }

    await _save();
    state = List<CalendarEvent>.from(state);
    return !currentlyHoliday;
  }

  /// Reset manual override for a specific date
  Future<void> resetHolidayOverride(DateTime date) async {
    final k = _dateKey(date);
    _ignoredHolidays.remove(k);
    _customHolidays.remove(k);
    await _save();
    state = List<CalendarEvent>.from(state);
  }

  /// Direct state updates for testing
  void setEvents(List<CalendarEvent> events) {
    state = events;
    _save();
  }

  /// Backward compatibility for tests
  void setHolidays(List<CalendarHoliday> holidays) {
    state = holidays.map((h) => h.toCalendarEvent()).toList();
    _save();
  }

  int? getDayOfWeekOverride(DateTime date) {
    return _dayOfWeekOverrides[_dateKey(date)];
  }

  Future<void> setDayOfWeekOverride(DateTime date, int dayOfWeek) async {
    _dayOfWeekOverrides[_dateKey(date)] = dayOfWeek;
    await _save();
    // Trigger state change so listeners update
    state = List<CalendarEvent>.from(state);
  }
}
