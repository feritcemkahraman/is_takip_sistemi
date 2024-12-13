import 'package:cloud_firestore/cloud_firestore.dart';

class WorkflowHistory {
  final String id;
  final String workflowId;
  final String action;
  final String userId;
  final String? details;
  final DateTime timestamp;

  static const String actionCreated = 'created';
  static const String actionUpdated = 'updated';
  static const String actionStepCompleted = 'step_completed';
  static const String actionStepRejected = 'step_rejected';
  static const String actionStepSkipped = 'step_skipped';
  static const String actionCommentAdded = 'comment_added';
  static const String actionFileAdded = 'file_added';
  static const String actionFileRemoved = 'file_removed';

  WorkflowHistory({
    required this.id,
    required this.workflowId,
    required this.action,
    required this.userId,
    this.details,
    required this.timestamp,
  });

  factory WorkflowHistory.fromMap(Map<String, dynamic> map) {
    return WorkflowHistory(
      id: map['id'] as String,
      workflowId: map['workflowId'] as String,
      action: map['action'] as String,
      userId: map['userId'] as String,
      details: map['details'] as String?,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workflowId': workflowId,
      'action': action,
      'userId': userId,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  String getActionText() {
    switch (action) {
      case actionCreated:
        return 'İş akışı oluşturuldu';
      case actionUpdated:
        return 'İş akışı güncellendi';
      case actionStepCompleted:
        return 'Adım tamamlandı';
      case actionStepRejected:
        return 'Adım reddedildi';
      case actionStepSkipped:
        return 'Adım atlandı';
      case actionCommentAdded:
        return 'Yorum eklendi';
      case actionFileAdded:
        return 'Dosya eklendi';
      case actionFileRemoved:
        return 'Dosya kaldırıldı';
      default:
        return 'Bilinmeyen işlem';
    }
  }
}
