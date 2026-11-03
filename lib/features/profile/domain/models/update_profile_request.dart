/// Request payload for editing citizen profile information (PUT /auth/profile).
class UpdateProfileRequest {
  final String name;
  final String email;

  const UpdateProfileRequest({required this.name, required this.email});

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  /// Client-side validation. Returns map of field name to error message.
  Map<String, String> validate() {
    final errors = <String, String>{};

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      errors['name'] = 'Full name is required.';
    } else if (trimmedName.length > 255) {
      errors['name'] = 'Name cannot exceed 255 characters.';
    }

    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      errors['email'] = 'Email address is required.';
    } else if (!_emailRegExp.hasMatch(trimmedEmail)) {
      errors['email'] = 'Please enter a valid email address.';
    } else if (trimmedEmail.length > 255) {
      errors['email'] = 'Email cannot exceed 255 characters.';
    }

    return errors;
  }

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'email': email.trim().toLowerCase(),
  };
}
