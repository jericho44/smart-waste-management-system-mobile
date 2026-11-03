import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

/// Notifier managing dashboard statistics fetching, pull-to-refresh, and error recovery.
class DashboardNotifier extends Notifier<DashboardState> {
  late final DashboardRepository _repository;

  @override
  DashboardState build() {
    _repository = ref.watch(dashboardRepositoryProvider);
    return DashboardState.initial();
  }

  /// Load dashboard data from the API
  Future<void> loadDashboard({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isRefreshing: true);
    } else if (state.data == null) {
      state = DashboardState.loading(existingData: state.data);
    }

    try {
      final dashboardData = await _repository.getUserDashboard();
      if (!ref.mounted) return;
      state = DashboardState.success(dashboardData);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = DashboardState.error(e.message, existingData: state.data);
    } catch (e) {
      if (!ref.mounted) return;
      state = DashboardState.error(
        'Unable to load dashboard data. Please try again.',
        existingData: state.data,
      );
    }
  }
}

/// Riverpod provider for DashboardNotifier
final dashboardNotifierProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);
