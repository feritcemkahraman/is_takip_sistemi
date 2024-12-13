import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String department;
  final String role;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.department,
    required this.role,
    this.isActive = true,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      department: data['department'] ?? '',
      role: data['role'] ?? 'user',
      isActive: data['isActive'] ?? true,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      department: map['department'] as String,
      role: map['role'] as String,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  // Getter for id (compatibility with existing code)
  String get id => uid;

  // Getter for username (compatibility with existing code)
  String get username => name;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'department': department,
      'role': role,
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? department,
    String? role,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      department: department ?? this.department,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }

  bool isAdmin() {
    return role == 'admin';
  }
}
