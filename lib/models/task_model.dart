import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignedTo;
  final String createdBy;
  final DateTime createdAt;
  final DateTime deadline;
  final DateTime? completedAt;
  final String status; // 'active', 'pending', 'completed'
  final int priority; // 1: Düşük, 2: Orta, 3: Yüksek
  final List<String> attachments;
  final Map<String, dynamic> metadata;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.createdBy,
    required this.createdAt,
    required this.deadline,
    this.completedAt,
    required this.status,
    required this.priority,
    required this.attachments,
    required this.metadata,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      deadline: (data['deadline'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'pending',
      priority: data['priority'] ?? 1,
      attachments: List<String>.from(data['attachments'] ?? []),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'deadline': Timestamp.fromDate(deadline),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'status': status,
      'priority': priority,
      'attachments': attachments,
      'metadata': metadata,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedTo,
    String? createdBy,
    DateTime? createdAt,
    DateTime? deadline,
    DateTime? completedAt,
    String? status,
    int? priority,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
    );
  }
}
