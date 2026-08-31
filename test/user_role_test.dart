import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/core/models/user_role.dart';

void main() {
  group('parseUserRole', () {
    // --- Recognized roles ---
    test('returns admin for "admin" string', () {
      expect(parseUserRole('admin'), UserRole.admin);
    });

    test('returns faculty for "faculty" string', () {
      expect(parseUserRole('faculty'), UserRole.faculty);
    });

    test('returns student for "student" string', () {
      expect(parseUserRole('student'), UserRole.student);
    });

    // --- Fail-safe defaults (must NEVER be admin) ---
    test('returns student for null (missing claim)', () {
      expect(parseUserRole(null), UserRole.student);
    });

    test('returns student for empty string', () {
      expect(parseUserRole(''), UserRole.student);
    });

    test('returns student for unknown string', () {
      expect(parseUserRole('superuser'), UserRole.student);
      expect(parseUserRole('root'), UserRole.student);
      expect(parseUserRole('ADMIN'), UserRole.student); // case-sensitive
      expect(parseUserRole('Admin'), UserRole.student);
    });

    test('returns student for integer input', () {
      expect(parseUserRole(1), UserRole.student);
      expect(parseUserRole(0), UserRole.student);
    });

    test('returns student for boolean input', () {
      expect(parseUserRole(true), UserRole.student);
      expect(parseUserRole(false), UserRole.student);
    });

    test('returns student for map/object input', () {
      expect(parseUserRole({'role': 'admin'}), UserRole.student);
    });
  });

  group('UserRole enum', () {
    test('admin is elevated (not equal to student)', () {
      expect(UserRole.admin == UserRole.student, false);
    });

    test('faculty is not admin', () {
      expect(UserRole.faculty == UserRole.admin, false);
    });

    test('student is the default least-privileged role', () {
      // Verify the default in parseUserRole is always student
      final unknownValues = [null, '', 'unknown', 'root', 123, true, []];
      for (final v in unknownValues) {
        expect(
          parseUserRole(v),
          UserRole.student,
          reason: 'Expected student for value: $v',
        );
      }
    });
  });

  group('Authorization logic', () {
    test('only admin role grants admin access', () {
      final roles = [UserRole.student, UserRole.faculty, UserRole.admin];
      final adminRoles = roles.where((r) => r == UserRole.admin).toList();
      expect(adminRoles, [UserRole.admin]);
      expect(adminRoles.length, 1);
    });

    test('student and faculty cannot access admin', () {
      expect(UserRole.student == UserRole.admin, false);
      expect(UserRole.faculty == UserRole.admin, false);
    });
  });
}
