import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/models/api_response.dart';
import '../../domain/models/status_history_item.dart';
import '../../domain/models/waste_category.dart';
import '../../domain/models/waste_report.dart';

/// Repository managing report retrieval, filtering, timeline history, and deletion.
class ReportRepository {
  final ApiClient apiClient;

  ReportRepository({required this.apiClient});

  /// Fetch paginated list of user reports with optional filters
  Future<ApiResponse<List<WasteReport>>> getReports({
    int page = 1,
    int perPage = 10,
    String? search,
    String? status,
    String? categoryUuid,
    String sort = 'created_at',
    String order = 'desc',
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      'sort': sort,
      'order': order,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (categoryUuid != null && categoryUuid.isNotEmpty)
        'category_uuid': categoryUuid,
    };

    return apiClient.get<List<WasteReport>>(
      ApiEndpoints.reports,
      queryParameters: query,
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(WasteReport.fromJson)
              .toList();
        }
        return const [];
      },
    );
  }

  /// Retrieve full details of a specific report by UUID
  Future<WasteReport> getReportDetails(String uuid) async {
    final response = await apiClient.get<WasteReport>(
      ApiEndpoints.reportDetails(uuid),
      fromJson: (json) => WasteReport.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  /// Retrieve the audit status history timeline of a report
  Future<List<StatusHistoryItem>> getReportHistory(String uuid) async {
    final response = await apiClient.get<List<StatusHistoryItem>>(
      ApiEndpoints.reportHistory(uuid),
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(StatusHistoryItem.fromJson)
              .toList();
        }
        return const [];
      },
    );
    return response.data ?? const [];
  }

  /// Delete a report if permitted by backend policy (status == PENDING)
  Future<void> deleteReport(String uuid) async {
    await apiClient.delete<dynamic>(ApiEndpoints.reportDelete(uuid));
  }

  /// Fetch all active waste categories for filtering & form selection
  Future<List<WasteCategory>> getCategories() async {
    final response = await apiClient.get<List<WasteCategory>>(
      ApiEndpoints.categories,
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(WasteCategory.fromJson)
              .toList();
        }
        return const [];
      },
    );
    return response.data ?? const [];
  }
}

/// Riverpod provider for ReportRepository
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportRepository(apiClient: apiClient);
});

/// Riverpod FutureProvider for active waste categories
final wasteCategoriesProvider = FutureProvider<List<WasteCategory>>((ref) {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getCategories();
});
