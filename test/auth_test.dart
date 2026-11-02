import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_mobile/core/errors/app_exception.dart';
import 'package:smart_waste_mobile/core/network/api_client.dart';
import 'package:smart_waste_mobile/core/storage/secure_storage_service.dart';
import 'package:smart_waste_mobile/features/authentication/data/models/auth_response.dart';
import 'package:smart_waste_mobile/features/authentication/data/models/login_request.dart';
import 'package:smart_waste_mobile/features/authentication/data/models/register_request.dart';
import 'package:smart_waste_mobile/features/authentication/data/repositories/auth_repository.dart';
import 'package:smart_waste_mobile/features/authentication/domain/models/authenticated_user.dart';
import 'package:smart_waste_mobile/features/authentication/presentation/state/auth_notifier.dart';
import 'package:smart_waste_mobile/features/authentication/presentation/state/auth_state.dart';

class MockAuthRepository implements AuthRepository {
  @override
  late final ApiClient apiClient;

  @override
  late final SecureStorageService storageService;

  bool hasTokenResult = false;
  AuthenticatedUser? meResult;
  Exception? meException;
  AuthResponse? loginResult;
  Exception? loginException;
  AuthResponse? registerResult;
  Exception? registerException;
  bool logoutCalled = false;
  bool clearLocalAuthCalled = false;

  @override
  Future<bool> hasStoredToken() async => hasTokenResult;

  @override
  Future<AuthenticatedUser> getMe() async {
    if (meException != null) throw meException!;
    return meResult!;
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    if (loginException != null) throw loginException!;
    return loginResult!;
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    if (registerException != null) throw registerException!;
    return registerResult!;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<void> clearLocalAuth() async {
    clearLocalAuthCalled = true;
  }

  @override
  Future<AuthenticatedUser?> getCachedUser() async => meResult;
}

void main() {
  const testUser = AuthenticatedUser(
    uuid: 'user-uuid-123',
    name: 'Citizen Tester',
    email: 'user@waste.local',
    roles: ['user'],
    permissions: ['reports:create', 'reports:view-own'],
  );

  const testAuthResponse = AuthResponse(
    user: testUser,
    token: '1|sanctum_mock_token_abc123',
    tokenType: 'Bearer',
  );

  group('Authentication Model Serialization Tests', () {
    test('AuthenticatedUser parses from and serializes to JSON correctly', () {
      final json = testUser.toJson();
      final parsed = AuthenticatedUser.fromJson(json);

      expect(parsed.uuid, equals('user-uuid-123'));
      expect(parsed.name, equals('Citizen Tester'));
      expect(parsed.email, equals('user@waste.local'));
      expect(parsed.isAdmin, isFalse);
      expect(parsed.hasPermission('reports:create'), isTrue);
    });

    test('LoginRequest produces valid json payload without whitespace', () {
      const request = LoginRequest(
        email: '  user@waste.local  ',
        password: 'Password@123',
        deviceName: 'android_test',
      );
      final json = request.toJson();

      expect(json['email'], equals('user@waste.local'));
      expect(json['password'], equals('Password@123'));
      expect(json['device_name'], equals('android_test'));
    });

    test('RegisterRequest excludes role selection and enforces citizen role contract', () {
      const request = RegisterRequest(
        name: 'John Citizen',
        email: 'john@example.com',
        password: 'Password@123',
        passwordConfirmation: 'Password@123',
      );
      final json = request.toJson();

      expect(json.containsKey('role'), isFalse);
      expect(json['name'], equals('John Citizen'));
      expect(json['email'], equals('john@example.com'));
      expect(json['password_confirmation'], equals('Password@123'));
    });
  });

  group('AuthNotifier and State Lifecycle Tests', () {
    late MockAuthRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockAuthRepository();
      container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    test('Initial state is AuthStatus.initial', () {
      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.initial));
      expect(state.isAuthenticated, isFalse);
    });

    test(
      'checkAuthStatus transitions to unauthenticated if no stored token',
      () async {
        mockRepository.hasTokenResult = false;

        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.checkAuthStatus();

        final state = container.read(authNotifierProvider);
        expect(state.status, equals(AuthStatus.unauthenticated));
        expect(state.isAuthenticated, isFalse);
      },
    );

    test(
      'checkAuthStatus transitions to authenticated when valid token exists',
      () async {
        mockRepository.hasTokenResult = true;
        mockRepository.meResult = testUser;

        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.checkAuthStatus();

        final state = container.read(authNotifierProvider);
        expect(state.status, equals(AuthStatus.authenticated));
        expect(state.isAuthenticated, isTrue);
        expect(state.user?.name, equals('Citizen Tester'));
      },
    );

    test(
      'checkAuthStatus purges storage and marks unauthenticated on 401',
      () async {
        mockRepository.hasTokenResult = true;
        mockRepository.meException = const UnauthorizedException(
          message: 'Unauthenticated.',
          statusCode: 401,
        );

        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.checkAuthStatus();

        final state = container.read(authNotifierProvider);
        expect(state.status, equals(AuthStatus.unauthenticated));
        expect(mockRepository.clearLocalAuthCalled, isTrue);
      },
    );

    test('login succeeds and sets state to authenticated', () async {
      mockRepository.loginResult = testAuthResponse;

      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.login(
        email: 'user@waste.local',
        password: 'Password@123',
      );

      expect(success, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.authenticated));
      expect(state.user?.email, equals('user@waste.local'));
    });

    test(
      'login with invalid credentials captures 422 validation errors in state',
      () async {
        mockRepository.loginException = const ValidationException(
          message: 'These credentials do not match our records.',
          errors: {
            'email': ['These credentials do not match our records.'],
          },
        );

        final notifier = container.read(authNotifierProvider.notifier);
        final success = await notifier.login(
          email: 'wrong@waste.local',
          password: 'bad-password',
        );

        expect(success, isFalse);
        final state = container.read(authNotifierProvider);
        expect(state.status, equals(AuthStatus.error));
        expect(
          state.errorMessage,
          equals('These credentials do not match our records.'),
        );
        expect(
          state.errorFor('email'),
          equals('These credentials do not match our records.'),
        );
      },
    );

    test('logout invokes repository logout and clears session', () async {
      mockRepository.hasTokenResult = true;
      mockRepository.meResult = testUser;

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.checkAuthStatus();
      expect(container.read(authNotifierProvider).isAuthenticated, isTrue);

      await notifier.logout();

      expect(mockRepository.logoutCalled, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.unauthenticated));
      expect(state.user, isNull);
    });
  });
}
