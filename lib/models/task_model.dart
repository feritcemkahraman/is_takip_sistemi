class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignedTo;
  final String createdBy;
  final DateTime createdAt;
  final DateTime deadline;
  final int priority;
  final String status;
  final DateTime? completedAt;
  final List<String> attachments;
  final List<CommentModel> comments;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.createdBy,
    required this.createdAt,
    required this.deadline,
    required this.priority,
    required this.status,
    this.completedAt,
    this.attachments = const [],
    this.comments = const [],
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      assignedTo: json['assignedTo'],
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      deadline: DateTime.parse(json['deadline']),
      priority: json['priority'],
      status: json['status'],
      completedAt: json['completedAt'] != null 
        ? DateTime.parse(json['completedAt'])
        : null,
      attachments: List<String>.from(json['attachments'] ?? []),
      comments: (json['comments'] as List<dynamic>?)
          ?.map((comment) => CommentModel.fromJson(comment))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'priority': priority,
      'status': status,
      'completedAt': completedAt?.toIso8601String(),
      'attachments': attachments,
      'comments': comments.map((comment) => comment.toJson()).toList(),
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
    int? priority,
    String? status,
    DateTime? completedAt,
    List<String>? attachments,
    List<CommentModel>? comments,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      attachments: attachments ?? this.attachments,
      comments: comments ?? this.comments,
    );
  }
}

class CommentModel {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['_id'],
      userId: json['userId'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
