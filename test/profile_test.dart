import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_mobile/app/config/app_config.dart';
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
import 'package:smart_waste_mobile/features/profile/data/repositories/profile_repository.dart';
import 'package:smart_waste_mobile/features/profile/domain/models/change_password_request.dart';
import 'package:smart_waste_mobile/features/profile/domain/models/update_profile_request.dart';
import 'package:smart_waste_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:smart_waste_mobile/features/profile/presentation/state/profile_notifier.dart';

// Mocks
class MockProfileRepository implements ProfileRepository {
  AuthenticatedUser? updateProfileResult;
  Exception? updateProfileException;
  bool updateProfileCalled = false;
  UpdateProfileRequest? capturedUpdateRequest;

  Exception? changePasswordException;
  bool changePasswordCalled = false;
  ChangePasswordRequest? capturedPasswordRequest;

  @override
  Future<AuthenticatedUser> updateProfile(UpdateProfileRequest request) async {
    updateProfileCalled = true;
    capturedUpdateRequest = request;
    if (updateProfileException != null) throw updateProfileException!;
    return updateProfileResult!;
  }

  @override
  Future<void> changePassword(ChangePasswordRequest request) async {
    changePasswordCalled = true;
    capturedPasswordRequest = request;
    if (changePasswordException != null) throw changePasswordException!;
  }
}

class MockAuthRepository implements AuthRepository {
  @override
  late final ApiClient apiClient;

  @override
  late final SecureStorageService storageService;

  bool logoutCalled = false;

  @override
  Future<bool> hasStoredToken() async => true;

  @override
  Future<AuthenticatedUser> getMe() async => throw UnimplementedError();

  @override
  Future<AuthenticatedUser?> getCachedUser() async => null;

  @override
  Future<AuthResponse> login(LoginRequest request) async =>
      throw UnimplementedError();

  @override
  Future<AuthResponse> register(RegisterRequest request) async =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<void> clearLocalAuth() async {}
}

void main() {
  setUpAll(() async {
    await AppConfig.initialize();
  });

  const sampleUser = AuthenticatedUser(
    uuid: 'user-uuid-1234',
    name: 'Budi Santoso',
    email: 'budi@waste.local',
    roles: ['user'],
  );

  group('Profile Request Validation Tests', () {
    test('UpdateProfileRequest validates required name and valid email', () {
      const emptyReq = UpdateProfileRequest(name: '', email: '');
      final emptyErrors = emptyReq.validate();
      expect(emptyErrors.containsKey('name'), isTrue);
      expect(emptyErrors.containsKey('email'), isTrue);

      const invalidEmailReq = UpdateProfileRequest(
        name: 'Budi',
        email: 'invalid-email-format',
      );
      final invalidErrors = invalidEmailReq.validate();
      expect(invalidErrors['email'], contains('valid email'));

      const validReq = UpdateProfileRequest(
        name: 'Budi Santoso',
        email: 'budi@waste.local',
      );
      final validErrors = validReq.validate();
      expect(validErrors.isEmpty, isTrue);
      expect(validReq.toJson()['name'], equals('Budi Santoso'));
      expect(validReq.toJson()['email'], equals('budi@waste.local'));
    });

    test('ChangePasswordRequest validates requirements and confirmation', () {
      const emptyReq = ChangePasswordRequest(
        currentPassword: '',
        newPassword: '',
        newPasswordConfirmation: '',
      );
      final emptyErrors = emptyReq.validate();
      expect(emptyErrors.containsKey('current_password'), isTrue);
      expect(emptyErrors.containsKey('new_password'), isTrue);

      const shortReq = ChangePasswordRequest(
        currentPassword: 'oldpassword',
        newPassword: 'short',
        newPasswordConfirmation: 'short',
      );
      expect(shortReq.validate()['new_password'], contains('8 characters'));

      const sameReq = ChangePasswordRequest(
        currentPassword: 'password123',
        newPassword: 'password123',
        newPasswordConfirmation: 'password123',
      );
      expect(sameReq.validate()['new_password'], contains('different'));

      const mismatchReq = ChangePasswordRequest(
        currentPassword: 'oldpassword123',
        newPassword: 'newpassword123',
        newPasswordConfirmation: 'mismatch123',
      );
      expect(
        mismatchReq.validate()['new_password_confirmation'],
        contains('match'),
      );

      const validReq = ChangePasswordRequest(
        currentPassword: 'oldpassword123',
        newPassword: 'newpassword123',
        newPasswordConfirmation: 'newpassword123',
      );
      expect(validReq.validate().isEmpty, isTrue);
    });
  });

  group('ProfileNotifier State & Logic Tests', () {
    late MockProfileRepository mockProfileRepo;
    late MockAuthRepository mockAuthRepo;
    late ProviderContainer container;

    setUp(() {
      mockProfileRepo = MockProfileRepository();
      mockAuthRepo = MockAuthRepository();

      container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(mockProfileRepo),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
      );

      // Pre-seed authenticated auth state
      container
          .read(authNotifierProvider.notifier)
          .updateCurrentUser(sampleUser);
    });

    tearDown(() {
      container.dispose();
    });

    test('updateProfile updates user state on success', () async {
      const updatedUser = AuthenticatedUser(
        uuid: 'user-uuid-1234',
        name: 'Budi Santoso Updated',
        email: 'budi.new@waste.local',
        roles: ['user'],
      );
      mockProfileRepo.updateProfileResult = updatedUser;

      final notifier = container.read(profileNotifierProvider.notifier);
      final success = await notifier.updateProfile(
        const UpdateProfileRequest(
          name: 'Budi Santoso Updated',
          email: 'budi.new@waste.local',
        ),
      );

      expect(success, isTrue);
      expect(mockProfileRepo.updateProfileCalled, isTrue);

      // Verify authenticated user in AuthNotifier was updated
      final authState = container.read(authNotifierProvider);
      expect(authState.user?.name, equals('Budi Santoso Updated'));
      expect(authState.user?.email, equals('budi.new@waste.local'));

      final profileState = container.read(profileNotifierProvider);
      expect(profileState.profileSuccessMessage, isNotNull);
    });

    test('updateProfile handles HTTP 422 email already taken error', () async {
      mockProfileRepo.updateProfileException = const ValidationException(
        message: 'The email has already been taken.',
        errors: {
          'email': ['The email has already been taken.'],
        },
      );

      final notifier = container.read(profileNotifierProvider.notifier);
      final success = await notifier.updateProfile(
        const UpdateProfileRequest(name: 'Budi', email: 'taken@waste.local'),
      );

      expect(success, isFalse);
      final profileState = container.read(profileNotifierProvider);
      expect(
        profileState.profileErrors['email'],
        equals('The email has already been taken.'),
      );
    });

    test('changePassword succeeds and sets success message', () async {
      final notifier = container.read(profileNotifierProvider.notifier);
      final success = await notifier.changePassword(
        const ChangePasswordRequest(
          currentPassword: 'currentPassword123',
          newPassword: 'brandNewPassword123',
          newPasswordConfirmation: 'brandNewPassword123',
        ),
      );

      expect(success, isTrue);
      expect(mockProfileRepo.changePasswordCalled, isTrue);

      final profileState = container.read(profileNotifierProvider);
      expect(profileState.passwordSuccessMessage, isNotNull);
    });

    test('changePassword captures HTTP 422 wrong current password', () async {
      mockProfileRepo.changePasswordException = const ValidationException(
        message: 'The password is incorrect.',
        errors: {
          'current_password': ['The password is incorrect.'],
        },
      );

      final notifier = container.read(profileNotifierProvider.notifier);
      final success = await notifier.changePassword(
        const ChangePasswordRequest(
          currentPassword: 'wrongPassword',
          newPassword: 'brandNewPassword123',
          newPasswordConfirmation: 'brandNewPassword123',
        ),
      );

      expect(success, isFalse);
      final profileState = container.read(profileNotifierProvider);
      expect(
        profileState.passwordErrors['current_password'],
        equals('The password is incorrect.'),
      );
    });
  });

  group('ProfileScreen Widget Tests', () {
    testWidgets('Renders user credentials, citizen role, and account tiles', (
      WidgetTester tester,
    ) async {
      final mockProfileRepo = MockProfileRepository();
      final mockAuthRepo = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            authNotifierProvider.overrideWith(
              () => StaticAuthNotifier(sampleUser),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Header card
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('budi@waste.local'), findsOneWidget);
      expect(find.text('Citizen'), findsWidgets);
      expect(find.text('Active'), findsOneWidget);

      // Account Settings tiles
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);

      // Details
      expect(find.text('Citizen ID'), findsOneWidget);
      expect(find.text('user-uuid-1234'), findsOneWidget);

      // Sign Out
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('Sign Out button opens confirmation dialog and can cancel', (
      WidgetTester tester,
    ) async {
      final mockProfileRepo = MockProfileRepository();
      final mockAuthRepo = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            authNotifierProvider.overrideWith(
              () => StaticAuthNotifier(sampleUser),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Sign Out button
      final signOutBtn = find.text('Sign Out');
      await tester.ensureVisible(signOutBtn);
      await tester.pumpAndSettle();
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Sign Out?'), findsOneWidget);
      expect(
        find.textContaining(
          'Your authentication token and private session data will be permanently cleared',
        ),
        findsOneWidget,
      );

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('Sign Out?'), findsNothing);
      expect(mockAuthRepo.logoutCalled, isFalse);
    });

    testWidgets(
      'Tapping Edit Profile opens edit dialog pre-filled with user info',
      (WidgetTester tester) async {
        final mockProfileRepo = MockProfileRepository();
        final mockAuthRepo = MockAuthRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              profileRepositoryProvider.overrideWithValue(mockProfileRepo),
              authRepositoryProvider.overrideWithValue(mockAuthRepo),
              authNotifierProvider.overrideWith(
                () => StaticAuthNotifier(sampleUser),
              ),
            ],
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Tap Edit Profile tile
        await tester.tap(find.text('Edit Profile'));
        await tester.pumpAndSettle();

        // Dialog appears
        expect(find.text('Edit Profile'), findsWidgets);
        expect(find.widgetWithText(TextField, 'Budi Santoso'), findsOneWidget);
        expect(
          find.widgetWithText(TextField, 'budi@waste.local'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Tapping Change Password opens password dialog with inputs', (
      WidgetTester tester,
    ) async {
      final mockProfileRepo = MockProfileRepository();
      final mockAuthRepo = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            authNotifierProvider.overrideWith(
              () => StaticAuthNotifier(sampleUser),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Change Password tile
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.text('Change Password'), findsWidgets);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
    });
  });
}

class StaticAuthNotifier extends AuthNotifier {
  final AuthenticatedUser user;

  StaticAuthNotifier(this.user);

  @override
  AuthState build() => AuthState.authenticated(user);

  @override
  Future<void> checkAuthStatus() async {}
}
