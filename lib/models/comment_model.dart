import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      userId: data['userId'] as String,
      content: data['content'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
