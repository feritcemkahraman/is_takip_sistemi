import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String content;
  final String userId;
  final DateTime createdAt;
  final String? parentId;
  final List<String> attachments;
  final Map<String, dynamic>? metadata;

  Comment({
    required this.id,
    required this.content,
    required this.userId,
    required this.createdAt,
    this.parentId,
    this.attachments = const [],
    this.metadata,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      content: data['content'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      parentId: data['parentId'],
      attachments: List<String>.from(data['attachments'] ?? []),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'parentId': parentId,
      'attachments': attachments,
      'metadata': metadata,
    };
  }
}
