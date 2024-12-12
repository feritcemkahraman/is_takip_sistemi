import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import '../models/task_model.dart';
import '../constants/app_constants.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final String _collection = 'notifications';

  // FCM token'ı kaydet
  Future<void> saveToken(String userId) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }
  }

  // Bildirimleri getir
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data()))
            .toList());
  }

  // Okunmamış bildirim sayısını getir
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection(_collection).doc(notificationId).update({
      'isRead': true,
    });
  }

  // Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead(String userId) async {
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
  }

  // Bildirim oluştur
  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    required String userId,
    String? taskId,
    String? senderId,
  }) async {
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
        .collection(_collection)
        .doc(notification.id)
        .set(notification.toMap());

    // FCM bildirimi gönder
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final fcmToken = userDoc.data()?['fcmToken'] as String?;

    if (fcmToken != null) {
      await _messaging.sendMessage(
        to: fcmToken,
        data: {
          'title': title,
          'body': message,
          'type': type,
          'taskId': taskId ?? '',
        },
      );
    }
  }

  // Görev atandığında bildirim gönder
  Future<void> sendTaskAssignedNotification(TaskModel task) async {
    await createNotification(
      title: NotificationModel.getTitle(NotificationModel.typeTaskAssigned),
      message: '${task.title} görevi size atandı',
      type: NotificationModel.typeTaskAssigned,
      userId: task.assignedTo,
      taskId: task.id,
      senderId: task.createdBy,
    );
  }

  // Görev güncellendiğinde bildirim gönder
  Future<void> sendTaskUpdatedNotification(TaskModel task) async {
    final watchers = [...task.watchers];
    if (!watchers.contains(task.assignedTo)) {
      watchers.add(task.assignedTo);
    }

    for (final userId in watchers) {
      await createNotification(
        title: NotificationModel.getTitle(NotificationModel.typeTaskUpdated),
        message: '${task.title} görevi güncellendi',
        type: NotificationModel.typeTaskUpdated,
        userId: userId,
        taskId: task.id,
      );
    }
  }

  // Yorum eklendiğinde bildirim gönder
  Future<void> sendCommentAddedNotification(
    TaskModel task,
    Comment comment,
  ) async {
    final watchers = [...task.watchers];
    if (!watchers.contains(task.assignedTo)) {
      watchers.add(task.assignedTo);
    }

    for (final userId in watchers) {
      if (userId != comment.userId) {
        await createNotification(
          title: NotificationModel.getTitle(NotificationModel.typeCommentAdded),
          message: '${task.title} görevine yeni bir yorum eklendi',
          type: NotificationModel.typeCommentAdded,
          userId: userId,
          taskId: task.id,
          senderId: comment.userId,
        );
      }
    }
  }

  // Görev tamamlandığında bildirim gönder
  Future<void> sendTaskCompletedNotification(TaskModel task) async {
    final watchers = [...task.watchers];
    if (!watchers.contains(task.createdBy)) {
      watchers.add(task.createdBy);
    }

    for (final userId in watchers) {
      if (userId != task.assignedTo) {
        await createNotification(
          title: NotificationModel.getTitle(NotificationModel.typeTaskCompleted),
          message: '${task.title} görevi tamamlandı',
          type: NotificationModel.typeTaskCompleted,
          userId: userId,
          taskId: task.id,
          senderId: task.assignedTo,
        );
      }
    }
  }

  // Geciken görevler için bildirim gönder
  Future<void> sendTaskOverdueNotification(TaskModel task) async {
    final watchers = [...task.watchers];
    if (!watchers.contains(task.assignedTo)) {
      watchers.add(task.assignedTo);
    }
    if (!watchers.contains(task.createdBy)) {
      watchers.add(task.createdBy);
    }

    for (final userId in watchers) {
      await createNotification(
        title: NotificationModel.getTitle(NotificationModel.typeTaskOverdue),
        message: '${task.title} görevi gecikti',
        type: NotificationModel.typeTaskOverdue,
        userId: userId,
        taskId: task.id,
      );
    }
  }

  // Görev hatırlatması gönder
  Future<void> sendTaskReminderNotification(TaskModel task) async {
    await createNotification(
      title: NotificationModel.getTitle(NotificationModel.typeTaskReminder),
      message: '${task.title} görevi için son teslim tarihi yaklaşıyor',
      type: NotificationModel.typeTaskReminder,
      userId: task.assignedTo,
      taskId: task.id,
    );
  }
} 