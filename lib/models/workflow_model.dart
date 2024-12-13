import 'package:cloud_firestore/cloud_firestore.dart';

class WorkflowModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime deadline;
  final String status;
  final String priority;
  final String type;
  final List<String> assignedTo;
  final List<WorkflowStep> steps;
  final List<WorkflowFile> files;
  final List<WorkflowComment> comments;
  final List<String> departments;
  final List<String> tags;

  static const String statusDraft = 'draft';
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusRejected = 'rejected';
  static const String statusActive = 'active';

  static const String priorityLow = 'low';
  static const String priorityNormal = 'normal';
  static const String priorityHigh = 'high';
  static const String priorityUrgent = 'urgent';

  WorkflowModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.deadline,
    required this.status,
    required this.priority,
    required this.type,
    required this.assignedTo,
    required this.steps,
    required this.files,
    required this.comments,
    this.departments = const [],
    this.tags = const [],
  });

  factory WorkflowModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WorkflowModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      deadline: (data['deadline'] as Timestamp).toDate(),
      status: data['status'] ?? statusPending,
      priority: data['priority'] ?? priorityNormal,
      type: data['type'] ?? '',
      assignedTo: List<String>.from(data['assignedTo'] ?? []),
      steps: (data['steps'] as List<dynamic>? ?? [])
          .map((step) => WorkflowStep.fromMap(step as Map<String, dynamic>))
          .toList(),
      files: (data['files'] as List<dynamic>? ?? [])
          .map((file) => WorkflowFile.fromMap(file as Map<String, dynamic>))
          .toList(),
      comments: (data['comments'] as List<dynamic>? ?? [])
          .map((comment) => WorkflowComment.fromMap(comment as Map<String, dynamic>))
          .toList(),
      departments: List<String>.from(data['departments'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'deadline': Timestamp.fromDate(deadline),
      'status': status,
      'priority': priority,
      'type': type,
      'assignedTo': assignedTo,
      'steps': steps.map((step) => step.toMap()).toList(),
      'files': files.map((file) => file.toMap()).toList(),
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'departments': departments,
      'tags': tags,
    };
  }

  Map<String, dynamic> toFirestore() {
    final map = toMap();
    map.remove('id');
    return map;
  }

  WorkflowModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? deadline,
    String? status,
    String? priority,
    String? type,
    List<String>? assignedTo,
    List<WorkflowStep>? steps,
    List<WorkflowFile>? files,
    List<WorkflowComment>? comments,
    List<String>? departments,
    List<String>? tags,
  }) {
    return WorkflowModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      assignedTo: assignedTo ?? this.assignedTo,
      steps: steps ?? this.steps,
      files: files ?? this.files,
      comments: comments ?? this.comments,
      departments: departments ?? this.departments,
      tags: tags ?? this.tags,
    );
  }

  // Status check methods
  bool isActive() => status == statusActive;
  bool isCompleted() => status == statusCompleted;
  bool isCancelled() => status == statusRejected;
  bool isOverdue() => DateTime.now().isAfter(deadline) && status != statusCompleted;

  // Additional methods
  WorkflowStep? get currentStep {
    return steps.firstWhere(
      (step) => step.status == WorkflowStep.statusActive,
      orElse: () => steps.firstWhere(
        (step) => step.status == WorkflowStep.statusPending,
        orElse: () => steps.first,
      ),
    );
  }

  String get priorityText {
    switch (priority) {
      case priorityLow:
        return 'Düşük';
      case priorityNormal:
        return 'Normal';
      case priorityHigh:
        return 'Yüksek';
      case priorityUrgent:
        return 'Acil';
      default:
        return 'Bilinmiyor';
    }
  }

  String get remainingTimeText {
    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) {
      return 'Gecikmiş';
    }
    if (remaining.inDays > 0) {
      return '${remaining.inDays} gün';
    }
    if (remaining.inHours > 0) {
      return '${remaining.inHours} saat';
    }
    return '${remaining.inMinutes} dakika';
  }

  bool canEdit(String userId) {
    return createdBy == userId || assignedTo.contains(userId);
  }

  bool canDelete(String userId) {
    return createdBy == userId;
  }

  bool canAddComment(String userId) {
    return assignedTo.contains(userId) || createdBy == userId;
  }

  bool canAddFile(String userId) {
    return assignedTo.contains(userId) || createdBy == userId;
  }

  bool hasAttachments() {
    return files.isNotEmpty;
  }

  bool hasComments() {
    return comments.isNotEmpty;
  }
}

class WorkflowStep {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final String assignedTo;
  final String status;
  final String type;
  final DateTime? completedAt;
  final int order;
  final Map<String, dynamic>? conditions;
  final List<String>? trueSteps;
  final List<String>? falseSteps;
  final List<WorkflowStep>? parallelSteps;
  final Map<String, dynamic>? loopCondition;
  final List<WorkflowStep>? loopSteps;

  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusRejected = 'rejected';
  static const String statusActive = 'active';
  static const String statusSkipped = 'skipped';

  static const String typeTask = 'task';
  static const String typeApproval = 'approval';
  static const String typeCondition = 'condition';
  static const String typeParallel = 'parallel';
  static const String typeLoop = 'loop';

  WorkflowStep({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.assignedTo,
    required this.status,
    required this.type,
    this.completedAt,
    required this.order,
    this.conditions,
    this.trueSteps,
    this.falseSteps,
    this.parallelSteps,
    this.loopCondition,
    this.loopSteps,
  });

  factory WorkflowStep.fromMap(Map<String, dynamic> map) {
    return WorkflowStep(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      deadline: (map['deadline'] as Timestamp).toDate(),
      assignedTo: map['assignedTo'] as String,
      status: map['status'] as String,
      type: map['type'] as String,
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
      order: map['order'] as int,
      conditions: map['conditions'] as Map<String, dynamic>?,
      trueSteps: map['trueSteps'] != null ? List<String>.from(map['trueSteps'] as List<dynamic>) : null,
      falseSteps: map['falseSteps'] != null ? List<String>.from(map['falseSteps'] as List<dynamic>) : null,
      parallelSteps: map['parallelSteps'] != null
          ? (map['parallelSteps'] as List<dynamic>)
              .map((step) => WorkflowStep.fromMap(step as Map<String, dynamic>))
              .toList()
          : null,
      loopCondition: map['loopCondition'] as Map<String, dynamic>?,
      loopSteps: map['loopSteps'] != null
          ? (map['loopSteps'] as List<dynamic>)
              .map((step) => WorkflowStep.fromMap(step as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'assignedTo': assignedTo,
      'status': status,
      'type': type,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'order': order,
      'conditions': conditions,
      'trueSteps': trueSteps,
      'falseSteps': falseSteps,
      'parallelSteps': parallelSteps?.map((step) => step.toMap()).toList(),
      'loopCondition': loopCondition,
      'loopSteps': loopSteps?.map((step) => step.toMap()).toList(),
    };
  }

  bool get isCompleted => status == statusCompleted;
}

class WorkflowFile {
  final String id;
  final String name;
  final String url;
  final String type;
  final int size;
  final String uploadedBy;
  final DateTime uploadedAt;

  WorkflowFile({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory WorkflowFile.fromMap(Map<String, dynamic> map) {
    return WorkflowFile(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      type: map['type'] as String,
      size: map['size'] as int,
      uploadedBy: map['uploadedBy'] as String,
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'size': size,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}

class WorkflowComment {
  final String id;
  final String comment;
  final String userId;
  final DateTime timestamp;
  final List<String>? attachments;

  WorkflowComment({
    required this.id,
    required this.comment,
    required this.userId,
    required this.timestamp,
    this.attachments,
  });

  factory WorkflowComment.fromMap(Map<String, dynamic> map) {
    return WorkflowComment(
      id: map['id'] as String,
      comment: map['comment'] as String,
      userId: map['userId'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      attachments: map['attachments'] != null ? List<String>.from(map['attachments'] as List<dynamic>) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'comment': comment,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'attachments': attachments,
    };
  }
}

class WorkflowHistory {
  final String id;
  final String action;
  final String userId;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  WorkflowHistory({
    required this.id,
    required this.action,
    required this.userId,
    required this.timestamp,
    this.details,
  });

  factory WorkflowHistory.fromMap(Map<String, dynamic> map) {
    return WorkflowHistory(
      id: map['id'] as String,
      action: map['action'] as String,
      userId: map['userId'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      details: map['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'details': details,
    };
  }
}