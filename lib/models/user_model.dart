import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class UserModel {
  final String id;
  final String name;
  final String email;
  final String username;
  final String role;
  final String department;
  final String? avatar;
  final String? phoneNumber;
  final String? title;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';
  static const String roleEmployee = 'employee';

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
    required this.department,
    this.avatar,
    this.phoneNumber,
    this.title,
    required this.createdAt,
    this.lastLoginAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'username': username,
      'role': role,
      'department': department,
      'avatar': avatar,
      'phoneNumber': phoneNumber,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      role: map['role'] ?? '',
      department: map['department'] ?? '',
      avatar: map['avatar'],
      phoneNumber: map['phoneNumber'],
      title: map['title'],
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: map['lastLoginAt'] != null 
          ? map['lastLoginAt'] is Timestamp
              ? (map['lastLoginAt'] as Timestamp).toDate()
              : DateTime.parse(map['lastLoginAt'])
          : null,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel.fromMap({...data, 'id': doc.id});
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? role,
    String? department,
    String? avatar,
    String? phoneNumber,
    String? title,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      department: department ?? this.department,
      avatar: avatar ?? this.avatar,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
