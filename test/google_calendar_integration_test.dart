import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/services/google_calendar_service.dart';
import 'package:trackx/features/calendar/data/repositories/calendar_repository.dart';
import 'package:trackx/features/calendar/domain/models/calendar_event_model.dart';
import 'package:trackx/features/calendar/domain/models/calendar_holiday_model.dart';
import 'package:trackx/features/calendar/presentation/widgets/calendar_event_details_sheet.dart';
import 'package:trackx/features/calendar/presentation/widgets/holiday_details_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Calendar Holidays & Personal Events Integration Tests', () {
    test('1. CalendarHoliday model converts to and from map correctly', () {
      final holiday = CalendarHoliday(
        id: 'hol_123',
        title: 'Festival of Lights',
        description: 'National public holiday celebration',
        startDate: DateTime(2026, 10, 20),
        endDate: DateTime(2026, 10, 21),
        isAllDay: true,
        calendarId: 'en.indian#holiday@group.v.calendar.google.com',
        source: 'Google Calendar',
        location: 'India',
      );

      final map = holiday.toMap();
      final recovered = CalendarHoliday.fromMap(map);

      expect(recovered.id, 'hol_123');
      expect(recovered.title, 'Festival of Lights');
      expect(recovered.description, 'National public holiday celebration');
      expect(recovered.isAllDay, true);
      expect(recovered.location, 'India');
      expect(recovered.occursOn(DateTime(2026, 10, 20)), isTrue);
      expect(recovered.occursOn(DateTime(2026, 10, 22)), isFalse);
    });

    test(
      '2. CalendarEvent model supports personal, all-day, and timed events',
      () {
        final personalEvent = CalendarEvent(
          id: 'event_meeting_1',
          calendarId: 'primary_cal',
          calendarName: 'Personal',
          title: 'Capstone Project Review',
          description: 'Review project milestones with mentor',
          startDateTime: DateTime(2026, 8, 20, 14, 30),
          endDateTime: DateTime(2026, 8, 20, 15, 30),
          isAllDay: false,
          location: 'Engineering Lab 402',
          source: 'Google Calendar',
          eventType: 'personal',
        );

        final map = personalEvent.toMap();
        final recovered = CalendarEvent.fromMap(map);

        expect(recovered.id, 'event_meeting_1');
        expect(recovered.calendarName, 'Personal');
        expect(recovered.title, 'Capstone Project Review');
        expect(recovered.isAllDay, isFalse);
        expect(recovered.isHolidayOrFestival, isFalse);
        expect(recovered.occursOn(DateTime(2026, 8, 20)), isTrue);
        expect(recovered.occursOn(DateTime(2026, 8, 21)), isFalse);
      },
    );

    test(
      '3. GoogleCalendarService fetches user calendars and parses personal events',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('/calendarList')) {
            final payload = {
              'items': [
                {
                  'id': 'user_primary@gmail.com',
                  'summary': 'Personal',
                  'primary': true,
                },
                {
                  'id': 'college_events@group.calendar.google.com',
                  'summary': 'College',
                  'primary': false,
                },
                {
                  'id': 'en.indian#holiday@group.v.calendar.google.com',
                  'summary': 'Holidays in India',
                  'primary': false,
                },
              ],
            };
            return http.Response(
              jsonEncode(payload),
              200,
              headers: {'content-type': 'application/json'},
            );
          } else if (request.url.path.contains('/events')) {
            final payload = {
              'items': [
                {
                  'id': 'gcal_event_1',
                  'summary': 'Machine Learning Lab Seminar',
                  'description': 'Guest lecture on Transformers',
                  'start': {'dateTime': '2026-08-20T10:00:00Z'},
                  'end': {'dateTime': '2026-08-20T11:30:00Z'},
                  'location': 'Auditorium B',
                },
              ],
            };
            return http.Response(
              jsonEncode(payload),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not found', 404);
        });

        final service = GoogleCalendarService(client: mockClient);
        final userCalendars = await service.getUserCalendars(
          accessTokenOverride: 'mock_token',
        );

        expect(userCalendars.length, 3);
        expect(userCalendars[0].name, 'Personal');
        expect(userCalendars[0].isPrimary, isTrue);
        expect(userCalendars[2].isHolidayCalendar, isTrue);

        final events = await service.fetchCalendarEvents(
          calendarId: 'user_primary@gmail.com',
          calendarName: 'Personal',
          accessTokenOverride: 'mock_token',
        );

        expect(events.length, 1);
        expect(events.first.title, 'Machine Learning Lab Seminar');
        expect(events.first.eventType, 'personal');
      },
    );

    test(
      '4. CalendarRepository manages multiple calendars, filters, and offline cache',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final mockClient = MockClient((request) async {
          final payload = {'items': []};
          return http.Response(jsonEncode(payload), 200);
        });

        final service = GoogleCalendarService(client: mockClient);
        final repo = CalendarRepository(prefs, service);

        expect(repo.isConnected(), isFalse);
        expect(repo.state.isEmpty, isTrue);

        final holiday = CalendarEvent(
          id: 'hol_rep_day',
          calendarId: 'cal_holidays',
          calendarName: 'Holidays in India',
          title: 'Republic Day',
          startDateTime: DateTime(2026, 1, 26),
          endDateTime: DateTime(2026, 1, 27),
          isAllDay: true,
          source: 'Google Calendar',
          eventType: 'holiday',
        );

        final personalEvent = CalendarEvent(
          id: 'event_project_due',
          calendarId: 'cal_personal',
          calendarName: 'Personal',
          title: 'Project Submission',
          startDateTime: DateTime(2026, 1, 26, 17, 0),
          endDateTime: DateTime(2026, 1, 26, 18, 0),
          isAllDay: false,
          source: 'Google Calendar',
          eventType: 'personal',
        );

        repo.setEvents([holiday, personalEvent]);

        expect(repo.state.length, 2);
        expect(repo.isHoliday(DateTime(2026, 1, 26)), isTrue);
        expect(repo.getHolidaysForDate(DateTime(2026, 1, 26)).length, 1);
        expect(repo.getPersonalEventsForDate(DateTime(2026, 1, 26)).length, 1);

        await repo.disconnect();
        expect(repo.state.isEmpty, isTrue);
        expect(repo.isConnected(), isFalse);
      },
    );

    testWidgets(
      '5. CalendarEventDetailsSheet renders personal calendar event details in Glass modal',
      (tester) async {
        final personalEvent = CalendarEvent(
          id: 'p_event_test',
          calendarId: 'cal_college',
          calendarName: 'College',
          title: 'Workshop: Cloud Systems',
          description: 'Hands-on session with Docker and Kubernetes',
          startDateTime: DateTime(2026, 9, 10, 14, 0),
          endDateTime: DateTime(2026, 9, 10, 16, 0),
          isAllDay: false,
          source: 'Google Calendar',
          location: 'Computer Lab 3',
          eventType: 'personal',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () =>
                      CalendarEventDetailsSheet.show(ctx, personalEvent),
                  child: const Text('Open Event'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Event'));
        await tester.pumpAndSettle();

        expect(find.text('Workshop: Cloud Systems'), findsOneWidget);
        expect(
          find.text('Hands-on session with Docker and Kubernetes'),
          findsOneWidget,
        );
        expect(find.text('College'), findsOneWidget);
        expect(find.text('Computer Lab 3'), findsOneWidget);
        expect(find.text('Google Calendar Event'), findsOneWidget);
      },
    );

    testWidgets(
      '6. HolidayDetailsSheet renders holiday details in Glass modal',
      (tester) async {
        final holiday = CalendarHoliday(
          id: 'h_test',
          title: 'New Year Festival',
          description: 'Celebrated worldwide with festivities',
          startDate: DateTime(2027, 1, 1),
          endDate: DateTime(2027, 1, 2),
          isAllDay: true,
          calendarId: 'en.indian#holiday@group.v.calendar.google.com',
          source: 'Google Calendar',
          location: 'National',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => HolidayDetailsSheet.show(ctx, holiday),
                  child: const Text('Open Holiday'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Holiday'));
        await tester.pumpAndSettle();

        expect(find.text('New Year Festival'), findsOneWidget);
        expect(
          find.text('Celebrated worldwide with festivities'),
          findsOneWidget,
        );
        expect(find.text('Google Calendar'), findsOneWidget);
        expect(find.text('Public Holiday / Festival'), findsOneWidget);
      },
    );
  });
}
