import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final String assignedTo;
  final DateTime deadline;
  final String status;
  final String priority;
  final bool isRecurring;
  final String? recurrenceRule;
  final List<TaskComment> comments;
  final List<TaskFile> files;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusOverdue = 'overdue';

  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityUrgent = 'urgent';

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.assignedTo,
    required this.deadline,
    required this.status,
    required this.priority,
    this.isRecurring = false,
    this.recurrenceRule,
    this.comments = const [],
    this.files = const [],
    this.tags = const [],
    this.metadata,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      assignedTo: map['assignedTo'] as String,
      deadline: (map['deadline'] as Timestamp).toDate(),
      status: map['status'] as String,
      priority: map['priority'] as String,
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrenceRule: map['recurrenceRule'] as String?,
      comments: (map['comments'] as List<dynamic>?)
          ?.map((comment) => TaskComment.fromMap(comment as Map<String, dynamic>))
          .toList() ?? [],
      files: (map['files'] as List<dynamic>?)
          ?.map((file) => TaskFile.fromMap(file as Map<String, dynamic>))
          .toList() ?? [],
      tags: List<String>.from(map['tags'] as List<dynamic>? ?? []),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    return TaskModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'assignedTo': assignedTo,
      'deadline': Timestamp.fromDate(deadline),
      'status': status,
      'priority': priority,
      'isRecurring': isRecurring,
      'recurrenceRule': recurrenceRule,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'files': files.map((file) => file.toMap()).toList(),
      'tags': tags,
      'metadata': metadata,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    String? assignedTo,
    DateTime? deadline,
    String? status,
    String? priority,
    bool? isRecurring,
    String? recurrenceRule,
    List<TaskComment>? comments,
    List<TaskFile>? files,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      assignedTo: assignedTo ?? this.assignedTo,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      comments: comments ?? this.comments,
      files: files ?? this.files,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  bool hasComments() {
    return comments.isNotEmpty;
  }

  bool isOverdue() {
    return DateTime.now().isAfter(deadline) && status != statusCompleted;
  }

  // Status check methods
  bool isCompleted() => status == statusCompleted;
  bool isPending() => status == statusPending;
  bool isInProgress() => status == statusInProgress;
  bool isCancelled() => status == statusCancelled;
  bool isOverdueStatus() => status == statusOverdue;

  // Priority check methods
  bool isHighPriority() => priority == priorityHigh || priority == priorityUrgent;
  bool isMediumPriority() => priority == priorityMedium;
  bool isLowPriority() => priority == priorityLow;

  // Additional methods
  bool hasAttachments() => files.isNotEmpty;

}

class TaskComment {
  final String id;
  final String text;
  final String createdBy;
  final DateTime createdAt;
  final List<String>? attachments;

  TaskComment({
    required this.id,
    required this.text,
    required this.createdBy,
    required this.createdAt,
    this.attachments,
  });

  factory TaskComment.fromMap(Map<String, dynamic> map) {
    return TaskComment(
      id: map['id'] as String,
      text: map['text'] as String,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'] as List<dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'attachments': attachments,
    };
  }
}

class TaskFile {
  final String id;
  final String name;
  final String url;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String type;
  final int size;

  TaskFile({
    required this.id,
    required this.name,
    required this.url,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.type,
    required this.size,
  });

  factory TaskFile.fromMap(Map<String, dynamic> map) {
    return TaskFile(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      uploadedBy: map['uploadedBy'] as String,
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      type: map['type'] as String,
      size: map['size'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'type': type,
      'size': size,
    };
  }
}
