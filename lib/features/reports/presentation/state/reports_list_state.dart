import '../../domain/models/waste_report.dart';

enum ReportsListStatus { initial, loading, success, error }

/// State representation of the paginated, filtered report list.
class ReportsListState {
  final ReportsListStatus status;
  final List<WasteReport> reports;
  final int currentPage;
  final int lastPage;
  final bool hasNextPage;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String searchQuery;
  final String? selectedStatus;
  final String? selectedCategoryUuid;
  final String? errorMessage;

  const ReportsListState({
    required this.status,
    this.reports = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.hasNextPage = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.searchQuery = '',
    this.selectedStatus,
    this.selectedCategoryUuid,
    this.errorMessage,
  });

  factory ReportsListState.initial() =>
      const ReportsListState(status: ReportsListStatus.initial);

  bool get isLoading => status == ReportsListStatus.loading && reports.isEmpty;
  bool get isEmpty => status == ReportsListStatus.success && reports.isEmpty;
  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedStatus != null ||
      selectedCategoryUuid != null;

  ReportsListState copyWith({
    ReportsListStatus? status,
    List<WasteReport>? reports,
    int? currentPage,
    int? lastPage,
    bool? hasNextPage,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? searchQuery,
    String? selectedStatus,
    String? selectedCategoryUuid,
    String? errorMessage,
    bool clearStatus = false,
    bool clearCategory = false,
  }) {
    return ReportsListState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: clearStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      selectedCategoryUuid: clearCategory
          ? null
          : (selectedCategoryUuid ?? this.selectedCategoryUuid),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
