import 'package:image_picker/image_picker.dart';

/// Form data representing user input for waste report creation.
class CreateReportFormData {
  final String title;
  final String description;
  final String? categoryUuid;
  final double? latitude;
  final double? longitude;
  final String? address;
  final List<XFile> images;

  const CreateReportFormData({
    required this.title,
    required this.description,
    this.categoryUuid,
    this.latitude,
    this.longitude,
    this.address,
    this.images = const [],
  });

  /// Maximum allowed images per report (matches Laravel StoreReportRequest max:5)
  static const int maxImages = 5;

  /// Maximum file size in bytes (5 MB = 5120 KB matches Laravel max:5120)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  /// Allowed image MIME/extension types
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  /// Validate form data against business rules and Laravel backend constraints.
  /// Returns a map of field name to error message, or empty map if valid.
  Future<Map<String, String>> validate() async {
    final errors = <String, String>{};

    // Title validation
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      errors['title'] = 'Report title is required.';
    } else if (trimmedTitle.length > 255) {
      errors['title'] = 'Title cannot exceed 255 characters.';
    }

    // Description validation
    final trimmedDesc = description.trim();
    if (trimmedDesc.isEmpty) {
      errors['description'] = 'Description is required.';
    } else if (trimmedDesc.length > 5000) {
      errors['description'] = 'Description cannot exceed 5000 characters.';
    }

    // Category validation
    if (categoryUuid == null || categoryUuid!.trim().isEmpty) {
      errors['category_uuid'] = 'Please select a waste category.';
    }

    // Location validation
    if (latitude == null || longitude == null) {
      errors['location'] =
          'GPS location is required to pinpoint the waste site.';
    } else {
      if (latitude! < -90.0 || latitude! > 90.0) {
        errors['latitude'] = 'Latitude must be between -90 and 90.';
      }
      if (longitude! < -180.0 || longitude! > 180.0) {
        errors['longitude'] = 'Longitude must be between -180 and 180.';
      }
    }

    // Address validation (optional, max 500)
    if (address != null && address!.trim().length > 500) {
      errors['address'] = 'Address cannot exceed 500 characters.';
    }

    // Images count validation
    if (images.length > maxImages) {
      errors['images'] = 'A maximum of $maxImages images can be attached.';
    } else {
      // Validate each image
      for (int i = 0; i < images.length; i++) {
        final img = images[i];
        final filename = img.name.isNotEmpty ? img.name : img.path;
        final ext = filename.split('.').last.toLowerCase();

        if (!allowedExtensions.contains(ext)) {
          errors['images'] =
              'Image "$filename" has an unsupported format. Allowed: JPG, PNG, WEBP.';
          break;
        }

        try {
          final length = await img.length();
          if (length > maxFileSizeBytes) {
            final sizeMb = (length / (1024 * 1024)).toStringAsFixed(1);
            errors['images'] =
                'Image "$filename" ($sizeMb MB) exceeds the 5 MB limit.';
            break;
          }
        } catch (_) {
          // File length cannot be resolved on local disk
        }
      }
    }

    return errors;
  }
}
