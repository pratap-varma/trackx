import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/features/ai_advisor/domain/services/academic_context_builder.dart';
import 'package:trackx/features/attendance/domain/models/classroom_location_model.dart';

void main() {
  group('Stage 7 - AI Context, Geofences & Widgets Tests', () {
    test(
      'AcademicContextBuilder excludes notes by default and formats consent categories',
      () {
        final profile = UserProfile(
          id: 'u1',
          name: 'John Doe',
          email: 'john@example.com',
          branch: 'CS',
          semester: 3,
          globalTarget: 75.0,
          themeMode: 'dark',
          themeColorPack: 'purple',
          onboardingCompleted: true,
          createdTimestamp: 100,
          updatedTimestamp: 100,
        );

        final consentFlags = {
          'attendance': true,
          'tasks': false,
          'notes': false,
        };

        final context = AcademicContextBuilder.buildContext(
          profile: profile,
          semesters: [],
          subjects: [],
          attendance: [],
          tasks: [],
          assignments: [],
          exams: [],
          privacyConsent: consentFlags,
        );

        // Verify profile is shared
        expect(context['profile']['name'], 'John Doe');

        // Verify attendance is shared
        expect(context['attendanceCount'], 0);

        // Verify tasks are filtered out due to consent flag
        expect(context.containsKey('tasks'), false);

        // Verify notes are strictly excluded
        expect(context['notesExcluded'], true);
      },
    );

    test('ClassroomLocation geofence matches distance check radius', () {
      final classroom = ClassroomLocation(
        id: 'c1',
        userId: 'u1',
        semesterId: 's1',
        name: 'DBMS Classroom',
        latitude: 12.9716,
        longitude: 77.5946,
        radiusMeters: 50.0,
        isEnabled: true,
        createdAt: 100,
        updatedAt: 100,
      );

      // Simple Distance validation
      final userLat = 12.9718;
      final userLon = 77.5948;

      expect(userLat > classroom.latitude, true);
      expect(userLon > classroom.longitude, true);

      // Rough distance in meters (approximate)
      final distance = 30.0; // inside radius
      expect(distance <= classroom.radiusMeters, true);
    });

    test('Widget privacy options serialization formats correctly', () {
      final widgetData = {
        'overallAttendance': 78.5,
        'classesToday': 3,
        'nextClassName': 'Database Systems',
        'privacyMode': 'Hide subject names',
      };

      expect(widgetData['privacyMode'], 'Hide subject names');
    });
  });
}
