/// Data Transfer Object for user login request.
class LoginRequest {
  final String email;
  final String password;
  final String? deviceName;

  const LoginRequest({
    required this.email,
    required this.password,
    this.deviceName = 'smart_waste_flutter',
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim(),
      'password': password,
      if (deviceName != null) 'device_name': deviceName,
    };
  }
}

