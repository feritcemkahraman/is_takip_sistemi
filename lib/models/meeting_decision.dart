import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingDecision {
  final String id;
  final String meetingId;
  final String content;
  final String createdBy;
  final DateTime createdAt;
  final List<String> assignedTo;
  final DateTime? dueDate;
  final String status;
  final List<String> attachments;
  final Map<String, dynamic>? metadata;

  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  MeetingDecision({
    required this.id,
    required this.meetingId,
    required this.content,
    required this.createdBy,
    required this.createdAt,
    required this.assignedTo,
    this.dueDate,
    this.status = statusPending,
    this.attachments = const [],
    this.metadata,
  });

  factory MeetingDecision.fromFirestore(Map<String, dynamic> data) {
    return MeetingDecision(
      id: data['id'] ?? '',
      meetingId: data['meetingId'] ?? '',
      content: data['content'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      assignedTo: List<String>.from(data['assignedTo'] ?? []),
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      status: data['status'] ?? statusPending,
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
      'assignedTo': assignedTo,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status,
      'attachments': attachments,
      'metadata': metadata,
    };
  }

  bool isPending() => status == statusPending;
  bool isInProgress() => status == statusInProgress;
  bool isCompleted() => status == statusCompleted;
  bool isCancelled() => status == statusCancelled;

  bool hasAttachments() => attachments.isNotEmpty;
  bool isOverdue() => dueDate != null && DateTime.now().isAfter(dueDate!);
}
