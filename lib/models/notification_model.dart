import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // task_assigned, task_updated, comment_added, etc.
  final String userId; // Bildirimin gönderileceği kullanıcı
  final String? taskId; // İlgili görev varsa
  final String? senderId; // Bildirimi oluşturan kullanıcı
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.userId,
    this.taskId,
    this.senderId,
    required this.createdAt,
    this.isRead = false,
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
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
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
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] as bool? ?? false,
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
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      senderId: senderId ?? this.senderId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  // Bildirim türleri
  static const String typeTaskAssigned = 'task_assigned';
  static const String typeTaskUpdated = 'task_updated';
  static const String typeCommentAdded = 'comment_added';
  static const String typeTaskCompleted = 'task_completed';
  static const String typeTaskOverdue = 'task_overdue';
  static const String typeTaskReminder = 'task_reminder';
  static const String typeMeetingInvite = 'meeting_invite';
  static const String typeMeetingUpdate = 'meeting_update';
  static const String typeMeetingCancelled = 'meeting_cancelled';
  static const String typeMeetingReminder = 'meeting_reminder';
  static const String typeMeetingNote = 'meeting_note';
  static const String typeMeetingAgenda = 'meeting_agenda';
  static const String typeMeetingStatus = 'meeting_status';
  static const String typeMeetingRemoved = 'meeting_removed';

  // Bildirim başlıkları
  static String getTitle(String type) {
    switch (type) {
      case typeTaskAssigned:
        return 'Yeni Görev Atandı';
      case typeTaskUpdated:
        return 'Görev Güncellendi';
      case typeCommentAdded:
        return 'Yeni Yorum';
      case typeTaskCompleted:
        return 'Görev Tamamlandı';
      case typeTaskOverdue:
        return 'Geciken Görev';
      case typeTaskReminder:
        return 'Görev Hatırlatması';
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
      default:
        return 'Bildirim';
    }
  }
} 