import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String userId;
  final String? taskId;
  final String? senderId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.userId,
    this.taskId,
    this.senderId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'userId': userId,
      'taskId': taskId,
      'senderId': senderId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      type: map['type'] as String,
      userId: map['userId'] as String,
      taskId: map['taskId'] as String?,
      senderId: map['senderId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? userId,
    String? taskId,
    String? senderId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      senderId: senderId ?? this.senderId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Bildirim tipleri
  static const String typeTaskAssigned = 'task_assigned';
  static const String typeTaskUpdated = 'task_updated';
  static const String typeTaskCompleted = 'task_completed';
  static const String typeTaskOverdue = 'task_overdue';
  static const String typeTaskReminder = 'task_reminder';
  static const String typeTaskComment = 'task_comment';
  static const String typeTaskStatusChanged = 'task_status_changed';
  static const String typeTaskRemoved = 'task_removed';
  static const String typeMeetingInvite = 'meeting_invite';
  static const String typeMeetingUpdate = 'meeting_update';
  static const String typeMeetingCancelled = 'meeting_cancelled';
  static const String typeMeetingReminder = 'meeting_reminder';
  static const String typeMeetingNote = 'meeting_note';
  static const String typeMeetingAgenda = 'meeting_agenda';
  static const String typeMeetingStatus = 'meeting_status';
  static const String typeMeetingRemoved = 'meeting_removed';
  static const String typeMeetingMinutes = 'meeting_minutes';
  static const String typeMeetingDecision = 'meeting_decision';
  static const String typeMeetingDecisionOverdue = 'meeting_decision_overdue';

  static String getTitle(String type) {
    switch (type) {
      case typeTaskAssigned:
        return 'Yeni Görev Atandı';
      case typeTaskUpdated:
        return 'Görev Güncellendi';
      case typeTaskCompleted:
        return 'Görev Tamamlandı';
      case typeTaskOverdue:
        return 'Görev Gecikti';
      case typeTaskReminder:
        return 'Görev Hatırlatması';
      case typeTaskComment:
        return 'Yeni Görev Yorumu';
      case typeTaskStatusChanged:
        return 'Görev Durumu Değişti';
      case typeTaskRemoved:
        return 'Görevden Çıkarıldınız';
      case typeMeetingInvite:
        return 'Yeni Toplantı Daveti';
      case typeMeetingUpdate:
        return 'Toplantı Güncellendi';
      case typeMeetingCancelled:
        return 'Toplantı İptal Edildi';
      case typeMeetingReminder:
        return 'Toplantı Hatırlatması';
      case typeMeetingNote:
        return 'Yeni Toplantı Notu';
      case typeMeetingAgenda:
        return 'Yeni Gündem Maddesi';
      case typeMeetingStatus:
        return 'Toplantı Durumu';
      case typeMeetingRemoved:
        return 'Toplantıdan Çıkarıldınız';
      case typeMeetingMinutes:
        return 'Toplantı Tutanağı';
      case typeMeetingDecision:
        return 'Toplantı Kararı';
      case typeMeetingDecisionOverdue:
        return 'Toplantı Kararı Gecikti';
      default:
        return 'Bildirim';
    }
  }
} 