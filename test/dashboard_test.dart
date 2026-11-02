import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_mobile/core/errors/app_exception.dart';
import 'package:smart_waste_mobile/core/network/api_client.dart';
import 'package:smart_waste_mobile/features/authentication/domain/models/authenticated_user.dart';
import 'package:smart_waste_mobile/features/authentication/presentation/state/auth_notifier.dart';
import 'package:smart_waste_mobile/features/authentication/presentation/state/auth_state.dart';
import 'package:smart_waste_mobile/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:smart_waste_mobile/features/dashboard/domain/models/dashboard_data.dart';
import 'package:smart_waste_mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:smart_waste_mobile/features/dashboard/presentation/state/dashboard_notifier.dart';
import 'package:smart_waste_mobile/features/dashboard/presentation/state/dashboard_state.dart';

class MockDashboardRepository implements DashboardRepository {
  @override
  late final ApiClient apiClient;

  DashboardData? dashboardDataResult;
  Exception? dashboardException;
  bool getUserDashboardCalled = false;

  @override
  Future<DashboardData> getUserDashboard() async {
    getUserDashboardCalled = true;
    if (dashboardException != null) throw dashboardException!;
    return dashboardDataResult!;
  }
}

class StaticAuthNotifier extends AuthNotifier {
  final AuthenticatedUser user;

  StaticAuthNotifier(this.user);

  @override
  AuthState build() => AuthState.authenticated(user);

  @override
  Future<void> checkAuthStatus() async {
    state = AuthState.authenticated(user);
  }
}

void main() {
  const sampleDashboardJson = {
    'total_reports': 10,
    'pending_reports': 3,
    'in_progress_reports': 4,
    'completed_reports': 2,
    'rejected_reports': 1,
    'reports_by_category': [
      {
        'uuid': 'cat-1',
        'name': 'Plastic Waste',
        'slug': 'plastic',
        'count': 6,
        'percentage': 60.0,
      },
    ],
    'latest_reports': [
      {
        'uuid': 'rep-1',
        'title': 'Plastic bags on sidewalk',
        'description': 'Piles of shopping bags near bus station',
        'status': 'PENDING',
        'category': {
          'uuid': 'cat-1',
          'name': 'Plastic Waste',
          'slug': 'plastic',
        },
        'images': [
          {
            'uuid': 'img-1',
            'url': 'http://127.0.0.1:8000/storage/reports/sample.jpg',
          },
        ],
        'address': 'Jl. Sudirman No. 42',
        'created_at': '2026-11-02T19:40:00+07:00',
      },
    ],
  };

  const sampleCitizen = AuthenticatedUser(
    uuid: 'citizen-uuid-42',
    name: 'Jane Doe',
    email: 'jane@waste.local',
    roles: ['user'],
  );

  group('Dashboard Model Deserialization Tests', () {
    test('DashboardData correctly parses backend JSON response', () {
      final dashboard = DashboardData.fromJson(sampleDashboardJson);

      expect(dashboard.totalReports, equals(10));
      expect(dashboard.pendingReports, equals(3));
      expect(dashboard.inProgressReports, equals(4));
      expect(dashboard.completedReports, equals(2));
      expect(dashboard.rejectedReports, equals(1));
      expect(dashboard.hasReports, isTrue);

      expect(dashboard.reportsByCategory.length, equals(1));
      final cat = dashboard.reportsByCategory.first;
      expect(cat.name, equals('Plastic Waste'));
      expect(cat.percentage, equals(60.0));

      expect(dashboard.latestReports.length, equals(1));
      final rep = dashboard.latestReports.first;
      expect(rep.uuid, equals('rep-1'));
      expect(rep.title, equals('Plastic bags on sidewalk'));
      expect(rep.isPending, isTrue);
      expect(rep.categoryName, equals('Plastic Waste'));
      expect(
        rep.imageUrl,
        equals('http://127.0.0.1:8000/storage/reports/sample.jpg'),
      );
    });

    test('DashboardData handles empty metrics safely', () {
      final empty = DashboardData.fromJson(const {});
      expect(empty.totalReports, equals(0));
      expect(empty.pendingReports, equals(0));
      expect(empty.hasReports, isFalse);
      expect(empty.latestReports, isEmpty);
    });
  });

  group('DashboardNotifier State Transitions Tests', () {
    late MockDashboardRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockDashboardRepository();
      container = ProviderContainer(
        overrides: [dashboardRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() => container.dispose());

    test('Initial state is DashboardStatus.initial', () {
      final state = container.read(dashboardNotifierProvider);
      expect(state.status, equals(DashboardStatus.initial));
      expect(state.data, isNull);
    });

    test('loadDashboard loads data and sets state to success', () async {
      mockRepo.dashboardDataResult = DashboardData.fromJson(
        sampleDashboardJson,
      );

      final notifier = container.read(dashboardNotifierProvider.notifier);
      await notifier.loadDashboard();

      final state = container.read(dashboardNotifierProvider);
      expect(state.status, equals(DashboardStatus.success));
      expect(state.data?.totalReports, equals(10));
      expect(state.data?.pendingReports, equals(3));
      expect(mockRepo.getUserDashboardCalled, isTrue);
    });

    test('loadDashboard sets error state on network failure', () async {
      mockRepo.dashboardException = const NetworkException(
        message: 'Could not reach server.',
      );

      final notifier = container.read(dashboardNotifierProvider.notifier);
      await notifier.loadDashboard();

      final state = container.read(dashboardNotifierProvider);
      expect(state.status, equals(DashboardStatus.error));
      expect(state.errorMessage, equals('Could not reach server.'));
      expect(state.data, isNull);
    });
  });

  group('DashboardScreen Widget Tests', () {
    testWidgets('Renders dashboard greeting, statistics and recent reports', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockDashboardRepository();
      mockRepo.dashboardDataResult = DashboardData.fromJson(
        sampleDashboardJson,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(
              () => StaticAuthNotifier(sampleCitizen),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      // Trigger post frame callback
      await tester.pump();
      await tester.pumpAndSettle();

      // Check User Greeting
      expect(find.text('Hello, Jane Doe 👋'), findsOneWidget);

      // Check Quick Action callout
      expect(find.text('Found an illegal dump?'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);

      // Check Hero Card Total Reports
      expect(find.text('Total Reports Submitted'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);

      // Check Status Cards
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);

      // Check Recent Report Item
      expect(find.text('Plastic bags on sidewalk'), findsOneWidget);
      expect(find.text('Plastic Waste'), findsWidgets);
    });

    testWidgets('Renders empty state when user has 0 reports', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockDashboardRepository();
      mockRepo.dashboardDataResult = const DashboardData(
        totalReports: 0,
        pendingReports: 0,
        inProgressReports: 0,
        completedReports: 0,
        rejectedReports: 0,
        latestReports: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(
              () => StaticAuthNotifier(sampleCitizen),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('No Waste Reports Yet'), findsOneWidget);
      expect(find.text('Report Waste Now'), findsOneWidget);
    });

    testWidgets('Renders error state with retry button on API failure', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockDashboardRepository();
      mockRepo.dashboardException = const NetworkException(
        message: 'Network connection failed.',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(
              () => StaticAuthNotifier(sampleCitizen),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Dashboard'), findsOneWidget);
      expect(find.text('Network connection failed.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Tap Try Again and verify retry request is invoked
      mockRepo.dashboardException = null;
      mockRepo.dashboardDataResult = DashboardData.fromJson(
        sampleDashboardJson,
      );
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Total Reports Submitted'), findsOneWidget);
    });
  });
}
