import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingMinutes {
  final String id;
  final String meetingId;
  final String content;
  final String createdBy;
  final DateTime createdAt;
  final List<String> attachments;
  final Map<String, dynamic>? metadata;

  MeetingMinutes({
    required this.id,
    required this.meetingId,
    required this.content,
    required this.createdBy,
    required this.createdAt,
    this.attachments = const [],
    this.metadata,
  });

  factory MeetingMinutes.fromFirestore(Map<String, dynamic> data) {
    return MeetingMinutes(
      id: data['id'] ?? '',
      meetingId: data['meetingId'] ?? '',
      content: data['content'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      attachments: List<String>.from(data['attachments'] ?? []),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meetingId': meetingId,
      'content': content,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'attachments': attachments,
      'metadata': metadata,
    };
  }

  bool hasAttachments() => attachments.isNotEmpty;
}
