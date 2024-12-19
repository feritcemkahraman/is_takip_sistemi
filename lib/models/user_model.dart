import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class UserModel {
  final String id;
  final String email;
  final String name;
  final String username;
  final String role;
  final String department;
  final DateTime createdAt;
  final String? avatar;
  final String? phoneNumber;
  final String? title;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> metadata;

  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';
  static const String roleEmployee = 'employee';

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.username,
    required this.role,
    required this.department,
    required this.createdAt,
    this.avatar,
    this.phoneNumber,
    this.title,
    this.lastLoginAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'username': username,
      'role': role,
      'department': department,
      'createdAt': createdAt.toIso8601String(),
      'avatar': avatar,
      'phoneNumber': phoneNumber,
      'title': title,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? map['email'] ?? '',
      role: map['role'] ?? '',
      department: map['department'] ?? '',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      avatar: map['avatar'],
      phoneNumber: map['phoneNumber'],
      title: map['title'],
      lastLoginAt: map['lastLoginAt'] != null 
          ? map['lastLoginAt'] is Timestamp
              ? (map['lastLoginAt'] as Timestamp).toDate()
              : DateTime.parse(map['lastLoginAt'])
          : null,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel.fromMap({...data, 'id': doc.id});
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? username,
    String? role,
    String? department,
    String? avatar,
    String? phoneNumber,
    String? title,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      role: role ?? this.role,
      department: department ?? this.department,
      avatar: avatar ?? this.avatar,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'UserModel{id: $id, name: $name, email: $email, role: $role, department: $department, createdAt: $createdAt}';
  }
}
