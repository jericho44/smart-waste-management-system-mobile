import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../dashboard/presentation/state/dashboard_notifier.dart';
import '../../data/repositories/report_repository.dart';
import 'reports_list_state.dart';

/// Notifier managing reports pagination, filters, search, and deletion.
class ReportsListNotifier extends Notifier<ReportsListState> {
  late final ReportRepository _repository;

  @override
  ReportsListState build() {
    _repository = ref.watch(reportRepositoryProvider);
    return ReportsListState.initial();
  }

  /// Load initial page of reports with active filters
  Future<void> loadReports({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isRefreshing: true);
    } else if (state.reports.isEmpty) {
      state = state.copyWith(status: ReportsListStatus.loading);
    }

    try {
      final response = await _repository.getReports(
        page: 1,
        search: state.searchQuery,
        status: state.selectedStatus,
        categoryUuid: state.selectedCategoryUuid,
      );

      final pagination = response.meta?.pagination;
      final reports = response.data ?? [];

      state = state.copyWith(
        status: ReportsListStatus.success,
        reports: reports,
        currentPage: pagination?.currentPage ?? 1,
        lastPage: pagination?.lastPage ?? 1,
        hasNextPage: pagination?.hasNext ?? false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: null,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: ReportsListStatus.error,
        errorMessage: e.message,
        isRefreshing: false,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(
        status: ReportsListStatus.error,
        errorMessage: 'Failed to load reports. Please try again.',
        isRefreshing: false,
        isLoadingMore: false,
      );
    }
  }

  /// Load subsequent page for infinite scroll
  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasNextPage) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final response = await _repository.getReports(
        page: nextPage,
        search: state.searchQuery,
        status: state.selectedStatus,
        categoryUuid: state.selectedCategoryUuid,
      );

      final pagination = response.meta?.pagination;
      final newReports = response.data ?? [];

      state = state.copyWith(
        reports: [...state.reports, ...newReports],
        currentPage: pagination?.currentPage ?? nextPage,
        lastPage: pagination?.lastPage ?? state.lastPage,
        hasNextPage: pagination?.hasNext ?? false,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Update search query and trigger search reload
  void setSearch(String query) {
    if (state.searchQuery == query.trim()) return;
    state = state.copyWith(searchQuery: query.trim());
    loadReports();
  }

  /// Filter reports by status
  void setStatusFilter(String? status) {
    if (state.selectedStatus == status) {
      // Toggle off
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(selectedStatus: status);
    }
    loadReports();
  }

  /// Filter reports by category
  void setCategoryFilter(String? categoryUuid) {
    if (state.selectedCategoryUuid == categoryUuid) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryUuid: categoryUuid);
    }
    loadReports();
  }

  /// Delete report and synchronize local state + dashboard metrics
  Future<bool> deleteReport(String uuid) async {
    try {
      await _repository.deleteReport(uuid);
      if (!ref.mounted) return true;
      // Remove deleted report from active list
      final updatedList = state.reports.where((r) => r.uuid != uuid).toList();
      state = state.copyWith(reports: updatedList);

      // Refresh dashboard counters
      ref.read(dashboardNotifierProvider.notifier).loadDashboard(refresh: true);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Riverpod provider for ReportsListNotifier
final reportsListNotifierProvider =
    NotifierProvider<ReportsListNotifier, ReportsListState>(
      ReportsListNotifier.new,
    );
