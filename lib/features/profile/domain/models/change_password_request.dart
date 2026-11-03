/// Request payload for changing user password (PUT /auth/change-password).
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  final String newPasswordConfirmation;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.newPasswordConfirmation,
  });

  /// Client-side validation matching backend requirements.
  Map<String, String> validate() {
    final errors = <String, String>{};

    if (currentPassword.isEmpty) {
      errors['current_password'] = 'Current password is required.';
    }

    if (newPassword.isEmpty) {
      errors['new_password'] = 'New password is required.';
    } else if (newPassword.length < 8) {
      errors['new_password'] =
          'New password must be at least 8 characters long.';
    } else if (newPassword == currentPassword) {
      errors['new_password'] =
          'New password must be different from your current password.';
    }

    if (newPasswordConfirmation.isEmpty) {
      errors['new_password_confirmation'] = 'Please confirm your new password.';
    } else if (newPassword != newPasswordConfirmation) {
      errors['new_password_confirmation'] =
          'Password confirmation does not match.';
    }

    return errors;
  }

  Map<String, dynamic> toJson() => {
    'current_password': currentPassword,
    'new_password': newPassword,
    'new_password_confirmation': newPasswordConfirmation,
  };
}
