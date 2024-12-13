import 'package:cloud_firestore/cloud_firestore.dart';

class WorkflowNotification {
  final String id;
  final String workflowId;
  final String userId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  final Map<String, dynamic>? additionalData;

  static const String typeNewWorkflow = 'new_workflow';
  static const String typeWorkflowUpdated = 'workflow_updated';
  static const String typeStepAssigned = 'step_assigned';
  static const String typeStepCompleted = 'step_completed';
  static const String typeStepRejected = 'step_rejected';
  static const String typeCommentAdded = 'comment_added';
  static const String typeFileAdded = 'file_added';
  static const String typeDeadlineApproaching = 'deadline_approaching';
  static const String typeDeadlineMissed = 'deadline_missed';

  WorkflowNotification({
    required this.id,
    required this.workflowId,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.additionalData,
  });

  factory WorkflowNotification.fromMap(Map<String, dynamic> map) {
    return WorkflowNotification(
      id: map['id'] as String,
      workflowId: map['workflowId'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] as bool,
      type: map['type'] as String,
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workflowId': workflowId,
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type,
      'additionalData': additionalData,
    };
  }

  WorkflowNotification copyWith({
    String? id,
    String? workflowId,
    String? userId,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    Map<String, dynamic>? additionalData,
  }) {
    return WorkflowNotification(
      id: id ?? this.id,
      workflowId: workflowId ?? this.workflowId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  String getNotificationTypeText() {
    switch (type) {
      case typeNewWorkflow:
        return 'Yeni İş Akışı';
      case typeWorkflowUpdated:
        return 'İş Akışı Güncellendi';
      case typeStepAssigned:
        return 'Adım Atandı';
      case typeStepCompleted:
        return 'Adım Tamamlandı';
      case typeStepRejected:
        return 'Adım Reddedildi';
      case typeCommentAdded:
        return 'Yeni Yorum';
      case typeFileAdded:
        return 'Yeni Dosya';
      case typeDeadlineApproaching:
        return 'Yaklaşan Son Tarih';
      case typeDeadlineMissed:
        return 'Son Tarih Geçti';
      default:
        return 'Bildirim';
    }
  }
}
