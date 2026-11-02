import '../../domain/models/authenticated_user.dart';

/// Response payload returned on successful authentication (login / register).
class AuthResponse {
  final AuthenticatedUser user;
  final String token;
  final String tokenType;

  const AuthResponse({
    required this.user,
    required this.token,
    this.tokenType = 'Bearer',
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: AuthenticatedUser.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }
}

