import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../dashboard/presentation/state/dashboard_notifier.dart';
import '../../../reports/domain/models/waste_category.dart';
import '../../../reports/domain/models/waste_report.dart';
import '../../../reports/presentation/state/reports_list_notifier.dart';
import '../../data/repositories/report_creation_repository.dart';
import '../../domain/models/create_report_form_data.dart';
import '../../domain/services/location_service.dart';
import 'report_creation_state.dart';

/// Provider for ImagePicker to allow mocking in tests
final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

/// Notifier orchestrating the entire waste report creation lifecycle.
class ReportCreationNotifier extends Notifier<ReportCreationState> {
  late final ReportCreationRepository _repository;
  late final LocationService _locationService;
  late final ImagePicker _imagePicker;

  @override
  ReportCreationState build() {
    _repository = ref.watch(reportCreationRepositoryProvider);
    _locationService = ref.watch(locationServiceProvider);
    _imagePicker = ref.watch(imagePickerProvider);

    return ReportCreationState.initial();
  }

  /// Load categories and trigger initial GPS location acquisition.
  Future<void> initialize() async {
    state = state.copyWith(status: ReportCreationStatus.loadingCategories);

    try {
      final categories = await _repository.getCategories();
      if (!ref.mounted) return;

      state = state.copyWith(
        status: ReportCreationStatus.ready,
        categories: categories,
        clearErrorMessage: true,
      );

      // Acquire location immediately in background
      await fetchLocation();
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ReportCreationStatus.error,
        errorMessage: e.message,
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ReportCreationStatus.error,
        errorMessage: 'Failed to initialize report form. Please try again.',
      );
    }
  }

  /// Request permissions and obtain accurate device GPS coordinates.
  Future<void> fetchLocation({bool isRetry = false}) async {
    state = state.copyWith(
      locationStatus: LocationStatus.acquiring,
      clearLocationError: true,
    );

    try {
      final isServiceEnabled = await _locationService
          .isLocationServiceEnabled();
      if (!ref.mounted) return;

      if (!isServiceEnabled) {
        state = state.copyWith(
          locationStatus: LocationStatus.serviceDisabled,
          locationErrorMessage: 'Device location service (GPS) is disabled. Please turn on location in settings.',
        );
        return;
      }

      var permission = await _locationService.checkPermission();
      if (!ref.mounted) return;

      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestPermission();
        if (!ref.mounted) return;
      }

      if (permission == LocationPermission.denied) {
        state = state.copyWith(
          locationStatus: LocationStatus.permissionDenied,
          locationErrorMessage: 'Location permission is required to pinpoint the waste site for collection.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          locationStatus: LocationStatus.permissionDeniedForever,
          locationErrorMessage: 'Location permissions are permanently denied. Please enable them in App Settings.',
        );
        return;
      }

      // Permission granted: obtain coordinates
      final location = await _locationService.getCurrentLocation();
      if (!ref.mounted) return;

      // Clear any location error from field errors
      final updatedFieldErrors = Map<String, String>.from(state.fieldErrors)
        ..remove('location')
        ..remove('latitude')
        ..remove('longitude');

      state = state.copyWith(
        locationStatus: LocationStatus.acquired,
        latitude: location.latitude,
        longitude: location.longitude,
        locationAccuracy: location.accuracy,
        clearLocationError: true,
        fieldErrors: updatedFieldErrors,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        locationStatus: LocationStatus.error,
        locationErrorMessage: 'Unable to acquire current location. Please verify your GPS signal and tap Retry.',
      );
    }
  }

  /// Open application settings to allow permissions
  Future<bool> openAppSettings() => _locationService.openAppSettings();

  /// Open system location settings to turn on GPS
  Future<bool> openLocationSettings() =>
      _locationService.openLocationSettings();

  /// Select waste category
  void selectCategory(WasteCategory? category) {
    final updatedFieldErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('category_uuid');

    state = state.copyWith(
      selectedCategory: category,
      clearSelectedCategory: category == null,
      fieldErrors: updatedFieldErrors,
    );
  }

  /// Capture a single photo using camera
  Future<void> captureImageFromCamera() async {
    if (state.images.length >= CreateReportFormData.maxImages) {
      _setImageError(
        'Maximum of ${CreateReportFormData.maxImages} images allowed.',
      );
      return;
    }

    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo == null || !ref.mounted) return;

      final error = await _validateSingleImage(photo);
      if (error != null) {
        _setImageError(error);
        return;
      }

      final updatedImages = [...state.images, photo];
      final updatedFieldErrors = Map<String, String>.from(state.fieldErrors)
        ..remove('images');

      state = state.copyWith(
        images: updatedImages,
        fieldErrors: updatedFieldErrors,
      );
    } catch (_) {
      _setImageError('Failed to capture photo from camera.');
    }
  }

  /// Pick multiple images from photo gallery
  Future<void> pickImagesFromGallery() async {
    final currentCount = state.images.length;
    if (currentCount >= CreateReportFormData.maxImages) {
      _setImageError(
        'Maximum of ${CreateReportFormData.maxImages} images allowed.',
      );
      return;
    }

    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFiles.isEmpty || !ref.mounted) return;

      final remainingSlot = CreateReportFormData.maxImages - currentCount;
      final candidates = pickedFiles.take(remainingSlot).toList();

      final validFiles = <XFile>[];
      for (final file in candidates) {
        final err = await _validateSingleImage(file);
        if (err == null) {
          validFiles.add(file);
        } else {
          _setImageError(err);
          return;
        }
      }

      final updatedImages = [...state.images, ...validFiles];
      final updatedFieldErrors = Map<String, String>.from(state.fieldErrors)
        ..remove('images');

      state = state.copyWith(
        images: updatedImages,
        fieldErrors: updatedFieldErrors,
      );
    } catch (_) {
      _setImageError('Failed to pick images from gallery.');
    }
  }

  /// Remove selected image attachment
  void removeImage(int index) {
    if (index < 0 || index >= state.images.length) return;
    final updatedList = List<XFile>.from(state.images)..removeAt(index);
    state = state.copyWith(images: updatedList);
  }

  /// Submit waste report with full validation and duplicate tap prevention
  Future<WasteReport?> submitReport({
    required String title,
    required String description,
    String? address,
  }) async {
    // 1. Guard against duplicate submission during in-flight request
    if (state.isSubmitting) return null;

    final formData = CreateReportFormData(
      title: title,
      description: description,
      categoryUuid: state.selectedCategory?.uuid,
      latitude: state.latitude,
      longitude: state.longitude,
      address: address,
      images: state.images,
    );

    // 2. Perform client-side validation
    final validationErrors = await formData.validate();
    if (validationErrors.isNotEmpty) {
      state = state.copyWith(fieldErrors: validationErrors);
      return null;
    }

    // 3. Begin submission with progress indicator
    state = state.copyWith(
      status: ReportCreationStatus.submitting,
      uploadProgress: 0.05,
      fieldErrors: const {},
      clearErrorMessage: true,
    );

    try {
      final newReport = await _repository.submitReport(
        formData,
        onProgress: (sent, total) {
          if (!ref.mounted) return;
          if (total > 0) {
            final progress = (sent / total).clamp(0.0, 1.0);
            state = state.copyWith(uploadProgress: progress);
          }
        },
      );

      if (!ref.mounted) return newReport;

      // 4. Invalidate and refresh dependent states (reports list & dashboard stats)
      ref.read(reportsListNotifierProvider.notifier).loadReports(refresh: true);
      ref.read(dashboardNotifierProvider.notifier).loadDashboard(refresh: true);

      state = state.copyWith(
        status: ReportCreationStatus.success,
        createdReport: newReport,
        uploadProgress: 1.0,
      );

      return newReport;
    } on ValidationException catch (e) {
      if (!ref.mounted) return null;

      final backendErrors = <String, String>{};
      for (final entry in e.errors.entries) {
        if (entry.value.isNotEmpty) {
          backendErrors[entry.key] = entry.value.first;
        }
      }

      state = state.copyWith(
        status: ReportCreationStatus.ready,
        fieldErrors: backendErrors,
        errorMessage: e.primaryErrorMessage,
      );
      return null;
    } on AppException catch (e) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        status: ReportCreationStatus.error,
        errorMessage: e.message,
      );
      return null;
    } catch (e) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        status: ReportCreationStatus.error,
        errorMessage: 'Report submission failed. Please check your connection and try again.',
      );
      return null;
    }
  }

  void _setImageError(String error) {
    final updated = Map<String, String>.from(state.fieldErrors)
      ..['images'] = error;
    state = state.copyWith(fieldErrors: updated);
  }

  Future<String?> _validateSingleImage(XFile file) async {
    final ext = file.name.split('.').last.toLowerCase();
    if (!CreateReportFormData.allowedExtensions.contains(ext)) {
      return 'Unsupported format for "${file.name}". Please use JPG, PNG, or WEBP.';
    }

    final size = await file.length();
    if (size > CreateReportFormData.maxFileSizeBytes) {
      final sizeMb = (size / (1024 * 1024)).toStringAsFixed(1);
      return 'File "${file.name}" ($sizeMb MB) exceeds the 5 MB maximum limit.';
    }

    return null;
  }
}

/// Riverpod provider for ReportCreationNotifier
final reportCreationNotifierProvider =
    NotifierProvider<ReportCreationNotifier, ReportCreationState>(
      ReportCreationNotifier.new,
    );
