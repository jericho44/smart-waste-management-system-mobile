/// Global application constants.
class AppConstants {
  AppConstants._();

  // Storage keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserUuid = 'user_uuid';
  static const String keyUserData = 'user_data';

  // Pagination defaults
  static const int defaultPerPage = 10;
  static const int maxPerPage = 100;

  // Waste Report Statuses
  static const String statusPending = 'PENDING';
  static const String statusInProgress = 'IN_PROGRESS';
  static const String statusCompleted = 'COMPLETED';
  static const String statusRejected = 'REJECTED';

  // Request Headers
  static const String headerRequestId = 'X-Request-ID';
  static const String headerAuthorization = 'Authorization';
}
