import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/models/authenticated_user.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

/// Repository handling authentication API requests and secure token persistence.
class AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService storageService;

  AuthRepository({required this.apiClient, required this.storageService});

  /// Authenticate with email and password through Laravel Sanctum API.
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await apiClient.post<AuthResponse>(
      ApiEndpoints.login,
      data: request.toJson(),
      fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
    );

    final authData = response.data!;
    await storageService.saveToken(authData.token);
    await storageService.saveUserData(authData.user.toJsonString());

    return authData;
  }

  /// Register a new citizen account and automatically persist generated token.
  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await apiClient.post<AuthResponse>(
      ApiEndpoints.register,
      data: request.toJson(),
      fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
    );

    final authData = response.data!;
    await storageService.saveToken(authData.token);
    await storageService.saveUserData(authData.user.toJsonString());

    return authData;
  }

  /// Revoke current access token on Laravel and purge local storage.
  Future<void> logout() async {
    try {
      await apiClient.post<dynamic>(ApiEndpoints.logout);
    } catch (_) {
      // Continue clearing local credentials even if network/server fails
    } finally {
      await storageService.clearAll();
    }
  }

  /// Validate current session and retrieve profile through GET /auth/me.
  Future<AuthenticatedUser> getMe() async {
    final response = await apiClient.get<AuthenticatedUser>(
      ApiEndpoints.me,
      fromJson: (json) =>
          AuthenticatedUser.fromJson(json as Map<String, dynamic>),
    );

    final user = response.data!;
    await storageService.saveUserData(user.toJsonString());
    return user;
  }

  /// Retrieve locally cached user profile if present
  Future<AuthenticatedUser?> getCachedUser() async {
    final raw = await storageService.getUserData();
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthenticatedUser.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  /// Check whether an access token exists in secure storage
  Future<bool> hasStoredToken() async {
    return storageService.hasToken();
  }

  /// Purge all stored credentials and cached session data
  Future<void> clearLocalAuth() async {
    await storageService.clearAll();
  }
}

/// Riverpod provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  return AuthRepository(apiClient: apiClient, storageService: storageService);
});
