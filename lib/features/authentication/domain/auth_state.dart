import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/core/models/user_role.dart';

enum AuthStatus { loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserProfile? userProfile;
  final String? errorMessage;

  /// The current user's role, derived from the Firebase ID Token custom claim.
  /// Always defaults to [UserRole.student] when unauthenticated or when the
  /// claim is missing/malformed.
  final UserRole role;

  AuthState({
    required this.status,
    this.userProfile,
    this.errorMessage,
    this.role = UserRole.student,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.loading);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);

  factory AuthState.authenticated(UserProfile profile, {UserRole role = UserRole.student}) =>
      AuthState(
        status: AuthStatus.authenticated,
        userProfile: profile,
        role: role,
      );

  factory AuthState.unauthenticated() =>
      AuthState(status: AuthStatus.unauthenticated, role: UserRole.student);

  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message, role: UserRole.student);

  /// Convenience getter — true only when the Firebase Custom Claim role == 'admin'
  bool get isAdmin => role == UserRole.admin;

  /// Convenience getter — true only when role == 'faculty'
  bool get isFaculty => role == UserRole.faculty;
}
