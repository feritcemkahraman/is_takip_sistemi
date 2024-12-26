class UserModel {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? avatar;
  final String status;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final List<String> permissions;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.avatar,
    required this.status,
    required this.createdAt,
    this.lastLoginAt,
    this.permissions = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      avatar: json['avatar'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null 
        ? DateTime.parse(json['lastLoginAt'])
        : null,
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'role': role,
      'avatar': avatar,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'permissions': permissions,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? avatar,
    String? status,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<String>? permissions,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      permissions: permissions ?? this.permissions,
    );
  }
}
