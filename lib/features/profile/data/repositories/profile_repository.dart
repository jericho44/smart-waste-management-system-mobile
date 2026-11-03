import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../authentication/domain/models/authenticated_user.dart';
import '../../domain/models/change_password_request.dart';
import '../../domain/models/update_profile_request.dart';

/// Repository for citizen profile updates and password modification.
abstract class ProfileRepository {
  /// Update user profile (name, email) via PUT /auth/profile
  Future<AuthenticatedUser> updateProfile(UpdateProfileRequest request);

  /// Change password via PUT /auth/change-password
  Future<void> changePassword(ChangePasswordRequest request);
}

/// Production implementation using ApiClient.
class ApiProfileRepository implements ProfileRepository {
  final ApiClient apiClient;

  ApiProfileRepository({required this.apiClient});

  @override
  Future<AuthenticatedUser> updateProfile(UpdateProfileRequest request) async {
    final response = await apiClient.put<AuthenticatedUser>(
      ApiEndpoints.updateProfile,
      data: request.toJson(),
      fromJson: (json) =>
          AuthenticatedUser.fromJson(json as Map<String, dynamic>),
    );

    return response.data!;
  }

  @override
  Future<void> changePassword(ChangePasswordRequest request) async {
    await apiClient.put(ApiEndpoints.changePassword, data: request.toJson());
  }
}

/// Riverpod provider for ProfileRepository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiProfileRepository(apiClient: apiClient);
});
