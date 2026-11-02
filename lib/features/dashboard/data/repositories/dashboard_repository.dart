import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/dashboard_data.dart';

/// Repository for retrieving citizen dashboard metrics and recent submissions.
class DashboardRepository {
  final ApiClient apiClient;

  DashboardRepository({required this.apiClient});

  /// Fetch dashboard statistics and recent reports from GET /dashboard/user
  Future<DashboardData> getUserDashboard() async {
    final response = await apiClient.get<DashboardData>(
      ApiEndpoints.userDashboard,
      fromJson: (json) => DashboardData.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }
}

/// Riverpod provider for DashboardRepository
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRepository(apiClient: apiClient);
});
