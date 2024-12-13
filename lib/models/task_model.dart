import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String assignedTo;
  final String createdBy;
  final DateTime dueDate;
  final DateTime createdAt;
  final double progress;
  final List<String> attachments;
  final List<String> tags;
  final List<Comment> comments;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.assignedTo,
    required this.createdBy,
    required this.dueDate,
    required this.createdAt,
    this.progress = 0.0,
    this.attachments = const [],
    this.tags = const [],
    this.comments = const [],
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? '',
      priority: data['priority'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      createdBy: data['createdBy'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      progress: (data['progress'] ?? 0.0).toDouble(),
      attachments: List<String>.from(data['attachments'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      comments: (data['comments'] as List<dynamic>?)
          ?.map((c) => Comment.fromMap(c as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'progress': progress,
      'attachments': attachments,
      'tags': tags,
      'comments': comments.map((c) => c.toMap()).toList(),
    };
  }

  bool isOverdue() {
    return DateTime.now().isAfter(dueDate);
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? assignedTo,
    String? createdBy,
    DateTime? dueDate,
    DateTime? createdAt,
    double? progress,
    List<String>? attachments,
    List<String>? tags,
    List<Comment>? comments,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      progress: progress ?? this.progress,
      attachments: attachments ?? this.attachments,
      tags: tags ?? this.tags,
      comments: comments ?? this.comments,
    );
  }
}

class Comment {
  final String id;
  final String text;
  final String userId;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.text,
    required this.userId,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
