import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../models/meeting_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    required String userId,
    String? taskId,
    String? senderId,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: type,
        userId: userId,
        taskId: taskId,
        senderId: senderId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('Bildirim oluşturulurken bir hata oluştu: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Bildirim okundu olarak işaretlenirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Bildirim silinirken bir hata oluştu: $e');
    }
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data()))
            .toList());
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Okunmamış bildirim sayısı alınırken bir hata oluştu: $e');
    }
  }

  // Toplantı tutanağı eklendi bildirimi
  Future<void> sendMeetingMinutesAddedNotification(MeetingModel meeting) async {
    for (final participant in meeting.participants) {
      await createNotification(
        title: NotificationModel.getTitle(NotificationModel.typeMeetingMinutes),
        message: '${meeting.title} toplantısına yeni tutanak eklendi',
        type: NotificationModel.typeMeetingMinutes,
        userId: participant.userId,
        taskId: meeting.id,
        senderId: meeting.organizerId,
      );
    }
  }

  // Toplantı tutanağı onaylandı bildirimi
  Future<void> sendMeetingMinutesApprovedNotification(MeetingModel meeting) async {
    for (final participant in meeting.participants) {
      await createNotification(
        title: NotificationModel.getTitle(NotificationModel.typeMeetingMinutes),
        message: '${meeting.title} toplantısının tutanağı onaylandı',
        type: NotificationModel.typeMeetingMinutes,
        userId: participant.userId,
        taskId: meeting.id,
        senderId: meeting.minutes?.approvedBy,
      );
    }
  }

  // Toplantı kararı eklendi bildirimi
  Future<void> sendMeetingDecisionAddedNotification(
    MeetingModel meeting,
    MeetingDecision decision,
  ) async {
    // Sorumlu kişiye bildirim gönder
    if (decision.assignedTo != null) {
      await createNotification(
        title: NotificationModel.getTitle(NotificationModel.typeMeetingDecision),
        message: '${meeting.title} toplantısında size yeni bir görev atandı',
        type: NotificationModel.typeMeetingDecision,
        userId: decision.assignedTo!,
        taskId: meeting.id,
        senderId: decision.createdBy,
      );
    }

    // Toplantı organizatörüne bildirim gönder
    if (meeting.organizerId != decision.createdBy) {
      await createNotification(
        title: NotificationModel.getTitle(NotificationModel.typeMeetingDecision),
        message: '${meeting.title} toplantısına yeni bir karar eklendi',
        type: NotificationModel.typeMeetingDecision,
        userId: meeting.organizerId,
        taskId: meeting.id,
        senderId: decision.createdBy,
      );
    }
  }

  // Toplantı kararı güncellendi bildirimi
  Future<void> sendMeetingDecisionUpdatedNotification(
    MeetingModel meeting,
    MeetingDecision decision,
  ) async {
    final List<String> notifyUsers = [meeting.organizerId];
    
    if (decision.assignedTo != null) {
      notifyUsers.add(decision.assignedTo!);
    }

    for (final userId in notifyUsers) {
      if (userId != decision.createdBy) {
        await createNotification(
          title: NotificationModel.getTitle(NotificationModel.typeMeetingDecision),
          message: '${meeting.title} toplantısındaki bir karar güncellendi',
          type: NotificationModel.typeMeetingDecision,
          userId: userId,
          taskId: meeting.id,
          senderId: decision.createdBy,
        );
      }
    }
  }

  // Toplantı kararı tamamlandı bildirimi
  Future<void> sendMeetingDecisionCompletedNotification(
    MeetingModel meeting,
    MeetingDecision decision,
  ) async {
    await createNotification(
      title: NotificationModel.getTitle(NotificationModel.typeMeetingDecision),
      message: '${meeting.title} toplantısındaki bir karar tamamlandı',
      type: NotificationModel.typeMeetingDecision,
      userId: meeting.organizerId,
      taskId: meeting.id,
      senderId: decision.assignedTo,
    );
  }

  // Toplantı kararı iptal edildi bildirimi
  Future<void> sendMeetingDecisionCancelledNotification(
    MeetingModel meeting,
    MeetingDecision decision,
  ) async {
    final List<String> notifyUsers = [meeting.organizerId];
    
    if (decision.assignedTo != null) {
      notifyUsers.add(decision.assignedTo!);
    }

    for (final userId in notifyUsers) {
      if (userId != decision.createdBy) {
        await createNotification(
          title: NotificationModel.getTitle(NotificationModel.typeMeetingDecision),
          message: '${meeting.title} toplantısındaki bir karar iptal edildi',
          type: NotificationModel.typeMeetingDecision,
          userId: userId,
          taskId: meeting.id,
          senderId: decision.createdBy,
        );
      }
    }
  }

  // Toplantı kararı gecikti bildirimi
  Future<void> sendMeetingDecisionOverdueNotification(
    MeetingModel meeting,
    MeetingDecision decision,
  ) async {
    final List<String> notifyUsers = [meeting.organizerId];
    
    if (decision.assignedTo != null) {
      notifyUsers.add(decision.assignedTo!);
    }

    for (final userId in notifyUsers) {
      await createNotification(
        title: NotificationModel.getTitle(NotificationModel.typeMeetingDecisionOverdue),
        message: '${meeting.title} toplantısındaki bir karar gecikti',
        type: NotificationModel.typeMeetingDecisionOverdue,
        userId: userId,
        taskId: meeting.id,
        senderId: decision.createdBy,
      );
    }
  }
} 