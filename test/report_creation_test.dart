import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_waste_mobile/app/config/app_config.dart';
import 'package:smart_waste_mobile/core/constants/app_constants.dart';
import 'package:smart_waste_mobile/core/errors/app_exception.dart';
import 'package:smart_waste_mobile/core/network/api_client.dart';
import 'package:smart_waste_mobile/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:smart_waste_mobile/features/dashboard/domain/models/dashboard_data.dart';
import 'package:smart_waste_mobile/features/report_creation/data/repositories/report_creation_repository.dart';
import 'package:smart_waste_mobile/features/report_creation/domain/models/create_report_form_data.dart';
import 'package:smart_waste_mobile/features/report_creation/domain/services/location_service.dart';
import 'package:smart_waste_mobile/features/report_creation/presentation/screens/create_report_screen.dart';
import 'package:smart_waste_mobile/features/report_creation/presentation/state/report_creation_notifier.dart';
import 'package:smart_waste_mobile/features/report_creation/presentation/state/report_creation_state.dart';
import 'package:smart_waste_mobile/features/reports/data/repositories/report_repository.dart';
import 'package:smart_waste_mobile/features/reports/domain/models/status_history_item.dart';
import 'package:smart_waste_mobile/features/reports/domain/models/waste_category.dart';
import 'package:smart_waste_mobile/features/reports/domain/models/waste_report.dart';
import 'package:smart_waste_mobile/shared/models/api_response.dart';

// Mocks
class MockLocationService implements LocationService {
  bool serviceEnabled = true;
  LocationPermission currentPermission = LocationPermission.whileInUse;
  UserLocation? locationResult = const UserLocation(
    latitude: -6.2088,
    longitude: 106.8456,
    accuracy: 5.0,
  );
  Exception? locationException;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => currentPermission;

  @override
  Future<LocationPermission> requestPermission() async => currentPermission;

  @override
  Future<UserLocation> getCurrentLocation() async {
    if (locationException != null) throw locationException!;
    return locationResult!;
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}

class MockReportCreationRepository implements ReportCreationRepository {
  List<WasteCategory> categories = [
    const WasteCategory(
      uuid: 'cat-org-1',
      name: 'Organic Waste',
      slug: 'organic',
    ),
    const WasteCategory(
      uuid: 'cat-plas-2',
      name: 'Plastic Waste',
      slug: 'plastic',
    ),
  ];

  WasteReport? submitReportResult;
  Exception? submitException;
  bool submitCalled = false;
  CreateReportFormData? capturedFormData;

  @override
  Future<List<WasteCategory>> getCategories() async => categories;

  @override
  Future<WasteReport> submitReport(
    CreateReportFormData formData, {
    void Function(int sent, int total)? onProgress,
  }) async {
    submitCalled = true;
    capturedFormData = formData;

    if (onProgress != null) {
      onProgress(50, 100);
      onProgress(100, 100);
    }

    if (submitException != null) throw submitException!;
    return submitReportResult!;
  }
}

class MockReportListRepository implements ReportRepository {
  @override
  late final ApiClient apiClient;

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
      data: [],
    );
  }

  @override
  Future<WasteReport> getReportDetails(String uuid) =>
      throw UnimplementedError();

  @override
  Future<List<StatusHistoryItem>> getReportHistory(String uuid) async => [];

  @override
  Future<void> deleteReport(String uuid) async {}

  @override
  Future<List<WasteCategory>> getCategories() async => [];
}

class MockDashboardRepository implements DashboardRepository {
  @override
  late final ApiClient apiClient;

  @override
  Future<DashboardData> getUserDashboard() async {
    return const DashboardData(
      totalReports: 0,
      pendingReports: 0,
      inProgressReports: 0,
      completedReports: 0,
      rejectedReports: 0,
    );
  }
}

void main() {
  setUpAll(() async {
    await AppConfig.initialize();
  });

  final sampleCreatedReport = WasteReport(
    uuid: 'new-rep-uuid-123',
    title: 'Illegal Plastic Dumping',
    description: 'Found piles of single use plastics behind the market.',
    status: AppConstants.statusPending,
    latitude: -6.2088,
    longitude: 106.8456,
    address: 'Pasar Minggu',
    category: const WasteCategory(
      uuid: 'cat-plas-2',
      name: 'Plastic Waste',
      slug: 'plastic',
    ),
    createdAt: DateTime.now(),
  );

  group('CreateReportFormData Validation Tests', () {
    test(
      'Empty title, description, category and location fail validation',
      () async {
        const form = CreateReportFormData(
          title: '',
          description: '',
          categoryUuid: null,
          latitude: null,
          longitude: null,
        );

        final errors = await form.validate();
        expect(errors.containsKey('title'), isTrue);
        expect(errors.containsKey('description'), isTrue);
        expect(errors.containsKey('category_uuid'), isTrue);
        expect(errors.containsKey('location'), isTrue);
      },
    );

    test('Valid form data passes validation with 0 errors', () async {
      const form = CreateReportFormData(
        title: 'Dumped Garbage',
        description: 'Piles of domestic rubbish near sidewalk.',
        categoryUuid: 'cat-org-1',
        latitude: -6.1754,
        longitude: 106.8272,
        address: 'Monas Jakarta',
      );

      final errors = await form.validate();
      expect(errors.isEmpty, isTrue);
    });

    test('Excessive title or description length fails validation', () async {
      final form = CreateReportFormData(
        title: 'A' * 256,
        description: 'B' * 5001,
        categoryUuid: 'cat-org-1',
        latitude: 0.0,
        longitude: 0.0,
      );

      final errors = await form.validate();
      expect(errors['title'], contains('255'));
      expect(errors['description'], contains('5000'));
    });

    test('Excessive image count fails validation', () async {
      final sixImages = List.generate(
        6,
        (i) => XFile.fromData(Uint8List(10), name: 'test$i.jpg'),
      );
      final form = CreateReportFormData(
        title: 'Plastics dump',
        description: 'Desc',
        categoryUuid: 'cat-org-1',
        latitude: 0.0,
        longitude: 0.0,
        images: sixImages,
      );

      final errors = await form.validate();
      expect(errors['images'], contains('5'));
    });
  });

  group('ReportCreationNotifier State & Logic Tests', () {
    late MockReportCreationRepository mockRepo;
    late MockLocationService mockLocService;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockReportCreationRepository();
      mockLocService = MockLocationService();
      mockRepo.submitReportResult = sampleCreatedReport;

      container = ProviderContainer(
        overrides: [
          reportCreationRepositoryProvider.overrideWithValue(mockRepo),
          locationServiceProvider.overrideWithValue(mockLocService),
          reportRepositoryProvider.overrideWithValue(
            MockReportListRepository(),
          ),
          dashboardRepositoryProvider.overrideWithValue(
            MockDashboardRepository(),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initialize loads categories and coordinates', () async {
      final notifier = container.read(reportCreationNotifierProvider.notifier);
      await notifier.initialize();

      final state = container.read(reportCreationNotifierProvider);
      expect(state.categories.length, equals(2));
      expect(state.categories.first.name, equals('Organic Waste'));
      expect(state.locationStatus, equals(LocationStatus.acquired));
      expect(state.latitude, equals(-6.2088));
      expect(state.longitude, equals(106.8456));
    });

    test(
      'Handles GPS disabled state safely without crashing or fabricating',
      () async {
        mockLocService.serviceEnabled = false;

        final notifier = container.read(
          reportCreationNotifierProvider.notifier,
        );
        await notifier.fetchLocation();

        final state = container.read(reportCreationNotifierProvider);
        expect(state.locationStatus, equals(LocationStatus.serviceDisabled));
        expect(state.latitude, isNull);
        expect(state.longitude, isNull);
        expect(state.locationErrorMessage, contains('disabled'));
      },
    );

    test('Handles permission denied state', () async {
      mockLocService.currentPermission = LocationPermission.denied;

      final notifier = container.read(reportCreationNotifierProvider.notifier);
      await notifier.fetchLocation();

      final state = container.read(reportCreationNotifierProvider);
      expect(state.locationStatus, equals(LocationStatus.permissionDenied));
      expect(state.latitude, isNull);
    });

    test('Handles permission denied forever state', () async {
      mockLocService.currentPermission = LocationPermission.deniedForever;

      final notifier = container.read(reportCreationNotifierProvider.notifier);
      await notifier.fetchLocation();

      final state = container.read(reportCreationNotifierProvider);
      expect(
        state.locationStatus,
        equals(LocationStatus.permissionDeniedForever),
      );
      expect(state.latitude, isNull);
    });

    test(
      'submitReport validates client errors and halts submission if invalid',
      () async {
        final notifier = container.read(
          reportCreationNotifierProvider.notifier,
        );
        final result = await notifier.submitReport(title: '', description: '');

        expect(result, isNull);
        expect(mockRepo.submitCalled, isFalse);

        final state = container.read(reportCreationNotifierProvider);
        expect(state.fieldErrors.containsKey('title'), isTrue);
      },
    );

    test('submitReport succeeds, dispatches multipart data, and sets success state', () async {
      final notifier = container.read(reportCreationNotifierProvider.notifier);
      await notifier.initialize();
      notifier.selectCategory(mockRepo.categories.first);

      final result = await notifier.submitReport(
        title: 'Dumped Plastics in Alley',
        description: 'Large amount of non-biodegradable plastics.',
        address: 'Jl. Sudirman No. 10',
      );

      expect(result, isNotNull);
      expect(result?.title, equals('Illegal Plastic Dumping'));
      expect(mockRepo.submitCalled, isTrue);
      expect(
        mockRepo.capturedFormData?.title,
        equals('Dumped Plastics in Alley'),
      );

      final state = container.read(reportCreationNotifierProvider);
      expect(state.status, equals(ReportCreationStatus.success));
      expect(state.createdReport?.uuid, equals('new-rep-uuid-123'));
    });

    test('submitReport captures HTTP 422 ValidationException errors into fieldErrors', () async {
      mockRepo.submitException = const ValidationException(
        message: 'The given data was invalid.',
        errors: {
          'title': ['Title already exists.'],
          'category_uuid': ['Selected category is invalid.'],
        },
      );

      final notifier = container.read(reportCreationNotifierProvider.notifier);
      await notifier.initialize();
      notifier.selectCategory(mockRepo.categories.first);

      final result = await notifier.submitReport(
        title: 'Duplicate Title',
        description: 'Valid description text.',
      );

      expect(result, isNull);
      final state = container.read(reportCreationNotifierProvider);
      expect(state.fieldErrors['title'], equals('Title already exists.'));
      expect(
        state.fieldErrors['category_uuid'],
        equals('Selected category is invalid.'),
      );
    });
  });

  group('CreateReportScreen Widget Tests', () {
    testWidgets(
      'Renders all form fields, categories, image section, and location card',
      (WidgetTester tester) async {
        final mockRepo = MockReportCreationRepository();
        final mockLocService = MockLocationService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              reportCreationRepositoryProvider.overrideWithValue(mockRepo),
              locationServiceProvider.overrideWithValue(mockLocService),
              reportRepositoryProvider.overrideWithValue(
                MockReportListRepository(),
              ),
              dashboardRepositoryProvider.overrideWithValue(
                MockDashboardRepository(),
              ),
            ],
            child: const MaterialApp(home: CreateReportScreen()),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        // Verify Header
        expect(find.text('Create Waste Report'), findsOneWidget);
        expect(find.text('Report Waste Incident'), findsOneWidget);

        // Verify Fields
        expect(find.text('Report Title'), findsOneWidget);
        expect(find.text('Waste Category'), findsOneWidget);
        expect(find.text('Detailed Description'), findsOneWidget);
        expect(find.text('Waste Photos'), findsOneWidget);
        expect(find.text('GPS Location'), findsOneWidget);
        expect(find.text('Submit Report'), findsOneWidget);

        // Verify camera and gallery buttons
        expect(find.text('Camera'), findsOneWidget);
        expect(find.text('Gallery'), findsOneWidget);

        // Verify coordinates acquired from mock
        expect(find.text('Coordinates Acquired'), findsOneWidget);
        expect(find.textContaining('Latitude: -6.208800'), findsOneWidget);
        expect(find.textContaining('Longitude: 106.845600'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping submit with empty inputs triggers validation error highlights',
      (WidgetTester tester) async {
        final mockRepo = MockReportCreationRepository();
        final mockLocService = MockLocationService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              reportCreationRepositoryProvider.overrideWithValue(mockRepo),
              locationServiceProvider.overrideWithValue(mockLocService),
              reportRepositoryProvider.overrideWithValue(
                MockReportListRepository(),
              ),
              dashboardRepositoryProvider.overrideWithValue(
                MockDashboardRepository(),
              ),
            ],
            child: const MaterialApp(home: CreateReportScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll to submit button and tap
        final submitButton = find.text('Submit Report');
        await tester.ensureVisible(submitButton);
        await tester.pumpAndSettle();
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Verification errors appear in form
        expect(
          find.text('Report title is required.', skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.text('Description is required.', skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.text('Please select a waste category.', skipOffstage: false),
          findsOneWidget,
        );
      },
    );
  });
}
