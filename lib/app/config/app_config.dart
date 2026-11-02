import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application runtime configuration loaded from environment (.env).
class AppConfig {
  AppConfig._();

  static late final String apiBaseUrl;
  static late final int connectTimeoutMs;
  static late final int receiveTimeoutMs;
  static late final int sendTimeoutMs;
  static late final String appName;
  static late final String appEnv;

  /// Initialize application configuration with safe fallbacks.
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Fallback if .env is missing or cannot be loaded in test environments
    }

    apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api/v1';
    connectTimeoutMs =
        int.tryParse(dotenv.env['CONNECT_TIMEOUT_MS'] ?? '') ?? 15000;
    receiveTimeoutMs =
        int.tryParse(dotenv.env['RECEIVE_TIMEOUT_MS'] ?? '') ?? 15000;
    sendTimeoutMs = int.tryParse(dotenv.env['SEND_TIMEOUT_MS'] ?? '') ?? 15000;
    appName = dotenv.env['APP_NAME'] ?? 'Smart Waste Mobile';
    appEnv = dotenv.env['APP_ENV'] ?? 'development';
  }

  /// Whether running in production mode
  static bool get isProduction => appEnv == 'production';
}
