import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_waste_mobile/app/config/app_config.dart';
import 'package:smart_waste_mobile/core/constants/app_constants.dart';
import 'package:smart_waste_mobile/core/network/api_client.dart';
import 'package:smart_waste_mobile/core/storage/secure_storage_service.dart';
import 'package:smart_waste_mobile/features/authentication/data/models/auth_response.dart';
import 'package:smart_waste_mobile/features/authentication/data/models/login_request.dart';
import 'package:smart_waste_mobile/features/authentication/data/models/register_request.dart';
import 'package:smart_waste_mobile/features/authentication/data/repositories/auth_repository.dart';
import 'package:smart_waste_mobile/features/authentication/domain/models/authenticated_user.dart';
import 'package:smart_waste_mobile/features/authentication/presentation/screens/login_screen.dart';
import 'package:smart_waste_mobile/features/authentication/presentation/screens/register_screen.dart';
import 'package:smart_waste_mobile/features/authentication/presentation/state/auth_notifier.dart';
import 'package:smart_waste_mobile/features/authentication/presentation/state/auth_state.dart';
import 'package:smart_waste_mobile/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:smart_waste_mobile/features/dashboard/domain/models/dashboard_data.dart';
import 'package:smart_waste_mobile/features/profile/data/repositories/profile_repository.dart';
import 'package:smart_waste_mobile/features/profile/domain/models/change_password_request.dart';
import 'package:smart_waste_mobile/features/profile/domain/models/update_profile_request.dart';
import 'package:smart_waste_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:smart_waste_mobile/features/profile/presentation/state/profile_notifier.dart';
import 'package:smart_waste_mobile/features/report_creation/data/repositories/report_creation_repository.dart';
import 'package:smart_waste_mobile/features/report_creation/domain/models/create_report_form_data.dart';
import 'package:smart_waste_mobile/features/report_creation/domain/services/location_service.dart';
import 'package:smart_waste_mobile/features/report_creation/presentation/screens/create_report_screen.dart';
import 'package:smart_waste_mobile/features/report_creation/presentation/state/report_creation_notifier.dart';
import 'package:smart_waste_mobile/features/reports/data/repositories/report_repository.dart';
import 'package:smart_waste_mobile/features/reports/domain/models/report_image.dart';
import 'package:smart_waste_mobile/features/reports/domain/models/status_history_item.dart';
import 'package:smart_waste_mobile/features/reports/domain/models/waste_category.dart';
import 'package:smart_waste_mobile/features/reports/domain/models/waste_report.dart';
import 'package:smart_waste_mobile/features/reports/presentation/screens/report_details_screen.dart';
import 'package:smart_waste_mobile/features/reports/presentation/screens/reports_screen.dart';
import 'package:smart_waste_mobile/shared/models/api_response.dart';

// Unified Test Repository Implementations
class IntegrationMockAuthRepository implements AuthRepository {
  @override
  late final ApiClient apiClient;
  @override
  late final SecureStorageService storageService;

  bool hasToken = false;
  AuthenticatedUser? currentUser;
  bool logoutCalled = false;

  @override
  Future<bool> hasStoredToken() async => hasToken;

  @override
  Future<AuthenticatedUser> getMe() async => currentUser!;

  @override
  Future<AuthenticatedUser?> getCachedUser() async => currentUser;

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    hasToken = true;
    currentUser = AuthenticatedUser(
      uuid: 'user-auth-100',
      name: 'Integration Tester',
      email: request.email,
      roles: const ['user'],
    );
    return AuthResponse(token: 'test-sanctum-token', user: currentUser!);
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    hasToken = true;
    currentUser = AuthenticatedUser(
      uuid: 'user-auth-200',
      name: request.name,
      email: request.email,
      roles: const ['user'],
    );
    return AuthResponse(token: 'test-sanctum-token-2', user: currentUser!);
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    hasToken = false;
    currentUser = null;
  }

  @override
  Future<void> clearLocalAuth() async {
    hasToken = false;
    currentUser = null;
  }
}

class IntegrationMockDashboardRepository implements DashboardRepository {
  @override
  late final ApiClient apiClient;

  @override
  Future<DashboardData> getUserDashboard() async {
    return const DashboardData(
      totalReports: 1,
      pendingReports: 1,
      inProgressReports: 0,
      completedReports: 0,
      rejectedReports: 0,
    );
  }
}

class IntegrationMockReportRepository implements ReportRepository {
  @override
  late final ApiClient apiClient;

  List<WasteReport> reports = [];
  Map<String, List<StatusHistoryItem>> histories = {};

  @override
  Future<ApiResponse<List<WasteReport>>> getReports({
    int page = 1,
    int perPage = 10,
    String? search,
    String? status,
    String? categoryUuid,
    String sort = 'created_at',
    String order = 'desc',
  }) async {
    return ApiResponse<List<WasteReport>>(
      success: true,
      message: 'OK',
      data: reports,
    );
  }

  @override
  Future<WasteReport> getReportDetails(String uuid) async {
    return reports.firstWhere((r) => r.uuid == uuid);
  }

  @override
  Future<List<StatusHistoryItem>> getReportHistory(String uuid) async {
    return histories[uuid] ?? [];
  }

  @override
  Future<void> deleteReport(String uuid) async {
    reports.removeWhere((r) => r.uuid == uuid);
  }

  @override
  Future<List<WasteCategory>> getCategories() async {
    return const [
      WasteCategory(uuid: 'cat-org', name: 'Organic Waste', slug: 'organic'),
      WasteCategory(uuid: 'cat-plas', name: 'Plastic Waste', slug: 'plastic'),
    ];
  }
}

class IntegrationMockReportCreationRepository
    implements ReportCreationRepository {
  List<WasteCategory> categories = const [
    WasteCategory(uuid: 'cat-org', name: 'Organic Waste', slug: 'organic'),
    WasteCategory(uuid: 'cat-plas', name: 'Plastic Waste', slug: 'plastic'),
  ];

  WasteReport? nextCreatedReport;

  @override
  Future<List<WasteCategory>> getCategories() async => categories;

  @override
  Future<WasteReport> submitReport(
    CreateReportFormData formData, {
    void Function(int sent, int total)? onProgress,
  }) async {
    if (onProgress != null) onProgress(100, 100);
    return nextCreatedReport!;
  }
}

class IntegrationMockLocationService implements LocationService {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<UserLocation> getCurrentLocation() async =>
      const UserLocation(latitude: -6.2088, longitude: 106.8456, accuracy: 3.5);

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}

class IntegrationMockProfileRepository implements ProfileRepository {
  @override
  Future<AuthenticatedUser> updateProfile(UpdateProfileRequest request) async {
    return AuthenticatedUser(
      uuid: 'user-auth-100',
      name: request.name,
      email: request.email,
      roles: const ['user'],
    );
  }

  @override
  Future<void> changePassword(ChangePasswordRequest request) async {}
}

void main() {
  setUpAll(() async {
    await AppConfig.initialize();
  });

  const sampleCategory = WasteCategory(
    uuid: 'cat-org',
    name: 'Organic Waste',
    slug: 'organic',
  );

  final sampleReport = WasteReport(
    uuid: 'rep-workflow-100',
    title: 'Illegal Waste Dump near Market',
    description: 'Decomposed organic waste causing foul odor.',
    status: AppConstants.statusPending,
    latitude: -6.2088,
    longitude: 106.8456,
    address: 'Jl. Pasar Baru No. 12',
    category: sampleCategory,
    images: const [
      ReportImage(
        uuid: 'img-100',
        url: 'http://127.0.0.1:8000/storage/reports/test.jpg',
        originalFilename: 'test.jpg',
      ),
    ],
    createdAt: DateTime(2026, 11, 2, 14, 30),
  );

  final sampleHistory = StatusHistoryItem(
    uuid: 'hist-100',
    oldStatus: null,
    newStatus: AppConstants.statusPending,
    notes: 'Citizen submitted report',
    changedByName: 'Integration Tester',
    createdAt: DateTime(2026, 11, 2, 14, 30),
  );

  group('Workflow A — Authentication Flow', () {
    testWidgets('Registration, Login, Session Restore, and Logout workflow', (
      WidgetTester tester,
    ) async {
      final mockAuth = IntegrationMockAuthRepository();
      final mockDashboard = IntegrationMockDashboardRepository();
      final mockReports = IntegrationMockReportRepository();
      final mockCreation = IntegrationMockReportCreationRepository();
      final mockProfile = IntegrationMockProfileRepository();
      final mockLocation = IntegrationMockLocationService();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          dashboardRepositoryProvider.overrideWithValue(mockDashboard),
          reportRepositoryProvider.overrideWithValue(mockReports),
          reportCreationRepositoryProvider.overrideWithValue(mockCreation),
          profileRepositoryProvider.overrideWithValue(mockProfile),
          locationServiceProvider.overrideWithValue(mockLocation),
        ],
      );

      // 1. Initial State: unauthenticated
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // 2. Perform Login
      final notifier = container.read(authNotifierProvider.notifier);
      final loginOk = await notifier.login(
        email: 'test@waste.local',
        password: 'password123',
      );
      expect(loginOk, isTrue);

      final authState = container.read(authNotifierProvider);
      expect(authState.isAuthenticated, isTrue);
      expect(authState.user?.name, equals('Integration Tester'));

      // 3. Test Session Restore (GET /auth/me)
      await notifier.checkAuthStatus();
      final restoredState = container.read(authNotifierProvider);
      expect(restoredState.isAuthenticated, isTrue);

      // 4. Test Logout
      await notifier.logout();
      expect(mockAuth.logoutCalled, isTrue);
      final loggedOutState = container.read(authNotifierProvider);
      expect(loggedOutState.isAuthenticated, isFalse);

      container.dispose();
    });

    testWidgets(
      'Registration screen validates fields and submits registration',
      (WidgetTester tester) async {
        final mockAuth = IntegrationMockAuthRepository();

        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuth)],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: RegisterScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Create Account'), findsWidgets);

        // Submit registration through notifier
        final notifier = container.read(authNotifierProvider.notifier);
        final registerOk = await notifier.register(
          name: 'Jane Citizen',
          email: 'jane@waste.local',
          password: 'securePassword123',
          passwordConfirmation: 'securePassword123',
        );

        expect(registerOk, isTrue);
        final authState = container.read(authNotifierProvider);
        expect(authState.isAuthenticated, isTrue);
        expect(authState.user?.name, equals('Jane Citizen'));

        container.dispose();
      },
    );
  });

  group('Workflow B — Report Creation Flow', () {
    testWidgets(
      'Category selection, description input, GPS acquisition, and submission',
      (WidgetTester tester) async {
        final mockCreation = IntegrationMockReportCreationRepository();
        mockCreation.nextCreatedReport = sampleReport;

        final mockLocation = IntegrationMockLocationService();
        final mockReports = IntegrationMockReportRepository();
        final mockDashboard = IntegrationMockDashboardRepository();

        final container = ProviderContainer(
          overrides: [
            reportCreationRepositoryProvider.overrideWithValue(mockCreation),
            locationServiceProvider.overrideWithValue(mockLocation),
            reportRepositoryProvider.overrideWithValue(mockReports),
            dashboardRepositoryProvider.overrideWithValue(mockDashboard),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: CreateReportScreen()),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        // 1. Verify Screen Elements
        expect(find.text('Create Waste Report'), findsOneWidget);
        expect(find.text('Coordinates Acquired'), findsOneWidget);

        // 2. Select category and enter details
        final notifier = container.read(
          reportCreationNotifierProvider.notifier,
        );
        notifier.selectCategory(sampleCategory);

        final created = await notifier.submitReport(
          title: 'Illegal Waste Dump near Market',
          description: 'Decomposed organic waste causing foul odor.',
          address: 'Jl. Pasar Baru No. 12',
        );

        expect(created, isNotNull);
        expect(created?.uuid, equals('rep-workflow-100'));
        expect(created?.status, equals(AppConstants.statusPending));

        container.dispose();
      },
    );
  });

  group('Workflow C — Report Tracking Flow', () {
    testWidgets(
      'Reports list, report details view, and status history timeline',
      (WidgetTester tester) async {
        final mockReports = IntegrationMockReportRepository();
        mockReports.reports = [sampleReport];
        mockReports.histories = {
          'rep-workflow-100': [sampleHistory],
        };

        final container = ProviderContainer(
          overrides: [
            reportRepositoryProvider.overrideWithValue(mockReports),
            dashboardRepositoryProvider.overrideWithValue(
              IntegrationMockDashboardRepository(),
            ),
          ],
        );

        // 1. Report List Screen
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ReportsScreen()),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('My Waste Reports'), findsOneWidget);
        expect(find.text('Illegal Waste Dump near Market'), findsOneWidget);
        expect(find.text('Pending'), findsWidgets);

        // 2. Report Details Screen
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: ReportDetailsScreen(uuid: 'rep-workflow-100'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Report Details'), findsOneWidget);
        expect(find.text('Illegal Waste Dump near Market'), findsOneWidget);
        expect(find.text('Resolution History & Timeline'), findsOneWidget);
        expect(find.text('Citizen submitted report'), findsOneWidget);

        container.dispose();
      },
    );
  });

  group('Workflow D — Profile Management Flow', () {
    testWidgets(
      'View profile, update name/email, change password, and sign out confirmation',
      (WidgetTester tester) async {
        final mockAuth = IntegrationMockAuthRepository();
        final mockProfile = IntegrationMockProfileRepository();

        const user = AuthenticatedUser(
          uuid: 'user-auth-100',
          name: 'Original Citizen Name',
          email: 'citizen.original@waste.local',
          roles: ['user'],
        );

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            profileRepositoryProvider.overrideWithValue(mockProfile),
            authNotifierProvider.overrideWith(
              () => StaticAuthNotifier(user, customRepo: mockAuth),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Profile View
        expect(find.text('Original Citizen Name'), findsOneWidget);
        expect(find.text('citizen.original@waste.local'), findsOneWidget);
        expect(find.text('Citizen'), findsWidgets);

        // 2. Profile Update
        final profileNotifier = container.read(
          profileNotifierProvider.notifier,
        );
        final updateOk = await profileNotifier.updateProfile(
          const UpdateProfileRequest(
            name: 'Updated Citizen Name',
            email: 'citizen.updated@waste.local',
          ),
        );
        expect(updateOk, isTrue);

        // 3. Password Modification
        final pwdOk = await profileNotifier.changePassword(
          const ChangePasswordRequest(
            currentPassword: 'oldPassword123',
            newPassword: 'newPassword123',
            newPasswordConfirmation: 'newPassword123',
          ),
        );
        expect(pwdOk, isTrue);

        // 4. Logout Confirmation Dialog
        final signOutBtn = find.text('Sign Out');
        await tester.ensureVisible(signOutBtn);
        await tester.pumpAndSettle();
        await tester.tap(signOutBtn);
        await tester.pumpAndSettle();

        expect(find.text('Sign Out?'), findsOneWidget);
        await tester.tap(find.text('Sign Out').last);
        await tester.pumpAndSettle();

        expect(mockAuth.logoutCalled, isTrue);

        container.dispose();
      },
    );
  });
}

class StaticAuthNotifier extends AuthNotifier {
  final AuthenticatedUser user;
  final AuthRepository? customRepo;

  StaticAuthNotifier(this.user, {this.customRepo});

  @override
  AuthState build() => AuthState.authenticated(user);

  @override
  Future<void> checkAuthStatus() async {}

  @override
  Future<void> logout() async {
    await customRepo?.logout();
    state = AuthState.unauthenticated();
  }
}
