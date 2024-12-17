import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? deadline;
  final String createdBy;
  final List<String> teamMembers;
  final Map<String, dynamic>? metadata;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.deadline,
    required this.createdBy,
    required this.teamMembers,
    this.metadata,
  });

  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? deadline,
    String? createdBy,
    List<String>? teamMembers,
    Map<String, dynamic>? metadata,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      createdBy: createdBy ?? this.createdBy,
      teamMembers: teamMembers ?? this.teamMembers,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'createdBy': createdBy,
      'teamMembers': teamMembers,
      'metadata': metadata,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      deadline: map['deadline'] != null 
        ? (map['deadline'] as Timestamp).toDate() 
        : null,
      createdBy: map['createdBy'] ?? '',
      teamMembers: List<String>.from(map['teamMembers'] ?? []),
      metadata: map['metadata'],
    );
  }

  @override
  String toString() {
    return 'ProjectModel(id: $id, title: $title, description: $description, status: $status, createdAt: $createdAt, deadline: $deadline, createdBy: $createdBy, teamMembers: $teamMembers, metadata: $metadata)';
  }
}
