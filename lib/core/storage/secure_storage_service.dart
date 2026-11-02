import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Secure storage abstraction for authentication tokens and sensitive credentials.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  /// Save personal access token
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.keyAuthToken, value: token);
  }

  /// Retrieve current access token
  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.keyAuthToken);
  }

  /// Check whether an access token exists
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Delete saved access token
  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.keyAuthToken);
  }

  /// Save cached user data json
  Future<void> saveUserData(String userDataJson) async {
    await _storage.write(key: AppConstants.keyUserData, value: userDataJson);
  }

  /// Retrieve cached user data json
  Future<String?> getUserData() async {
    return _storage.read(key: AppConstants.keyUserData);
  }

  /// Delete cached user data
  Future<void> deleteUserData() async {
    await _storage.delete(key: AppConstants.keyUserData);
  }

  /// Clear all stored credentials and cached session data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

/// Riverpod provider for secure storage service
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
