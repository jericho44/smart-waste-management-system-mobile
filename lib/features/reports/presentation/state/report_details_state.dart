import '../../domain/models/status_history_item.dart';
import '../../domain/models/waste_report.dart';

enum ReportDetailsStatus { initial, loading, success, error, deleting, deleted }

/// State representation for single report details and audit trail.
class ReportDetailsState {
  final ReportDetailsStatus status;
  final WasteReport? report;
  final List<StatusHistoryItem> history;
  final String? errorMessage;

  const ReportDetailsState({
    required this.status,
    this.report,
    this.history = const [],
    this.errorMessage,
  });

  factory ReportDetailsState.initial() =>
      const ReportDetailsState(status: ReportDetailsStatus.initial);

  bool get isLoading => status == ReportDetailsStatus.loading;
  bool get isDeleting => status == ReportDetailsStatus.deleting;
  bool get isDeleted => status == ReportDetailsStatus.deleted;

  ReportDetailsState copyWith({
    ReportDetailsStatus? status,
    WasteReport? report,
    List<StatusHistoryItem>? history,
    String? errorMessage,
  }) {
    return ReportDetailsState(
      status: status ?? this.status,
      report: report ?? this.report,
      history: history ?? this.history,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
