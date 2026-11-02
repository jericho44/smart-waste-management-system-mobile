import '../../domain/models/authenticated_user.dart';

/// Possible states of the application authentication flow.
enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

/// Immutable state holder for authentication.
class AuthState {
  final AuthStatus status;
  final AuthenticatedUser? user;
  final String? errorMessage;
  final Map<String, List<String>> validationErrors;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.validationErrors = const {},
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.authenticating() =>
      const AuthState(status: AuthStatus.authenticating);

  factory AuthState.authenticated(AuthenticatedUser user) =>
      AuthState(status: AuthStatus.authenticated, user: user);

  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.error(
    String message, {
    Map<String, List<String>> errors = const {},
    AuthenticatedUser? user,
  }) => AuthState(
    status: AuthStatus.error,
    errorMessage: message,
    validationErrors: errors,
    user: user,
  );

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isAuthenticating => status == AuthStatus.authenticating;
  bool get isInitial => status == AuthStatus.initial;

  /// Retrieve the first error message for a specific form field
  String? errorFor(String field) => validationErrors[field]?.firstOrNull;

  AuthState copyWith({
    AuthStatus? status,
    AuthenticatedUser? user,
    String? errorMessage,
    Map<String, List<String>>? validationErrors,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}
