/// API endpoint routes for Smart Waste Management System.
class ApiEndpoints {
  ApiEndpoints._();

  // Health
  static const String health = '/health';

  // Authentication
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String changePassword = '/auth/change-password';

  // Categories
  static const String categories = '/categories';
  static String categoryDetails(String idOrSlug) => '/categories/$idOrSlug';

  // Dashboard
  static const String userDashboard = '/dashboard/user';

  // Waste Reports
  static const String reports = '/reports';
  static String reportDetails(String uuid) => '/reports/$uuid';
  static String reportUpdate(String uuid) => '/reports/$uuid';
  static String reportDelete(String uuid) => '/reports/$uuid';
  static String reportHistory(String uuid) => '/reports/$uuid/history';
  static String reportUploadImages(String uuid) => '/reports/$uuid/images';
  static String reportDeleteImage(String reportUuid, String imageUuid) =>
      '/reports/$reportUuid/images/$imageUuid';
}
