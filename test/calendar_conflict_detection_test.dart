import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/features/calendar/domain/models/calendar_event_model.dart';
import 'package:trackx/features/planner/domain/models/calendar_conflict_model.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/planner/domain/services/calendar_conflict_service.dart';
import 'package:trackx/features/planner/presentation/widgets/calendar_conflict_details_sheet.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = CalendarConflictService();
  final testDate = DateTime(2026, 8, 20); // Thursday (weekday 4)

  final mockSubject1 = Subject(
    id: 'sub_ds',
    userId: 'u1',
    semesterId: 'sem1',
    name: 'Data Structures',
    code: 'CS201',
    facultyName: 'Dr. Smith',
    colorValue: 0xFF5B5FEF,
    type: 'Theory',
    targetAttendance: 75.0,
    presentClasses: 0,
    absentClasses: 0,
    status: 'Active',
    expectedDifficulty: 'Moderate',
    createdAt: 0,
    updatedAt: 0,
  );

  final mockSubject2 = Subject(
    id: 'sub_ml',
    userId: 'u1',
    semesterId: 'sem1',
    name: 'Machine Learning',
    code: 'CS401',
    facultyName: 'Dr. Turing',
    colorValue: 0xFF10B981,
    type: 'Theory',
    targetAttendance: 75.0,
    presentClasses: 0,
    absentClasses: 0,
    status: 'Active',
    expectedDifficulty: 'Challenging',
    createdAt: 0,
    updatedAt: 0,
  );

  final subjects = [mockSubject1, mockSubject2];

  group('Calendar Conflict Detection Engine Tests', () {
    test('1. No overlap between events at different times', () {
      final timetable = [
        TimetableEntry(
          id: 'entry_1',
          userId: 'u1',
          semesterId: 'sem1',
          subjectId: 'sub_ds',
          dayOfWeek: 4,
          periodNumber: 1,
          startTime: 9 * 60, // 9:00 AM
          endTime: 10 * 60, // 10:00 AM
          isEnabled: true,
          createdAt: 0,
          updatedAt: 0,
        ),
      ];

      final gcalEvents = [
        CalendarEvent(
          id: 'e1',
          calendarId: 'cal1',
          calendarName: 'Personal',
          title: 'Study Group',
          startDateTime: DateTime(2026, 8, 20, 14, 0), // 2:00 PM
          endDateTime: DateTime(2026, 8, 20, 15, 0), // 3:00 PM
          isAllDay: false,
          source: 'Google Calendar',
          eventType: 'personal',
        ),
      ];

      final conflicts = service.detectConflictsForDate(
        date: testDate,
        timetableEntries: timetable,
        subjects: subjects,
        tasks: [],
        calendarEvents: gcalEvents,
      );

      expect(conflicts.isEmpty, isTrue);
    });

    test(
      '2. Partial overlap: Google Calendar event overlaps college class',
      () {
        final timetable = [
          TimetableEntry(
            id: 'entry_1',
            userId: 'u1',
            semesterId: 'sem1',
            subjectId: 'sub_ds',
            dayOfWeek: 4,
            periodNumber: 1,
            startTime: 10 * 60, // 10:00 AM
            endTime: 11 * 60, // 11:00 AM
            isEnabled: true,
            createdAt: 0,
            updatedAt: 0,
          ),
        ];

        final gcalEvents = [
          CalendarEvent(
            id: 'e1',
            calendarId: 'cal1',
            calendarName: 'Personal',
            title: 'Project Meeting',
            startDateTime: DateTime(2026, 8, 20, 10, 30), // 10:30 AM
            endDateTime: DateTime(2026, 8, 20, 11, 30), // 11:30 AM
            isAllDay: false,
            source: 'Google Calendar',
            eventType: 'personal',
          ),
        ];

        final conflicts = service.detectConflictsForDate(
          date: testDate,
          timetableEntries: timetable,
          subjects: subjects,
          tasks: [],
          calendarEvents: gcalEvents,
        );

        expect(conflicts.length, 1);
        expect(conflicts.first.conflictType, ConflictType.classAndGoogleEvent);
        expect(conflicts.first.overlapMinutes, 30);
      },
    );

    test('3. Exact same time creates high severity conflict', () {
      final timetable = [
        TimetableEntry(
          id: 'entry_1',
          userId: 'u1',
          semesterId: 'sem1',
          subjectId: 'sub_ml',
          dayOfWeek: 4,
          periodNumber: 1,
          startTime: 14 * 60, // 2:00 PM
          endTime: 15 * 60, // 3:00 PM
          isEnabled: true,
          createdAt: 0,
          updatedAt: 0,
        ),
      ];

      final gcalEvents = [
        CalendarEvent(
          id: 'e1',
          calendarId: 'cal1',
          calendarName: 'College',
          title: 'Guest Lecture',
          startDateTime: DateTime(2026, 8, 20, 14, 0),
          endDateTime: DateTime(2026, 8, 20, 15, 0),
          isAllDay: false,
          source: 'Google Calendar',
          eventType: 'personal',
        ),
      ];

      final conflicts = service.detectConflictsForDate(
        date: testDate,
        timetableEntries: timetable,
        subjects: subjects,
        tasks: [],
        calendarEvents: gcalEvents,
      );

      expect(conflicts.length, 1);
      expect(conflicts.first.overlapMinutes, 60);
      expect(conflicts.first.severity, ConflictSeverity.high);
    });

    test('4. Event ending exactly when another starts is NOT a conflict', () {
      final timetable = [
        TimetableEntry(
          id: 'entry_1',
          userId: 'u1',
          semesterId: 'sem1',
          subjectId: 'sub_ds',
          dayOfWeek: 4,
          periodNumber: 1,
          startTime: 10 * 60, // 10:00 AM
          endTime: 11 * 60, // 11:00 AM
          isEnabled: true,
          createdAt: 0,
          updatedAt: 0,
        ),
      ];

      final gcalEvents = [
        CalendarEvent(
          id: 'e1',
          calendarId: 'cal1',
          calendarName: 'Personal',
          title: 'Lunch',
          startDateTime: DateTime(2026, 8, 20, 11, 0), // Exactly 11:00 AM
          endDateTime: DateTime(2026, 8, 20, 12, 0),
          isAllDay: false,
          source: 'Google Calendar',
          eventType: 'personal',
        ),
      ];

      final conflicts = service.detectConflictsForDate(
        date: testDate,
        timetableEntries: timetable,
        subjects: subjects,
        tasks: [],
        calendarEvents: gcalEvents,
      );

      expect(conflicts.isEmpty, isTrue);
    });

    test('5. Nested event (event fully inside another) is detected', () {
      final gcalEvents = [
        CalendarEvent(
          id: 'e1',
          calendarId: 'cal1',
          calendarName: 'Work',
          title: 'Hackathon Workshop',
          startDateTime: DateTime(2026, 8, 20, 13, 0), // 1:00 PM
          endDateTime: DateTime(2026, 8, 20, 17, 0), // 5:00 PM
          isAllDay: false,
          source: 'Google Calendar',
          eventType: 'personal',
        ),
        CalendarEvent(
          id: 'e2',
          calendarId: 'cal2',
          calendarName: 'Personal',
          title: 'Mentor Check-in',
          startDateTime: DateTime(2026, 8, 20, 14, 0), // 2:00 PM
          endDateTime: DateTime(2026, 8, 20, 14, 45), // 2:45 PM
          isAllDay: false,
          source: 'Google Calendar',
          eventType: 'personal',
        ),
      ];

      final conflicts = service.detectConflictsForDate(
        date: testDate,
        timetableEntries: [],
        subjects: subjects,
        tasks: [],
        calendarEvents: gcalEvents,
      );

      expect(conflicts.length, 1);
      expect(
        conflicts.first.conflictType,
        ConflictType.googleEventAndGoogleEvent,
      );
      expect(conflicts.first.overlapMinutes, 45);
    });

    test(
      '6. All-day public holiday does NOT generate false conflicts with classes',
      () {
        final timetable = [
          TimetableEntry(
            id: 'entry_1',
            userId: 'u1',
            semesterId: 'sem1',
            subjectId: 'sub_ds',
            dayOfWeek: 4,
            periodNumber: 1,
            startTime: 9 * 60,
            endTime: 10 * 60,
            isEnabled: true,
            createdAt: 0,
            updatedAt: 0,
          ),
        ];

        final allDayHoliday = CalendarEvent(
          id: 'h1',
          calendarId: 'en.indian#holiday@group.v.calendar.google.com',
          calendarName: 'Holidays in India',
          title: 'Independence Day',
          startDateTime: DateTime(2026, 8, 20),
          endDateTime: DateTime(2026, 8, 21),
          isAllDay: true,
          source: 'Google Calendar',
          eventType: 'holiday',
        );

        final conflicts = service.detectConflictsForDate(
          date: testDate,
          timetableEntries: timetable,
          subjects: subjects,
          tasks: [],
          calendarEvents: [allDayHoliday],
        );

        expect(conflicts.isEmpty, isTrue);
      },
    );

    test('7. Study task overlapping college class is detected', () {
      final timetable = [
        TimetableEntry(
          id: 'entry_1',
          userId: 'u1',
          semesterId: 'sem1',
          subjectId: 'sub_ds',
          dayOfWeek: 4,
          periodNumber: 1,
          startTime: 15 * 60, // 3:00 PM
          endTime: 16 * 60, // 4:00 PM
          isEnabled: true,
          createdAt: 0,
          updatedAt: 0,
        ),
      ];

      final tasks = [
        Task(
          id: 'task_study_1',
          userId: 'u1',
          semesterId: 'sem1',
          title: 'Algorithms Homework',
          category: 'Assignment',
          priority: 'High',
          dueDate: DateTime(2026, 8, 20),
          dueTime: '3:30 PM',
          isCompleted: false,
          recurrenceRule: 'None',
          createdAt: 0,
          updatedAt: 0,
        ),
      ];

      final conflicts = service.detectConflictsForDate(
        date: testDate,
        timetableEntries: timetable,
        subjects: subjects,
        tasks: tasks,
        calendarEvents: [],
      );

      expect(conflicts.length, 1);
      expect(conflicts.first.conflictType, ConflictType.classAndStudyTask);
      expect(
        conflicts.first.description.contains('Algorithms Homework'),
        isTrue,
      );
    });

    test('8. Study task overlapping Google Calendar event is detected', () {
      final tasks = [
        Task(
          id: 'task_revision',
          userId: 'u1',
          semesterId: 'sem1',
          title: 'Finals Revision',
          category: 'Study',
          priority: 'Urgent',
          dueDate: DateTime(2026, 8, 20),
          dueTime: '16:00', // 4:00 PM
          isCompleted: false,
          recurrenceRule: 'None',
          createdAt: 0,
          updatedAt: 0,
        ),
      ];

      final gcalEvents = [
        CalendarEvent(
          id: 'e1',
          calendarId: 'cal_work',
          calendarName: 'Work',
          title: 'Team Sync',
          startDateTime: DateTime(2026, 8, 20, 16, 30),
          endDateTime: DateTime(2026, 8, 20, 17, 30),
          isAllDay: false,
          source: 'Google Calendar',
          eventType: 'personal',
        ),
      ];

      final conflicts = service.detectConflictsForDate(
        date: testDate,
        timetableEntries: [],
        subjects: subjects,
        tasks: tasks,
        calendarEvents: gcalEvents,
      );

      expect(conflicts.length, 1);
      expect(
        conflicts.first.conflictType,
        ConflictType.studyTaskAndGoogleEvent,
      );
    });

    testWidgets(
      '9. CalendarConflictDetailsSheet renders conflict overview and empty state',
      (tester) async {
        final conflict = CalendarConflict(
          id: 'conf_1',
          firstEvent: ConflictScheduleItem(
            id: 'item1',
            title: 'Data Structures Class',
            itemType: ConflictItemType.collegeClass,
            startDateTime: DateTime(2026, 8, 20, 10, 0),
            endDateTime: DateTime(2026, 8, 20, 11, 0),
            subtitle: 'Room 302',
          ),
          secondEvent: ConflictScheduleItem(
            id: 'item2',
            title: 'Client Project Meeting',
            itemType: ConflictItemType.googleEvent,
            startDateTime: DateTime(2026, 8, 20, 10, 30),
            endDateTime: DateTime(2026, 8, 20, 11, 30),
            subtitle: 'Personal',
          ),
          startDateTime: DateTime(2026, 8, 20, 10, 30),
          endDateTime: DateTime(2026, 8, 20, 11, 0),
          conflictType: ConflictType.classAndGoogleEvent,
          severity: ConflictSeverity.high,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => CalendarConflictDetailsSheet.show(
                    ctx,
                    conflicts: [conflict],
                    date: DateTime(2026, 8, 20),
                  ),
                  child: const Text('Open Conflicts'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Conflicts'));
        await tester.pumpAndSettle();

        expect(find.text('1 Schedule Conflict'), findsOneWidget);
        expect(find.text('Data Structures Class'), findsOneWidget);
        expect(find.text('Client Project Meeting'), findsOneWidget);
        expect(find.text('Overlap: 30 min'), findsOneWidget);
        expect(find.text('Keep Schedule Anyway'), findsOneWidget);
      },
    );
  });
}
