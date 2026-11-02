import '../../../../core/constants/app_constants.dart';

/// Lightweight summary model of a recent report on the dashboard.
class DashboardReportItem {
  final String uuid;
  final String title;
  final String description;
  final String status;
  final String categoryName;
  final String? imageUrl;
  final String? address;
  final DateTime? createdAt;

  const DashboardReportItem({
    required this.uuid,
    required this.title,
    required this.description,
    required this.status,
    required this.categoryName,
    this.imageUrl,
    this.address,
    this.createdAt,
  });

  bool get isPending => status == AppConstants.statusPending;
  bool get isInProgress => status == AppConstants.statusInProgress;
  bool get isCompleted => status == AppConstants.statusCompleted;
  bool get isRejected => status == AppConstants.statusRejected;

  factory DashboardReportItem.fromJson(Map<String, dynamic> json) {
    // Extract category name
    String categoryName = 'General';
    if (json['category'] is Map<String, dynamic>) {
      categoryName =
          (json['category'] as Map<String, dynamic>)['name'] as String? ??
          'General';
    }

    // Extract primary image url if available
    String? imageUrl;
    if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      final firstImg = (json['images'] as List).first;
      if (firstImg is Map<String, dynamic>) {
        imageUrl = firstImg['url'] as String?;
      }
    }

    return DashboardReportItem(
      uuid: json['uuid'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Report',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? AppConstants.statusPending,
      categoryName: categoryName,
      imageUrl: imageUrl,
      address: json['address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'title': title,
    'description': description,
    'status': status,
    'category_name': categoryName,
    'image_url': imageUrl,
    'address': address,
    'created_at': createdAt?.toIso8601String(),
  };
}
