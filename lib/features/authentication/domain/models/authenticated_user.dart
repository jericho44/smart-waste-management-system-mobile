import 'dart:convert';

/// Domain entity representing the authenticated citizen or user.
class AuthenticatedUser {
  final String uuid;
  final String name;
  final String email;
  final bool isActive;
  final List<String> roles;
  final List<String> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AuthenticatedUser({
    required this.uuid,
    required this.name,
    required this.email,
    this.isActive = true,
    this.roles = const [],
    this.permissions = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Check whether the user has administrator privileges
  bool get isAdmin => roles.contains('admin');

  /// Check whether the user has a specific permission
  bool hasPermission(String permission) => permissions.contains(permission);

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      roles:
          (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'email': email,
      'is_active': isActive,
      'roles': roles,
      'permissions': permissions,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory AuthenticatedUser.fromJsonString(String source) =>
      AuthenticatedUser.fromJson(jsonDecode(source) as Map<String, dynamic>);

  AuthenticatedUser copyWith({
    String? uuid,
    String? name,
    String? email,
    bool? isActive,
    List<String>? roles,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthenticatedUser(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
