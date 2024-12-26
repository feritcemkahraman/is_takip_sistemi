class User {
  final String id;
  final String username;
  final String email;
  final String? fcmToken;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fcmToken,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      username: json['username'],
      email: json['email'],
      fcmToken: json['fcmToken'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'fcmToken': fcmToken,
    };
  }
} 