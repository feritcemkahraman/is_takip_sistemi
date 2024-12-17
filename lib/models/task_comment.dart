import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class TaskComment {
  final String id;
  final String content;
  final String userId;
  final String? userName;
  final DateTime createdAt;
  final List<String> attachments;
  final Map<String, dynamic>? metadata;

  const TaskComment({
    required this.id,
    required this.content,
    required this.userId,
    this.userName,
    required this.createdAt,
    this.attachments = const [],
    this.metadata,
  });

  factory TaskComment.fromMap(Map<String, dynamic> map) {
    return TaskComment(
      id: map['id'] as String? ?? '',
      content: map['content'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      attachments: List<String>.from(map['attachments'] as List<dynamic>? ?? []),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'userId': userId,
      'userName': userName,
      'createdAt': Timestamp.fromDate(createdAt),
      'attachments': attachments,
      'metadata': metadata,
    };
  }

  TaskComment copyWith({
    String? id,
    String? content,
    String? userId,
    String? userName,
    DateTime? createdAt,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
  }) {
    return TaskComment(
      id: id ?? this.id,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
    );
  }

  bool hasAttachments() => attachments.isNotEmpty;

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'az önce';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskComment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content &&
          userId == other.userId &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^ content.hashCode ^ userId.hashCode ^ createdAt.hashCode;

  @override
  String toString() {
    return 'TaskComment(id: $id, content: $content)';
  }
}