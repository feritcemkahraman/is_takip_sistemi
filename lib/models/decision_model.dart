import 'package:cloud_firestore/cloud_firestore.dart';

class DecisionModel {
  final String id;
  final String content;
  final String? assignedTo;
  final DateTime dueDate;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? completedAt;

  DecisionModel({
    required this.id,
    required this.content,
    this.assignedTo,
    required this.dueDate,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.completedAt,
  });

  factory DecisionModel.fromMap(Map<String, dynamic> map) {
    return DecisionModel(
      id: map['id'] as String,
      content: map['content'] as String,
      assignedTo: map['assignedTo'] as String?,
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      status: map['status'] as String,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'assignedTo': assignedTo,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
} 