import 'package:cloud_firestore/cloud_firestore.dart';

class WorkflowModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String assignedTo;
  final String createdBy;
  final DateTime dueDate;
  final DateTime createdAt;
  final List<String> attachments;
  final List<String> tags;
  final List<WorkflowStep> steps;

  WorkflowModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedTo,
    required this.createdBy,
    required this.dueDate,
    required this.createdAt,
    this.attachments = const [],
    this.tags = const [],
    this.steps = const [],
  });

  factory WorkflowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkflowModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      createdBy: data['createdBy'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      attachments: List<String>.from(data['attachments'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      steps: (data['steps'] as List<dynamic>?)
          ?.map((s) => WorkflowStep.fromMap(s as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'attachments': attachments,
      'tags': tags,
      'steps': steps.map((s) => s.toMap()).toList(),
    };
  }

  bool isOverdue() {
    return DateTime.now().isAfter(dueDate);
  }

  bool isActive() {
    return status == 'active';
  }

  WorkflowModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? assignedTo,
    String? createdBy,
    DateTime? dueDate,
    DateTime? createdAt,
    List<String>? attachments,
    List<String>? tags,
    List<WorkflowStep>? steps,
  }) {
    return WorkflowModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
      tags: tags ?? this.tags,
      steps: steps ?? this.steps,
    );
  }
}

class WorkflowStep {
  final String id;
  final String title;
  final String description;
  final String status;
  final String assignedTo;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final List<String> attachments;
  final List<String> approvers;

  WorkflowStep({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedTo,
    this.dueDate,
    this.completedAt,
    this.attachments = const [],
    this.approvers = const [],
  });

  factory WorkflowStep.fromMap(Map<String, dynamic> map) {
    return WorkflowStep(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? '',
      assignedTo: map['assignedTo'] ?? '',
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      attachments: List<String>.from(map['attachments'] ?? []),
      approvers: List<String>.from(map['approvers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'assignedTo': assignedTo,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'attachments': attachments,
      'approvers': approvers,
    };
  }

  WorkflowStep copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? assignedTo,
    DateTime? dueDate,
    DateTime? completedAt,
    List<String>? attachments,
    List<String>? approvers,
  }) {
    return WorkflowStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      attachments: attachments ?? this.attachments,
      approvers: approvers ?? this.approvers,
    );
  }
} 