import 'package:cloud_firestore/cloud_firestore.dart';
import 'workflow_model.dart';

class WorkflowTemplate {
  final String id;
  final String name;
  final String description;
  final String type;
  final List<WorkflowStep> steps;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  WorkflowTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.steps,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.metadata,
  });

  factory WorkflowTemplate.fromMap(Map<String, dynamic> map) {
    return WorkflowTemplate(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      type: map['type'] as String,
      steps: (map['steps'] as List<dynamic>)
          .map((step) => WorkflowStep.fromMap(step as Map<String, dynamic>))
          .toList(),
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] as bool? ?? true,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'steps': steps.map((step) => step.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  WorkflowTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    List<WorkflowStep>? steps,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return WorkflowTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      steps: steps ?? this.steps,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  WorkflowModel createWorkflow({
    required String title,
    required String description,
    required String createdBy,
    required String assignedTo,
    required DateTime deadline,
    required String priority,
    Map<String, dynamic>? metadata,
  }) {
    return WorkflowModel(
      id: '', // This will be set by Firestore
      title: title,
      description: description,
      type: type,
      status: WorkflowModel.statusNew,
      currentStep: 0,
      steps: List.from(steps),
      createdBy: createdBy,
      assignedTo: assignedTo,
      deadline: deadline,
      priority: priority,
      createdAt: DateTime.now(),
      updatedAt: null,
      metadata: metadata,
    );
  }
}
