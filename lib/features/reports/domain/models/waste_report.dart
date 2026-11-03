import '../../../../core/constants/app_constants.dart';
import 'report_image.dart';
import 'status_history_item.dart';
import 'waste_category.dart';

/// Full domain model representing a waste issue report.
class WasteReport {
  final String uuid;
  final String title;
  final String description;
  final String status;
  final double latitude;
  final double longitude;
  final String? address;
  final WasteCategory? category;
  final List<ReportImage> images;
  final List<StatusHistoryItem> statusHistories;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WasteReport({
    required this.uuid,
    required this.title,
    required this.description,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.address,
    this.category,
    this.images = const [],
    this.statusHistories = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == AppConstants.statusPending;
  bool get isInProgress => status == AppConstants.statusInProgress;
  bool get isCompleted => status == AppConstants.statusCompleted;
  bool get isRejected => status == AppConstants.statusRejected;

  /// Business rule from WasteReportPolicy:
  /// Citizens can only modify or delete their report while it is still PENDING.
  bool get canBeEditedOrDeleted => isPending;

  /// Get the primary thumbnail URL (first image or null)
  String? get primaryImageUrl => images.isNotEmpty ? images.first.url : null;

  factory WasteReport.fromJson(Map<String, dynamic> json) {
    WasteCategory? category;
    if (json['category'] is Map<String, dynamic>) {
      category = WasteCategory.fromJson(
        json['category'] as Map<String, dynamic>,
      );
    }

    final imagesList =
        (json['images'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(ReportImage.fromJson)
            .toList() ??
        const [];

    final historiesList =
        (json['status_histories'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(StatusHistoryItem.fromJson)
            .toList() ??
        const [];

    return WasteReport(
      uuid: json['uuid'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Report',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? AppConstants.statusPending,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String?,
      category: category,
      images: imagesList,
      statusHistories: historiesList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'title': title,
    'description': description,
    'status': status,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'category': category?.toJson(),
    'images': images.map((i) => i.toJson()).toList(),
    'status_histories': statusHistories.map((h) => h.toJson()).toList(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
