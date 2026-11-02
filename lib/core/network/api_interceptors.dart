import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';

/// Interceptor to automatically attach Bearer token and standard API headers.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  AuthInterceptor(this._storageService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept'] = 'application/json';

    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers[AppConstants.headerAuthorization] = 'Bearer $token';
    }

    handler.next(options);
  }
}

/// Secure logging interceptor that masks sensitive user data and credentials.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('➡️ [HTTP] ${options.method} ${options.uri}');
      // Mask any sensitive payload fields before debug printing
      if (options.data is Map<String, dynamic>) {
        final sanitized = Map<String, dynamic>.from(options.data as Map);
        if (sanitized.containsKey('password')) sanitized['password'] = '******';
        if (sanitized.containsKey('password_confirmation')) {
          sanitized['password_confirmation'] = '******';
        }
        if (sanitized.containsKey('current_password')) {
          sanitized['current_password'] = '******';
        }
        debugPrint('   Payload: $sanitized');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final reqId = response.headers.value(AppConstants.headerRequestId) ?? '-';
      debugPrint(
        '⬅️ [HTTP] ${response.statusCode} ${response.requestOptions.path} (req_id: $reqId)',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '❌ [HTTP Error] ${err.response?.statusCode ?? 'NO_RESPONSE'} ${err.requestOptions.path}: ${err.message}',
      );
    }
    handler.next(err);
  }
}
