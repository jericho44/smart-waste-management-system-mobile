import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_mobile/app/config/app_config.dart';
import 'package:smart_waste_mobile/core/constants/app_constants.dart';
import 'package:smart_waste_mobile/core/errors/app_exception.dart';
import 'package:smart_waste_mobile/core/network/api_client.dart';
import 'package:smart_waste_mobile/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:smart_waste_mobile/features/dashboard/domain/models/dashboard_data.dart';
import 'package:smart_waste_mobile/features/reports/data/repositories/report_repository.dart';
import 'package:smart_waste_mobile/features/reports/domain/models/report_image.dart';
import 'package:smart_waste_mobile/features/reports/domain/models/status_history_item.dart';
import 'package:smart_waste_mobile/features/reports/domain/models/waste_category.dart';
import 'package:smart_waste_mobile/features/reports/domain/models/waste_report.dart';
import 'package:smart_waste_mobile/features/reports/presentation/screens/report_details_screen.dart';
import 'package:smart_waste_mobile/features/reports/presentation/screens/reports_screen.dart';
import 'package:smart_waste_mobile/features/reports/presentation/state/report_details_notifier.dart';
import 'package:smart_waste_mobile/features/reports/presentation/state/report_details_state.dart';
import 'package:smart_waste_mobile/features/reports/presentation/state/reports_list_notifier.dart';
import 'package:smart_waste_mobile/features/reports/presentation/state/reports_list_state.dart';
import 'package:smart_waste_mobile/shared/models/api_response.dart';

class MockReportRepository implements ReportRepository {
  @override
  late final ApiClient apiClient;

  ApiResponse<List<WasteReport>>? getReportsResult;
  Exception? getReportsException;
  WasteReport? getReportDetailsResult;
  Exception? getReportDetailsException;
  List<StatusHistoryItem> getReportHistoryResult = [];
  bool deleteReportCalled = false;
  List<WasteCategory> categoriesResult = [];

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
    if (getReportsException != null) throw getReportsException!;
    return getReportsResult!;
  }

  @override
  Future<WasteReport> getReportDetails(String uuid) async {
    if (getReportDetailsException != null) throw getReportDetailsException!;
    return getReportDetailsResult!;
  }

  @override
  Future<List<StatusHistoryItem>> getReportHistory(String uuid) async {
    return getReportHistoryResult;
  }

  @override
  Future<void> deleteReport(String uuid) async {
    deleteReportCalled = true;
  }

  @override
  Future<List<WasteCategory>> getCategories() async {
    return categoriesResult;
  }
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

  const sampleCategory = WasteCategory(
    uuid: 'cat-123',
    name: 'Plastic Waste',
    slug: 'plastic',
  );

  const sampleImage = ReportImage(
    uuid: 'img-123',
    url: 'http://127.0.0.1:8000/storage/reports/waste.jpg',
    originalFilename: 'waste.jpg',
  );

  final sampleHistory = StatusHistoryItem(
    uuid: 'hist-1',
    oldStatus: null,
    newStatus: AppConstants.statusPending,
    notes: 'Citizen submitted report',
    changedByName: 'Citizen User',
    createdAt: DateTime(2026, 11, 2, 10, 0),
  );

  final samplePendingReport = WasteReport(
    uuid: 'rep-pending-1',
    title: 'Plastic Bottle Dump',
    description: 'Multiple plastic bottles on sidewalk',
    status: AppConstants.statusPending,
    latitude: -6.2088,
    longitude: 106.8456,
    address: 'Jl. Merdeka No. 5',
    category: sampleCategory,
    images: [sampleImage],
    statusHistories: [sampleHistory],
    createdAt: DateTime(2026, 11, 2, 10, 0),
  );

  final sampleInProgressReport = WasteReport(
    uuid: 'rep-inprogress-2',
    title: 'Trash Piles In Progress',
    description: 'Cleaners on the way',
    status: AppConstants.statusInProgress,
    latitude: -6.2088,
    longitude: 106.8456,
    category: sampleCategory,
    createdAt: DateTime(2026, 11, 2, 11, 0),
  );

  group('Waste Report Domain Model & Policy Tests', () {
    test('JSON deserialization correctly maps all nested entities', () {
      final json = {
        'uuid': 'rep-test',
        'title': 'Test Report',
        'description': 'Test description',
        'status': 'PENDING',
        'latitude': -6.1754,
        'longitude': 106.8272,
        'address': 'Monas Jakarta',
        'category': {'uuid': 'cat-1', 'name': 'Organic', 'slug': 'organic'},
        'images': [
          {'uuid': 'img-1', 'url': 'http://127.0.0.1:8000/sample.jpg'},
        ],
        'status_histories': [
          {
            'uuid': 'hist-1',
            'old_status': null,
            'new_status': 'PENDING',
            'notes': 'Submitted',
            'changed_by': {'name': 'John'},
          },
        ],
        'created_at': '2026-11-02T10:00:00Z',
      };

      final report = WasteReport.fromJson(json);

      expect(report.uuid, equals('rep-test'));
      expect(report.title, equals('Test Report'));
      expect(report.category?.name, equals('Organic'));
      expect(report.images.length, equals(1));
      expect(report.statusHistories.length, equals(1));
      expect(report.isPending, isTrue);
      expect(report.canBeEditedOrDeleted, isTrue);
    });

    test(
      'WasteReportPolicy restriction: only PENDING reports can be deleted',
      () {
        expect(samplePendingReport.canBeEditedOrDeleted, isTrue);
        expect(sampleInProgressReport.canBeEditedOrDeleted, isFalse);

        final completedReport = WasteReport(
          uuid: 'rep-3',
          title: 'Resolved Waste',
          description: '',
          status: AppConstants.statusCompleted,
          latitude: 0,
          longitude: 0,
        );
        expect(completedReport.canBeEditedOrDeleted, isFalse);

        final rejectedReport = WasteReport(
          uuid: 'rep-4',
          title: 'Spam Report',
          description: '',
          status: AppConstants.statusRejected,
          latitude: 0,
          longitude: 0,
        );
        expect(rejectedReport.canBeEditedOrDeleted, isFalse);
      },
    );
  });

  group('ReportsListNotifier State & Pagination Tests', () {
    late MockReportRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockReportRepository();
      container = ProviderContainer(
        overrides: [
          reportRepositoryProvider.overrideWithValue(mockRepo),
          dashboardRepositoryProvider.overrideWithValue(
            MockDashboardRepository(),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('loadReports fetches page 1 and sets success state', () async {
      mockRepo.getReportsResult = ApiResponse<List<WasteReport>>(
        success: true,
        message: 'Reports retrieved',
        data: [samplePendingReport, sampleInProgressReport],
        meta: const ApiMeta(
          pagination: PaginationMeta(
            currentPage: 1,
            lastPage: 2,
            perPage: 10,
            total: 12,
            from: 1,
            to: 2,
            hasNext: true,
            hasPrevious: false,
          ),
        ),
      );

      final notifier = container.read(reportsListNotifierProvider.notifier);
      await notifier.loadReports();

      final state = container.read(reportsListNotifierProvider);
      expect(state.status, equals(ReportsListStatus.success));
      expect(state.reports.length, equals(2));
      expect(state.currentPage, equals(1));
      expect(state.hasNextPage, isTrue);
    });

    test(
      'loadNextPage appends subsequent reports without wiping page 1',
      () async {
        mockRepo.getReportsResult = ApiResponse<List<WasteReport>>(
          success: true,
          message: 'Reports retrieved',
          data: [samplePendingReport],
          meta: const ApiMeta(
            pagination: PaginationMeta(
              currentPage: 1,
              lastPage: 2,
              perPage: 10,
              total: 2,
              from: 1,
              to: 1,
              hasNext: true,
              hasPrevious: false,
            ),
          ),
        );

        final notifier = container.read(reportsListNotifierProvider.notifier);
        await notifier.loadReports();

        // Setup page 2 response
        mockRepo.getReportsResult = ApiResponse<List<WasteReport>>(
          success: true,
          message: 'Reports retrieved',
          data: [sampleInProgressReport],
          meta: const ApiMeta(
            pagination: PaginationMeta(
              currentPage: 2,
              lastPage: 2,
              perPage: 10,
              total: 2,
              from: 2,
              to: 2,
              hasNext: false,
              hasPrevious: true,
            ),
          ),
        );

        await notifier.loadNextPage();

        final state = container.read(reportsListNotifierProvider);
        expect(state.reports.length, equals(2));
        expect(state.currentPage, equals(2));
        expect(state.hasNextPage, isFalse);
      },
    );

    test('setStatusFilter toggles and filters reports', () async {
      mockRepo.getReportsResult = ApiResponse<List<WasteReport>>(
        success: true,
        message: 'OK',
        data: [samplePendingReport],
      );

      final notifier = container.read(reportsListNotifierProvider.notifier);
      notifier.setStatusFilter(AppConstants.statusPending);

      final state = container.read(reportsListNotifierProvider);
      expect(state.selectedStatus, equals(AppConstants.statusPending));
    });

    test('deleteReport removes report from list state', () async {
      mockRepo.getReportsResult = ApiResponse<List<WasteReport>>(
        success: true,
        message: 'OK',
        data: [samplePendingReport, sampleInProgressReport],
      );

      final notifier = container.read(reportsListNotifierProvider.notifier);
      await notifier.loadReports();

      await notifier.deleteReport(samplePendingReport.uuid);

      expect(mockRepo.deleteReportCalled, isTrue);
      final state = container.read(reportsListNotifierProvider);
      expect(state.reports.length, equals(1));
      expect(state.reports.first.uuid, equals(sampleInProgressReport.uuid));
    });
  });

  group('ReportDetailsNotifier Tests', () {
    late ProviderContainer container;
    late MockReportRepository mockRepo;

    setUp(() {
      mockRepo = MockReportRepository();
      container = ProviderContainer(
        overrides: [
          reportRepositoryProvider.overrideWithValue(mockRepo),
          dashboardRepositoryProvider.overrideWithValue(
            MockDashboardRepository(),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loadDetails loads details and status history', () async {
      mockRepo.getReportDetailsResult = samplePendingReport;
      mockRepo.getReportHistoryResult = [sampleHistory];

      final notifier = container.read(
        reportDetailsNotifierProvider('rep-pending-1').notifier,
      );
      await notifier.loadDetails();

      final state = container.read(
        reportDetailsNotifierProvider('rep-pending-1'),
      );
      expect(state.status, equals(ReportDetailsStatus.success));
      expect(state.report?.uuid, equals('rep-pending-1'));
      expect(state.history.length, equals(1));
      expect(state.history.first.notes, equals('Citizen submitted report'));
    });

    test('loadDetails handles AppException properly', () async {
      mockRepo.getReportDetailsException = const NotFoundException(
        message: 'Report not found',
      );

      final notifier = container.read(
        reportDetailsNotifierProvider('non-existent').notifier,
      );
      await notifier.loadDetails();

      final state = container.read(
        reportDetailsNotifierProvider('non-existent'),
      );
      expect(state.status, equals(ReportDetailsStatus.error));
      expect(state.errorMessage, equals('Report not found'));
    });

    test(
      'deleteReport invokes repository and marks state as deleted',
      () async {
        mockRepo.getReportsResult = ApiResponse<List<WasteReport>>(
          success: true,
          message: 'OK',
          data: [],
        );

        final notifier = container.read(
          reportDetailsNotifierProvider('rep-pending-1').notifier,
        );
        final success = await notifier.deleteReport();

        expect(success, isTrue);
        expect(mockRepo.deleteReportCalled, isTrue);
        final state = container.read(
          reportDetailsNotifierProvider('rep-pending-1'),
        );
        expect(state.status, equals(ReportDetailsStatus.deleted));
      },
    );
  });

  group('Reports UI Widget Tests', () {
    testWidgets('ReportsScreen renders report cards and filter chips', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockReportRepository();
      mockRepo.getReportsResult = ApiResponse<List<WasteReport>>(
        success: true,
        message: 'OK',
        data: [samplePendingReport, sampleInProgressReport],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [reportRepositoryProvider.overrideWithValue(mockRepo)],
          child: const MaterialApp(home: ReportsScreen()),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Header & Filter chips
      expect(find.text('My Waste Reports'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('In Progress'), findsWidgets);

      // Report Cards
      expect(find.text('Plastic Bottle Dump'), findsOneWidget);
      expect(find.text('Trash Piles In Progress'), findsOneWidget);
      expect(find.text('Plastic Waste'), findsWidgets);
    });

    testWidgets(
      'ReportDetailsScreen renders map, image gallery, timeline, and delete button for pending report',
      (WidgetTester tester) async {
        final mockRepo = MockReportRepository();
        mockRepo.getReportDetailsResult = samplePendingReport;
        mockRepo.getReportHistoryResult = [sampleHistory];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [reportRepositoryProvider.overrideWithValue(mockRepo)],
            child: const MaterialApp(
              home: ReportDetailsScreen(uuid: 'rep-pending-1'),
            ),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        // Screen elements
        expect(find.text('Report Details'), findsOneWidget);
        expect(find.text('Plastic Bottle Dump'), findsOneWidget);
        expect(find.text('Waste Photos'), findsOneWidget);
        expect(find.text('Location Details'), findsOneWidget);
        expect(find.text('Resolution History & Timeline'), findsOneWidget);

        // Delete icon button present for PENDING status
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      },
    );

    testWidgets(
      'ReportDetailsScreen hides delete button for IN_PROGRESS report',
      (WidgetTester tester) async {
        final mockRepo = MockReportRepository();
        mockRepo.getReportDetailsResult = sampleInProgressReport;
        mockRepo.getReportHistoryResult = [sampleHistory];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [reportRepositoryProvider.overrideWithValue(mockRepo)],
            child: const MaterialApp(
              home: ReportDetailsScreen(uuid: 'rep-inprogress-2'),
            ),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        // Delete button must NOT be present
        expect(find.byIcon(Icons.delete_outline), findsNothing);

        // Policy lock message is displayed
        expect(
          find.text(
            'This report is currently under review or resolved and is locked against modifications.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
