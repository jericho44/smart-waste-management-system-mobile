import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/models/login_request.dart';
import '../../data/models/register_request.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Riverpod Notifier managing authentication state lifecycle and session verification.
class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    return AuthState.initial();
  }

  /// Check stored token and validate existing session through GET /auth/me.
  Future<void> checkAuthStatus() async {
    final hasToken = await _repository.hasStoredToken();

    if (!hasToken) {
      state = AuthState.unauthenticated();
      return;
    }

    try {
      final user = await _repository.getMe();
      state = AuthState.authenticated(user);
    } on UnauthorizedException {
      await _repository.clearLocalAuth();
      state = AuthState.unauthenticated();
    } on NetworkException {
      // If offline, check if we have cached user data to preserve session
      final cachedUser = await _repository.getCachedUser();
      if (cachedUser != null) {
        state = AuthState.authenticated(cachedUser);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      await _repository.clearLocalAuth();
      state = AuthState.unauthenticated();
    }
  }

  /// Authenticate user via Sanctum API and update state.
  Future<bool> login({required String email, required String password}) async {
    state = AuthState.authenticating();

    try {
      final result = await _repository.login(
        LoginRequest(email: email, password: password),
      );
      state = AuthState.authenticated(result.user);
      return true;
    } on ValidationException catch (e) {
      state = AuthState.error(e.primaryErrorMessage, errors: e.errors);
      return false;
    } on AppException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error(
        'Failed to log in. Please check your connection.',
      );
      return false;
    }
  }

  /// Register new citizen user and auto-login if backend returns valid token.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = AuthState.authenticating();

    try {
      final result = await _repository.register(
        RegisterRequest(
          name: name,
          email: email,
          password: password,
          passwordConfirmation: passwordConfirmation,
        ),
      );
      state = AuthState.authenticated(result.user);
      return true;
    } on ValidationException catch (e) {
      state = AuthState.error(e.primaryErrorMessage, errors: e.errors);
      return false;
    } on AppException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('Failed to create account. Please try again.');
      return false;
    }
  }

  /// Log out from backend, purge local credentials, and reset state.
  Future<void> logout() async {
    state = AuthState.authenticating();
    await _repository.logout();
    state = AuthState.unauthenticated();
  }

  /// Centralized handler for HTTP 401 unauthorized errors from anywhere in the app.
  Future<void> handleUnauthorized() async {
    await _repository.clearLocalAuth();
    state = AuthState.unauthenticated();
  }
}

/// Global provider for AuthNotifier
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
