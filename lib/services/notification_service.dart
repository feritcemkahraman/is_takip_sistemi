import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/workflow_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore;
  final String _collection = 'notifications';

  NotificationService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  // Bildirim oluşturma
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore.collection(_collection).add(notification.toMap());
    } catch (e) {
      print('Bildirim oluşturma hatası: $e');
      rethrow;
    }
  }

  // Bildirim silme
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      print('Bildirim silme hatası: $e');
      rethrow;
    }
  }

  // Tüm bildirimleri silme
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Tüm bildirimleri silme hatası: $e');
      rethrow;
    }
  }

  // Bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Bildirim okundu işaretleme hatası: $e');
      rethrow;
    }
  }

  // Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Tüm bildirimleri okundu işaretleme hatası: $e');
      rethrow;
    }
  }

  // Kullanıcının bildirimlerini getir
  Stream<List<NotificationModel>> getNotifications(String userId) {
    try {
      return _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      print('Bildirimleri getirme hatası: $e');
      rethrow;
    }
  }

  // Okunmamış bildirim sayısını getir
  Stream<int> getUnreadCount(String userId) {
    try {
      return _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('Okunmamış bildirim sayısı getirme hatası: $e');
      rethrow;
    }
  }

  // Görev bildirimi gönder
  Future<void> sendTaskNotification(TaskModel task, String action) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: task.assignedTo,
        title: 'Görev: ${task.title}',
        body: _getTaskNotificationBody(task, action),
        type: NotificationModel.typeTask,
        data: {'taskId': task.id},
        createdAt: DateTime.now(),
      );

      await createNotification(notification);
    } catch (e) {
      print('Görev bildirimi gönderme hatası: $e');
      rethrow;
    }
  }

  // Toplantı bildirimi gönder
  Future<void> sendMeetingNotification(
      MeetingModel meeting, String action) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: meeting.organizerId,
        title: 'Toplantı: ${meeting.title}',
        body: _getMeetingNotificationBody(meeting, action),
        type: NotificationModel.typeMeeting,
        data: {'meetingId': meeting.id},
        createdAt: DateTime.now(),
      );

      await createNotification(notification);
    } catch (e) {
      print('Toplantı bildirimi gönderme hatası: $e');
      rethrow;
    }
  }

  // İş akışı bildirimi gönder
  Future<void> sendWorkflowNotification(
      WorkflowModel workflow, String action) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: workflow.assignedTo,
        title: 'İş Akışı: ${workflow.title}',
        body: _getWorkflowNotificationBody(workflow, action),
        type: NotificationModel.typeWorkflow,
        data: {'workflowId': workflow.id},
        createdAt: DateTime.now(),
      );

      await createNotification(notification);
    } catch (e) {
      print('İş akışı bildirimi gönderme hatası: $e');
      rethrow;
    }
  }

  // Bildirim izinlerini iste
  Future<void> requestPermissions() async {
    try {
      // Platform'a göre bildirim izinlerini iste
      // TODO: Platform spesifik izin istekleri eklenecek
    } catch (e) {
      print('Bildirim izni isteme hatası: $e');
      rethrow;
    }
  }

  // Bildirim servisini başlat
  Future<void> initialize() async {
    try {
      // Bildirim servisini başlat
      await requestPermissions();
      // TODO: Platform spesifik başlatma işlemleri eklenecek
    } catch (e) {
      print('Bildirim servisi başlatma hatası: $e');
      rethrow;
    }
  }

  // Görev bildirimi metni
  String _getTaskNotificationBody(TaskModel task, String action) {
    switch (action) {
      case 'created':
        return 'Size yeni bir görev atandı';
      case 'updated':
        return 'Görev güncellendi';
      case 'completed':
        return 'Görev tamamlandı';
      case 'overdue':
        return 'Görev süresi doldu';
      default:
        return 'Görev durumu değişti';
    }
  }

  // Toplantı bildirimi metni
  String _getMeetingNotificationBody(MeetingModel meeting, String action) {
    switch (action) {
      case 'created':
        return 'Yeni bir toplantı oluşturuldu';
      case 'updated':
        return 'Toplantı detayları güncellendi';
      case 'cancelled':
        return 'Toplantı iptal edildi';
      case 'reminder':
        return 'Toplantı yaklaşıyor';
      default:
        return 'Toplantı durumu değişti';
    }
  }

  // İş akışı bildirimi metni
  String _getWorkflowNotificationBody(WorkflowModel workflow, String action) {
    switch (action) {
      case 'created':
        return 'Size yeni bir iş akışı atandı';
      case 'updated':
        return 'İş akışı güncellendi';
      case 'completed':
        return 'İş akışı tamamlandı';
      case 'overdue':
        return 'İş akışı süresi doldu';
      default:
        return 'İş akışı durumu değişti';
    }
  }

  // Kaynakları temizleme
  void dispose() {
    // Firestore bağlantısını kapatma işlemleri burada yapılabilir
    // Şu an için özel bir temizleme işlemi gerekmiyor
  }
}