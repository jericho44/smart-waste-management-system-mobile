import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../authentication/presentation/state/auth_notifier.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/change_password_request.dart';
import '../../domain/models/update_profile_request.dart';
import 'profile_state.dart';

/// Notifier handling profile edits and password updates.
class ProfileNotifier extends Notifier<ProfileState> {
  late final ProfileRepository _repository;

  @override
  ProfileState build() {
    _repository = ref.watch(profileRepositoryProvider);
    return ProfileState.initial();
  }

  /// Update citizen profile name and email
  Future<bool> updateProfile(UpdateProfileRequest request) async {
    if (state.isUpdatingProfile) return false;

    // Client-side validation
    final errors = request.validate();
    if (errors.isNotEmpty) {
      state = state.copyWith(profileErrors: errors);
      return false;
    }

    state = state.copyWith(
      isUpdatingProfile: true,
      profileErrors: const {},
      clearProfileSuccess: true,
      clearError: true,
    );

    try {
      final updatedUser = await _repository.updateProfile(request);
      if (!ref.mounted) return true;

      // Update in-memory authenticated user in auth state
      ref.read(authNotifierProvider.notifier).updateCurrentUser(updatedUser);

      state = state.copyWith(
        isUpdatingProfile: false,
        profileSuccessMessage: 'Profile updated successfully.',
      );
      return true;
    } on ValidationException catch (e) {
      if (!ref.mounted) return false;

      final backendErrors = <String, String>{};
      for (final entry in e.errors.entries) {
        if (entry.value.isNotEmpty) {
          backendErrors[entry.key] = entry.value.first;
        }
      }

      state = state.copyWith(
        isUpdatingProfile: false,
        profileErrors: backendErrors,
        errorMessage: e.primaryErrorMessage,
      );
      return false;
    } on AppException catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(isUpdatingProfile: false, errorMessage: e.message);
      return false;
    } catch (_) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isUpdatingProfile: false,
        errorMessage: 'Unable to update profile. Please try again.',
      );
      return false;
    }
  }

  /// Change citizen password securely (never stored locally)
  Future<bool> changePassword(ChangePasswordRequest request) async {
    if (state.isChangingPassword) return false;

    // Client-side validation
    final errors = request.validate();
    if (errors.isNotEmpty) {
      state = state.copyWith(passwordErrors: errors);
      return false;
    }

    state = state.copyWith(
      isChangingPassword: true,
      passwordErrors: const {},
      clearPasswordSuccess: true,
      clearError: true,
    );

    try {
      await _repository.changePassword(request);
      if (!ref.mounted) return true;

      state = state.copyWith(
        isChangingPassword: false,
        passwordSuccessMessage: 'Password changed successfully.',
      );
      return true;
    } on ValidationException catch (e) {
      if (!ref.mounted) return false;

      final backendErrors = <String, String>{};
      for (final entry in e.errors.entries) {
        if (entry.value.isNotEmpty) {
          backendErrors[entry.key] = entry.value.first;
        }
      }

      state = state.copyWith(
        isChangingPassword: false,
        passwordErrors: backendErrors,
        errorMessage: e.primaryErrorMessage,
      );
      return false;
    } on AppException catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isChangingPassword: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isChangingPassword: false,
        errorMessage:
            'Unable to change password. Please verify your current password.',
      );
      return false;
    }
  }

  /// Reset transient error and success feedback
  void clearMessages() {
    state = state.copyWith(
      clearProfileSuccess: true,
      clearPasswordSuccess: true,
      clearError: true,
      profileErrors: const {},
      passwordErrors: const {},
    );
  }
}

/// Riverpod provider for ProfileNotifier
final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
