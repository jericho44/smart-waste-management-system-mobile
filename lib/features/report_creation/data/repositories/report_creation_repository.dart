import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../reports/domain/models/waste_category.dart';
import '../../../reports/domain/models/waste_report.dart';
import '../../domain/models/create_report_form_data.dart';

/// Repository responsible for waste report creation and category retrieval.
abstract class ReportCreationRepository {
  /// Fetch active waste categories for report assignment.
  Future<List<WasteCategory>> getCategories();

  /// Submit a new waste report using multipart/form-data.
  Future<WasteReport> submitReport(
    CreateReportFormData formData, {
    void Function(int sent, int total)? onProgress,
  });
}

/// Production implementation of ReportCreationRepository.
class ApiReportCreationRepository implements ReportCreationRepository {
  final ApiClient apiClient;

  ApiReportCreationRepository({required this.apiClient});

  @override
  Future<List<WasteCategory>> getCategories() async {
    final response = await apiClient.get<List<dynamic>>(
      ApiEndpoints.categories,
      fromJson: (json) => json as List<dynamic>,
    );

    final rawList = response.data ?? [];
    return rawList
        .map((item) => WasteCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WasteReport> submitReport(
    CreateReportFormData formData, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final multipartData = FormData();

    // Required text parameters
    multipartData.fields.add(MapEntry('title', formData.title.trim()));
    multipartData.fields.add(
      MapEntry('description', formData.description.trim()),
    );
    multipartData.fields.add(
      MapEntry('category_uuid', formData.categoryUuid!.trim()),
    );
    multipartData.fields.add(
      MapEntry('latitude', formData.latitude!.toString()),
    );
    multipartData.fields.add(
      MapEntry('longitude', formData.longitude!.toString()),
    );

    // Optional address
    if (formData.address != null && formData.address!.trim().isNotEmpty) {
      multipartData.fields.add(MapEntry('address', formData.address!.trim()));
    }

    // Attach images (Laravel expects images[] array in multipart)
    for (final img in formData.images) {
      final multipartFile = await MultipartFile.fromFile(
        img.path,
        filename: img.name,
      );
      multipartData.files.add(MapEntry('images[]', multipartFile));
    }

    final response = await apiClient.post<WasteReport>(
      ApiEndpoints.reports,
      data: multipartData,
      onSendProgress: onProgress,
      fromJson: (json) => WasteReport.fromJson(json as Map<String, dynamic>),
    );

    return response.data!;
  }
}

/// Riverpod provider for ReportCreationRepository
final reportCreationRepositoryProvider = Provider<ReportCreationRepository>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiReportCreationRepository(apiClient: apiClient);
});
