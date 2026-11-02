import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/app_config.dart';
import '../../shared/models/api_response.dart';
import '../errors/app_exception.dart';
import '../storage/secure_storage_service.dart';
import 'api_interceptors.dart';

/// Centralized HTTP client wrapping Dio with authentication, error mapping, and envelope unwrapping.
class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio, required SecureStorageService storageService})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: Duration(
                milliseconds: AppConfig.connectTimeoutMs,
              ),
              receiveTimeout: Duration(
                milliseconds: AppConfig.receiveTimeoutMs,
              ),
              sendTimeout: Duration(milliseconds: AppConfig.sendTimeoutMs),
              responseType: ResponseType.json,
              headers: {'Accept': 'application/json'},
            ),
          ) {
    _dio.interceptors.addAll([
      AuthInterceptor(storageService),
      LoggingInterceptor(),
    ]);
  }

  /// Expose underlying Dio instance for advanced scenarios
  Dio get dio => _dio;

  /// Perform HTTP GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  /// Perform HTTP POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  /// Perform HTTP PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  /// Perform HTTP PATCH request
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  /// Perform HTTP DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  /// Upload multipart form data with progress tracking
  Future<ApiResponse<T>> uploadMultipart<T>(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(contentType: 'multipart/form-data'),
      );
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  /// Unwraps backend JSON into `ApiResponse<T>`
  ApiResponse<T> _parseResponse<T>(
    Response response,
    T Function(dynamic json)? fromJson,
  ) {
    if (response.data is Map<String, dynamic>) {
      return ApiResponse<T>.fromJson(
        response.data as Map<String, dynamic>,
        fromJson,
      );
    }
    // Handle cases where body is not a map
    return ApiResponse<T>(
      success:
          response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300,
      message: 'OK',
      data: fromJson != null ? fromJson(response.data) : response.data as T?,
    );
  }

  /// Translates DioException into strongly-typed domain AppException
  AppException _handleDioError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;

    String? requestId;
    String message = 'An unexpected network error occurred';
    Map<String, List<String>> validationErrors = {};

    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;
      message = data['message'] as String? ?? message;

      if (data['meta'] is Map<String, dynamic>) {
        requestId =
            (data['meta'] as Map<String, dynamic>)['request_id'] as String?;
      }

      // Parse validation error dictionary
      if (data['errors'] is Map<String, dynamic>) {
        final rawErrors = data['errors'] as Map<String, dynamic>;
        validationErrors = rawErrors.map((key, value) {
          if (value is List) {
            return MapEntry(key, value.map((e) => e.toString()).toList());
          }
          return MapEntry(key, [value.toString()]);
        });
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.transformTimeout:
        return NetworkException(
          message:
              'Connection timed out. Please check your internet connectivity.',
          statusCode: statusCode,
          requestId: requestId,
        );

      case DioExceptionType.badResponse:
        switch (statusCode) {
          case 401:
            return UnauthorizedException(
              message: message,
              statusCode: 401,
              requestId: requestId,
            );
          case 403:
            return ForbiddenException(
              message: message,
              statusCode: 403,
              requestId: requestId,
            );
          case 404:
            return NotFoundException(
              message: message,
              statusCode: 404,
              requestId: requestId,
            );
          case 422:
            return ValidationException(
              message: message,
              errors: validationErrors,
              statusCode: 422,
              requestId: requestId,
            );
          case 500:
          case 502:
          case 503:
          case 504:
            return ServerException(
              message: 'Server error encountered. Please try again shortly.',
              statusCode: statusCode,
              requestId: requestId,
            );
          default:
            return UnknownException(
              message: message,
              statusCode: statusCode,
              requestId: requestId,
            );
        }

      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'SSL Certificate verification failed.',
        );

      case DioExceptionType.unknown:
        return NetworkException(
          message: error.message ?? 'Network connection failure.',
          statusCode: statusCode,
          requestId: requestId,
        );
    }
  }
}

/// Riverpod provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return ApiClient(storageService: storage);
});
