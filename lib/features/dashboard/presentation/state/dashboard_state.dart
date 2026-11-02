import '../../domain/models/dashboard_data.dart';

enum DashboardStatus { initial, loading, success, error }

/// State representation of the citizen dashboard.
class DashboardState {
  final DashboardStatus status;
  final DashboardData? data;
  final String? errorMessage;
  final bool isRefreshing;

  const DashboardState({
    required this.status,
    this.data,
    this.errorMessage,
    this.isRefreshing = false,
  });

  factory DashboardState.initial() =>
      const DashboardState(status: DashboardStatus.initial);

  factory DashboardState.loading({DashboardData? existingData}) =>
      DashboardState(status: DashboardStatus.loading, data: existingData);

  factory DashboardState.success(DashboardData data) =>
      DashboardState(status: DashboardStatus.success, data: data);

  factory DashboardState.error(String message, {DashboardData? existingData}) =>
      DashboardState(
        status: DashboardStatus.error,
        errorMessage: message,
        data: existingData,
      );

  bool get isLoading => status == DashboardStatus.loading && data == null;
  bool get isSuccess => status == DashboardStatus.success;
  bool get isError => status == DashboardStatus.error;
  bool get isEmpty => data != null && !data!.hasReports;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardData? data,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return DashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}
