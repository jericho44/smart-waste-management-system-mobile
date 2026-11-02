/// Data Transfer Object for citizen account registration.
class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
  }
}

