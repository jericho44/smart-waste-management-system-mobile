/// Base class for all application exceptions.
sealed class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? requestId;

  const AppException({required this.message, this.statusCode, this.requestId});

  @override
  String toString() => message;
}

/// Thrown when device has no internet or the connection timed out.
class NetworkException extends AppException {
  const NetworkException({
    super.message =
        'Unable to connect to server. Please check your internet connection.',
    super.statusCode,
    super.requestId,
  });
}

/// Thrown on HTTP 401 Unauthorized (invalid or expired token).
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Your session has expired. Please log in again.',
    super.statusCode = 401,
    super.requestId,
  });
}

/// Thrown on HTTP 403 Forbidden.
class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'You do not have permission to perform this action.',
    super.statusCode = 403,
    super.requestId,
  });
}

/// Thrown on HTTP 404 Not Found.
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.statusCode = 404,
    super.requestId,
  });
}

/// Thrown on HTTP 422 Validation Error from Laravel backend.
class ValidationException extends AppException {
  final Map<String, List<String>> errors;

  const ValidationException({
    super.message = 'The given data was invalid.',
    this.errors = const {},
    super.statusCode = 422,
    super.requestId,
  });

  /// Get the first validation error message for a specific field
  String? firstErrorFor(String field) => errors[field]?.firstOrNull;

  /// Get the primary overall error message
  String get primaryErrorMessage {
    if (errors.isNotEmpty) {
      final firstEntry = errors.entries.first;
      if (firstEntry.value.isNotEmpty) {
        return firstEntry.value.first;
      }
    }
    return message;
  }
}

/// Thrown on HTTP 500+ Internal Server Error.
class ServerException extends AppException {
  const ServerException({
    super.message = 'Server encountered an error. Please try again later.',
    super.statusCode = 500,
    super.requestId,
  });
}

/// Thrown on unexpected or parsing errors.
class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred. Please try again.',
    super.statusCode,
    super.requestId,
  });
}
