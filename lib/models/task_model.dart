import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignedTo;
  final String createdBy;
  final DateTime createdAt;
  final DateTime dueDate;
  final String priority; // Acil, Normal, Düşük
  final String status; // Beklemede, Devam Ediyor, Tamamlandı, Gecikmiş
  final double progress; // İlerleme yüzdesi (0-100)
  final List<String> attachments; // Dosya ekleri
  final List<Comment> comments; // Yorumlar
  final bool isRecurring; // Tekrarlı görev mi?
  final String? recurrenceType; // Günlük, Haftalık, Aylık
  final String department;
  final List<String> watchers; // Görevi takip edenler

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.createdBy,
    required this.createdAt,
    required this.dueDate,
    required this.priority,
    required this.status,
    this.progress = 0,
    this.attachments = const [],
    this.comments = const [],
    this.isRecurring = false,
    this.recurrenceType,
    required this.department,
    this.watchers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority,
      'status': status,
      'progress': progress,
      'attachments': attachments,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'isRecurring': isRecurring,
      'recurrenceType': recurrenceType,
      'department': department,
      'watchers': watchers,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      assignedTo: map['assignedTo'] as String,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      priority: map['priority'] as String,
      status: map['status'] as String,
      progress: (map['progress'] as num).toDouble(),
      attachments: List<String>.from(map['attachments'] ?? []),
      comments: (map['comments'] as List<dynamic>?)
          ?.map((comment) => Comment.fromMap(comment as Map<String, dynamic>))
          .toList() ?? [],
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrenceType: map['recurrenceType'] as String?,
      department: map['department'] as String,
      watchers: List<String>.from(map['watchers'] ?? []),
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedTo,
    String? createdBy,
    DateTime? createdAt,
    DateTime? dueDate,
    String? priority,
    String? status,
    double? progress,
    List<String>? attachments,
    List<Comment>? comments,
    bool? isRecurring,
    String? recurrenceType,
    String? department,
    List<String>? watchers,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      attachments: attachments ?? this.attachments,
      comments: comments ?? this.comments,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      department: department ?? this.department,
      watchers: watchers ?? this.watchers,
    );
  }
}

class Comment {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final List<String> attachments;

  Comment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.attachments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'attachments': attachments,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      userId: map['userId'] as String,
      content: map['content'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      attachments: List<String>.from(map['attachments'] ?? []),
    );
  }
}
