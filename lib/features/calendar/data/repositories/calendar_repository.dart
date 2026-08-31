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

  List<CalendarEvent> _mergeWithStandardHolidays(List<CalendarEvent> baseEvents) {
    final merged = <CalendarEvent>[...baseEvents];
    final seenDateTitles = <String>{};

    for (final ev in merged) {
      final k = '${_dateKey(ev.startDateTime)}_${ev.title.toLowerCase().trim()}';
      seenDateTitles.add(k);
    }

    for (final std in _getStandardAcademicHolidays()) {
      final k = '${_dateKey(std.startDateTime)}_${std.title.toLowerCase().trim()}';
      if (!seenDateTitles.contains(k)) {
        seenDateTitles.add(k);
        merged.add(std);
      }
    }

    merged.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return merged;
  }

  void _load() {
    final key = _getKey(_keyEvents);
    final raw = _prefs.getString(key);
    List<CalendarEvent> loaded = [];
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        loaded = decoded
            .map(
              (item) =>
                  CalendarEvent.fromMap(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } catch (_) {
        loaded = [];
      }
    }

    state = _mergeWithStandardHolidays(loaded);

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
      final granted = await _calendarService.requestCalendarAccess();
      if (!granted) {
        return false;
      }

      // Fetch user's calendars list with graceful fallback
      List<UserCalendarInfo> userCalendars = [];
      try {
        userCalendars = await _calendarService.getUserCalendars();
      } catch (_) {}

      _availableCalendars = userCalendars;

      // Fetch events from all selected calendars
      List<CalendarEvent> events = [];
      try {
        if (_availableCalendars.isNotEmpty) {
          events = await _calendarService.fetchMultipleCalendarEvents(
            calendars: _availableCalendars,
          );
        }
      } catch (_) {}

      state = _mergeWithStandardHolidays(events);
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

    state = _getStandardAcademicHolidays();
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
        _availableCalendars = await _calendarService.getUserCalendars();
      }

      List<CalendarEvent> events = [];
      if (_availableCalendars.isNotEmpty) {
        events = await _calendarService.fetchMultipleCalendarEvents(
          calendars: _availableCalendars,
        );
      }

      state = _mergeWithStandardHolidays(events);
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

  Future<void> resetDayOfWeekOverride(DateTime date) async {
    _dayOfWeekOverrides.remove(_dateKey(date));
    await _save();
    state = List<CalendarEvent>.from(state);
  }

  static List<CalendarEvent> _getStandardAcademicHolidays() {
    final list = <CalendarEvent>[];
    for (final year in [2025, 2026, 2027, 2028]) {
      list.addAll([
        CalendarEvent(
          id: 'holiday_new_year_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: "New Year's Day",
          description: "Public & Academic Holiday",
          startDateTime: DateTime(year, 1, 1),
          endDateTime: DateTime(year, 1, 1, 23, 59, 59),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'holiday',
        ),
        CalendarEvent(
          id: 'holiday_pongal_sankranti_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Makar Sankranti / Pongal',
          description: 'Harvest Festival & Public Holiday',
          startDateTime: DateTime(year, 1, 14),
          endDateTime: DateTime(year, 1, 15, 23, 59, 59),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'festival',
        ),
        CalendarEvent(
          id: 'holiday_republic_day_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Republic Day',
          description: 'National Holiday',
          startDateTime: DateTime(year, 1, 26),
          endDateTime: DateTime(year, 1, 26, 23, 59, 59),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'holiday',
        ),
        CalendarEvent(
          id: 'holiday_maha_shivaratri_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Maha Shivaratri',
          description: 'Religious & Academic Holiday',
          startDateTime: DateTime(
            year,
            year == 2025 ? 2 : (year == 2026 ? 2 : 3),
            year == 2025 ? 26 : (year == 2026 ? 15 : 6),
          ),
          endDateTime: DateTime(
            year,
            year == 2025 ? 2 : (year == 2026 ? 2 : 3),
            year == 2025 ? 26 : (year == 2026 ? 15 : 6),
            23,
            59,
            59,
          ),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'festival',
        ),
        CalendarEvent(
          id: 'holiday_holi_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Holi',
          description: 'Festival of Colors',
          startDateTime: DateTime(
            year,
            3,
            year == 2025 ? 14 : (year == 2026 ? 3 : 22),
          ),
          endDateTime: DateTime(
            year,
            3,
            year == 2025 ? 14 : (year == 2026 ? 3 : 22),
            23,
            59,
            59,
          ),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'festival',
        ),
        CalendarEvent(
          id: 'holiday_good_friday_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Good Friday',
          description: 'Christian Holiday',
          startDateTime: DateTime(
            year,
            year == 2025 ? 4 : (year == 2026 ? 4 : 3),
            year == 2025 ? 18 : (year == 2026 ? 3 : 26),
          ),
          endDateTime: DateTime(
            year,
            year == 2025 ? 4 : (year == 2026 ? 4 : 3),
            year == 2025 ? 18 : (year == 2026 ? 3 : 26),
            23,
            59,
            59,
          ),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'holiday',
        ),
        CalendarEvent(
          id: 'holiday_ugadi_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Ugadi / Gudi Padwa',
          description: 'New Year Festival',
          startDateTime: DateTime(
            year,
            3,
            year == 2025 ? 30 : (year == 2026 ? 19 : 8),
          ),
          endDateTime: DateTime(
            year,
            3,
            year == 2025 ? 30 : (year == 2026 ? 19 : 8),
            23,
            59,
            59,
          ),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'festival',
        ),
        CalendarEvent(
          id: 'holiday_eid_al_fitr_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Eid al-Fitr (Ramzan Eid)',
          description: 'Islamic Holiday',
          startDateTime: DateTime(
            year,
            3,
            year == 2025 ? 31 : (year == 2026 ? 20 : 10),
          ),
          endDateTime: DateTime(
            year,
            3,
            year == 2025 ? 31 : (year == 2026 ? 20 : 10),
            23,
            59,
            59,
          ),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'festival',
        ),
        CalendarEvent(
          id: 'holiday_ambedkar_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Dr. B.R. Ambedkar Jayanti',
          description: 'Public & Academic Holiday',
          startDateTime: DateTime(year, 4, 14),
          endDateTime: DateTime(year, 4, 14, 23, 59, 59),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'holiday',
        ),
        CalendarEvent(
          id: 'holiday_may_day_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: "May Day / Workers' Day",
          description: 'Public Holiday',
          startDateTime: DateTime(year, 5, 1),
          endDateTime: DateTime(year, 5, 1, 23, 59, 59),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'holiday',
        ),
        CalendarEvent(
          id: 'holiday_eid_al_adha_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Bakrid / Eid al-Adha',
          description: 'Islamic Holiday',
          startDateTime: DateTime(
            year,
            6,
            year == 2025 ? 7 : (year == 2026 ? 27 : 17),
          ),
          endDateTime: DateTime(
            year,
            6,
            year == 2025 ? 7 : (year == 2026 ? 27 : 17),
            23,
            59,
            59,
          ),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'festival',
        ),
        CalendarEvent(
          id: 'holiday_muharram_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Muharram',
          description: 'Islamic Observance',
          startDateTime: DateTime(
            year,
            7,
            year == 2025 ? 6 : (year == 2026 ? 26 : 16),
          ),
          endDateTime: DateTime(
            year,
            7,
            year == 2025 ? 6 : (year == 2026 ? 26 : 16),
            23,
            59,
            59,
          ),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'holiday',
        ),
        CalendarEvent(
          id: 'holiday_independence_day_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Independence Day',
          description: 'National Holiday',
          startDateTime: DateTime(year, 8, 15),
          endDateTime: DateTime(year, 8, 15, 23, 59, 59),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'holiday',
        ),
        CalendarEvent(
          id: 'holiday_ganesh_chaturthi_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Ganesh Chaturthi / Vinayaka Chavithi',
          description: 'Festival & Academic Holiday',
          startDateTime: DateTime(
            year,
            year == 2025 ? 8 : (year == 2026 ? 9 : 9),
            year == 2025 ? 27 : (year == 2026 ? 14 : 4),
          ),
          endDateTime: DateTime(
            year,
            year == 2025 ? 8 : (year == 2026 ? 9 : 9),
            year == 2025 ? 27 : (year == 2026 ? 14 : 4),
            23,
            59,
            59,
          ),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'festival',
        ),
        CalendarEvent(
          id: 'holiday_gandhi_jayanti_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Mahatma Gandhi Jayanti',
          description: 'National Holiday',
          startDateTime: DateTime(year, 10, 2),
          endDateTime: DateTime(year, 10, 2, 23, 59, 59),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'holiday',
        ),
        CalendarEvent(
          id: 'holiday_dussehra_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Dussehra / Vijayadashami',
          description: 'Festival & Academic Holiday',
          startDateTime: DateTime(
            year,
            10,
            year == 2025 ? 2 : (year == 2026 ? 20 : 10),
          ),
          endDateTime: DateTime(
            year,
            10,
            year == 2025 ? 2 : (year == 2026 ? 20 : 10),
            23,
            59,
            59,
          ),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'festival',
        ),
        CalendarEvent(
          id: 'holiday_diwali_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Diwali / Deepavali',
          description: 'Festival of Lights & Public Holiday',
          startDateTime: DateTime(
            year,
            year == 2025 ? 10 : (year == 2026 ? 11 : 10),
            year == 2025 ? 20 : (year == 2026 ? 8 : 29),
          ),
          endDateTime: DateTime(
            year,
            year == 2025 ? 10 : (year == 2026 ? 11 : 10),
            year == 2025 ? 20 : (year == 2026 ? 8 : 29),
            23,
            59,
            59,
          ),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'festival',
        ),
        CalendarEvent(
          id: 'holiday_guru_nanak_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Guru Nanak Jayanti',
          description: 'Religious & Academic Holiday',
          startDateTime: DateTime(
            year,
            11,
            year == 2025 ? 5 : (year == 2026 ? 24 : 14),
          ),
          endDateTime: DateTime(
            year,
            11,
            year == 2025 ? 5 : (year == 2026 ? 24 : 14),
            23,
            59,
            59,
          ),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'festival',
        ),
        CalendarEvent(
          id: 'holiday_christmas_$year',
          calendarId: 'public_holidays',
          calendarName: 'Public Holidays',
          title: 'Christmas Day',
          description: 'Christian & Public Holiday',
          startDateTime: DateTime(year, 12, 25),
          endDateTime: DateTime(year, 12, 25, 23, 59, 59),
          isAllDay: true,
          source: 'Public Calendar',
          eventType: 'holiday',
        ),
      ]);
    }
    return list;
  }
}
