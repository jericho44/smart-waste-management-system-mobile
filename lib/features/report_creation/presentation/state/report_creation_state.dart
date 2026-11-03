import 'package:image_picker/image_picker.dart';

import '../../../reports/domain/models/waste_category.dart';
import '../../../reports/domain/models/waste_report.dart';

/// Overall state of the report creation workflow.
enum ReportCreationStatus {
  initial,
  loadingCategories,
  ready,
  submitting,
  success,
  error,
}

/// GPS location acquisition status.
enum LocationStatus {
  idle,
  acquiring,
  acquired,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  error,
}

class ReportCreationState {
  final ReportCreationStatus status;
  final LocationStatus locationStatus;
  final List<WasteCategory> categories;
  final WasteCategory? selectedCategory;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final String? locationErrorMessage;
  final List<XFile> images;
  final double uploadProgress;
  final Map<String, String> fieldErrors;
  final String? errorMessage;
  final WasteReport? createdReport;

  const ReportCreationState({
    required this.status,
    required this.locationStatus,
    this.categories = const [],
    this.selectedCategory,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.locationErrorMessage,
    this.images = const [],
    this.uploadProgress = 0.0,
    this.fieldErrors = const {},
    this.errorMessage,
    this.createdReport,
  });

  factory ReportCreationState.initial() => const ReportCreationState(
    status: ReportCreationStatus.initial,
    locationStatus: LocationStatus.idle,
  );

  bool get isSubmitting => status == ReportCreationStatus.submitting;
  bool get isAcquiringLocation => locationStatus == LocationStatus.acquiring;
  bool get hasLocation => latitude != null && longitude != null;
  bool get hasImages => images.isNotEmpty;
  bool get canSubmit => !isSubmitting && !isAcquiringLocation;

  String? errorFor(String field) => fieldErrors[field];

  ReportCreationState copyWith({
    ReportCreationStatus? status,
    LocationStatus? locationStatus,
    List<WasteCategory>? categories,
    WasteCategory? selectedCategory,
    bool clearSelectedCategory = false,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    String? locationErrorMessage,
    bool clearLocationError = false,
    List<XFile>? images,
    double? uploadProgress,
    Map<String, String>? fieldErrors,
    String? errorMessage,
    bool clearErrorMessage = false,
    WasteReport? createdReport,
  }) {
    return ReportCreationState(
      status: status ?? this.status,
      locationStatus: locationStatus ?? this.locationStatus,
      categories: categories ?? this.categories,
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
      locationErrorMessage: clearLocationError
          ? null
          : (locationErrorMessage ?? this.locationErrorMessage),
      images: images ?? this.images,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      createdReport: createdReport ?? this.createdReport,
    );
  }
}
