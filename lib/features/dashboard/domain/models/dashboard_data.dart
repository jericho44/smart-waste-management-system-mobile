import 'category_stat.dart';
import 'dashboard_report_item.dart';

/// Aggregated user dashboard data returned from GET /dashboard/user.
class DashboardData {
  final int totalReports;
  final int pendingReports;
  final int inProgressReports;
  final int completedReports;
  final int rejectedReports;
  final List<CategoryStat> reportsByCategory;
  final List<DashboardReportItem> latestReports;

  const DashboardData({
    required this.totalReports,
    required this.pendingReports,
    required this.inProgressReports,
    required this.completedReports,
    required this.rejectedReports,
    this.reportsByCategory = const [],
    this.latestReports = const [],
  });

  bool get hasReports => totalReports > 0;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final categoriesRaw = json['reports_by_category'] as List<dynamic>? ?? [];
    final reportsRaw = json['latest_reports'] as List<dynamic>? ?? [];

    return DashboardData(
      totalReports: json['total_reports'] as int? ?? 0,
      pendingReports: json['pending_reports'] as int? ?? 0,
      inProgressReports: json['in_progress_reports'] as int? ?? 0,
      completedReports: json['completed_reports'] as int? ?? 0,
      rejectedReports: json['rejected_reports'] as int? ?? 0,
      reportsByCategory: categoriesRaw
          .whereType<Map<String, dynamic>>()
          .map(CategoryStat.fromJson)
          .toList(),
      latestReports: reportsRaw
          .whereType<Map<String, dynamic>>()
          .map(DashboardReportItem.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'total_reports': totalReports,
    'pending_reports': pendingReports,
    'in_progress_reports': inProgressReports,
    'completed_reports': completedReports,
    'rejected_reports': rejectedReports,
    'reports_by_category': reportsByCategory.map((c) => c.toJson()).toList(),
    'latest_reports': latestReports.map((r) => r.toJson()).toList(),
  };
}
