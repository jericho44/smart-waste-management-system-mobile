import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../dashboard/presentation/state/dashboard_notifier.dart';
import '../../data/repositories/report_repository.dart';
import '../../domain/models/status_history_item.dart';
import '../../domain/models/waste_report.dart';
import 'report_details_state.dart';
import 'reports_list_notifier.dart';

/// Notifier managing single report details, status timeline, and deletion.
class ReportDetailsNotifier extends Notifier<ReportDetailsState> {
  ReportDetailsNotifier(this.reportUuid);

  final String reportUuid;
  late final ReportRepository _repository;

  @override
  ReportDetailsState build() {
    _repository = ref.watch(reportRepositoryProvider);
    return ReportDetailsState.initial();
  }

  /// Fetch full report details and status timeline concurrently
  Future<void> loadDetails() async {
    state = state.copyWith(status: ReportDetailsStatus.loading);

    try {
      final reportFuture = _repository.getReportDetails(reportUuid);
      final historyFuture = _repository.getReportHistory(reportUuid);

      final results = await Future.wait([reportFuture, historyFuture]);
      if (!ref.mounted) return;
      final report = results[0] as WasteReport;
      final history = results[1] as List<StatusHistoryItem>;

      state = state.copyWith(
        status: ReportDetailsStatus.success,
        report: report,
        history: history,
        errorMessage: null,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: ReportDetailsStatus.error,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: ReportDetailsStatus.error,
        errorMessage: 'Failed to load report details. Please try again.',
      );
    }
  }

  /// Delete the report according to policy (status == PENDING)
  Future<bool> deleteReport() async {
    state = state.copyWith(status: ReportDetailsStatus.deleting);

    try {
      await _repository.deleteReport(reportUuid);
      if (!ref.mounted) return true;

      // Refresh list notifier and dashboard
      ref.read(reportsListNotifierProvider.notifier).loadReports(refresh: true);
      ref.read(dashboardNotifierProvider.notifier).loadDashboard(refresh: true);

      state = state.copyWith(status: ReportDetailsStatus.deleted);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: ReportDetailsStatus.success,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: ReportDetailsStatus.success,
        errorMessage: 'Unable to delete report. Please try again.',
      );
      return false;
    }
  }
}

/// Riverpod family provider for ReportDetailsNotifier
final reportDetailsNotifierProvider =
    NotifierProvider.family<ReportDetailsNotifier, ReportDetailsState, String>(
      ReportDetailsNotifier.new,
    );
