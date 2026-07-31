import 'package:trackx/core/models/user_profile.dart';

enum AuthStatus { loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserProfile? userProfile;
  final String? errorMessage;

  AuthState({required this.status, this.userProfile, this.errorMessage});

  factory AuthState.initial() => AuthState(status: AuthStatus.loading);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(UserProfile profile) =>
      AuthState(status: AuthStatus.authenticated, userProfile: profile);
  factory AuthState.unauthenticated() =>
      AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);
}
