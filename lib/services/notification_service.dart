import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_settings.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String senderId = '795393167329';
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';
  static const String _serverKey = 'YOUR_SERVER_KEY'; // Firebase Console'dan alınan Server Key

  // Bildirime tıklandığında çağrılacak callback
  Function(String chatId)? onNotificationTap;

  Future<void> initialize() async {
    // FCM izinlerini al
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // FCM token'ı al
    final token = await _fcm.getToken(
      vapidKey: senderId,
    );
    print('FCM Token: $token');

    // Ön planda bildirim gösterme
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Arka planda bildirim dinleme
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Ön planda bildirim dinleme
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Bildirime tıklama
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Ön planda mesaj alındı: ${message.data}');

    // Bildirim ayarlarını kontrol et
    if (message.data['chatId'] != null && message.data['userId'] != null) {
      final settings = await _getChatNotificationSettings(
        message.data['chatId'],
        message.data['userId'],
      );

      // Sohbet sessize alınmışsa bildirim gösterme
      if (settings.isMuted) return;
    }
  }

  Future<ChatNotificationSettings> _getChatNotificationSettings(
    String chatId,
    String userId,
  ) async {
    try {
      final doc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('notification_settings')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return ChatNotificationSettings(isMuted: false);
      }

      return ChatNotificationSettings.fromMap(doc.data()!);
    } catch (e) {
      print('Bildirim ayarları alınamadı: $e');
      return ChatNotificationSettings(isMuted: false);
    }
  }

  Future<void> _handleNotificationOpen(RemoteMessage message) async {
    print('Bildirim açıldı: ${message.data}');
    final chatId = message.data['chatId'];
    if (chatId != null && onNotificationTap != null) {
      onNotificationTap!(chatId);
    }
  }

  // Token'ı güncelle
  Future<void> updateToken(String userId) async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  // Bildirim ayarlarını getir
  Future<ChatNotificationSettings> getNotificationSettings(
    String chatId,
    String userId,
  ) async {
    try {
      final doc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('notification_settings')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return ChatNotificationSettings(isMuted: false);
      }

      return ChatNotificationSettings.fromMap(doc.data()!);
    } catch (e) {
      print('Bildirim ayarları alınamadı: $e');
      return ChatNotificationSettings(isMuted: false);
    }
  }

  // Belirli bir konuya abone ol
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  // Belirli bir konudan çık
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  Future<void> _sendFcmMessage({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('FCM isteği başarısız: ${response.statusCode}');
      }
    } catch (e) {
      print('FCM mesajı gönderilemedi: $e');
      rethrow;
    }
  }

  // Görev tamamlandığında bildirim gönder
  Future<void> sendTaskCompletionNotification({
    required String taskId,
    required String taskTitle,
    required String completedBy,
    required String assignedTo,
  }) async {
    try {
      final notification = {
        'type': 'task_completed',
        'taskId': taskId,
        'title': 'Görev Tamamlandı',
        'message': '$completedBy, "$taskTitle" görevini tamamladı',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': assignedTo,
        'isRead': false,
      };

      await _firestore.collection('notifications').add(notification);
      
      final userDoc = await _firestore.collection('users').doc(assignedTo).get();
      final fcmToken = userDoc.data()?['fcmToken'];
      
      if (fcmToken != null) {
        await _sendFcmMessage(
          token: fcmToken,
          title: 'Görev Tamamlandı',
          body: '$completedBy, "$taskTitle" görevini tamamladı',
          data: {
            'type': 'task_completed',
            'taskId': taskId,
          },
        );
      }
    } catch (e) {
      print('Bildirim gönderilemedi: $e');
    }
  }

  // Görev atandığında bildirim gönder
  Future<void> sendTaskAssignmentNotification({
    required String taskId,
    required String taskTitle,
    required String assignedBy,
    required String assignedTo,
  }) async {
    try {
      final notification = {
        'type': 'task_assigned',
        'taskId': taskId,
        'title': 'Yeni Görev Atandı',
        'message': '$assignedBy size "$taskTitle" görevini atadı',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': assignedTo,
        'isRead': false,
      };

      await _firestore.collection('notifications').add(notification);
      
      final userDoc = await _firestore.collection('users').doc(assignedTo).get();
      final fcmToken = userDoc.data()?['fcmToken'];
      
      if (fcmToken != null) {
        await _sendFcmMessage(
          token: fcmToken,
          title: 'Yeni Görev Atandı',
          body: '$assignedBy size "$taskTitle" görevini atadı',
          data: {
            'type': 'task_assigned',
            'taskId': taskId,
          },
        );
      }
    } catch (e) {
      print('Görev atama bildirimi gönderilemedi: $e');
    }
  }

  // Görev yeniden atandığında bildirim gönder
  Future<void> sendTaskReassignmentNotification({
    required String taskId,
    required String taskTitle,
    required String assignedBy,
    required String newAssignee,
    required String assignedTo,
  }) async {
    try {
      final notification = {
        'type': 'task_reassigned',
        'taskId': taskId,
        'title': 'Görev Yeniden Atandı',
        'message': '$assignedBy, "$taskTitle" görevini ${newAssignee}\'e yeniden atadı',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': assignedTo,
        'isRead': false,
      };

      await _firestore.collection('notifications').add(notification);
      
      final userDoc = await _firestore.collection('users').doc(assignedTo).get();
      final fcmToken = userDoc.data()?['fcmToken'];
      
      if (fcmToken != null) {
        await _sendFcmMessage(
          token: fcmToken,
          title: 'Görev Yeniden Atandı',
          body: '$assignedBy, "$taskTitle" görevini ${newAssignee}\'e yeniden atadı',
          data: {
            'type': 'task_reassigned',
            'taskId': taskId,
          },
        );
      }
    } catch (e) {
      print('Görev yeniden atama bildirimi gönderilemedi: $e');
    }
  }

  // Bildirimi okundu olarak işaretle
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Bildirim okundu olarak işaretlenemedi: $e');
    }
  }

  // Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Bildirimler okundu olarak işaretlenemedi: $e');
    }
  }

  // Bildirimleri getir (geliştirilmiş sıralama ve filtreleme)
  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50) // Son 50 bildirimi getir
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                  'formattedTimestamp': _formatTimestamp(doc.data()['timestamp'] as Timestamp),
                })
            .toList());
  }

  // Zaman damgasını formatla
  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Bildirim gönder
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Kullanıcının FCM token'ını al
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken == null) {
        print('FCM token bulunamadı: $userId');
        return;
      }

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
          'to': fcmToken,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Bildirim gönderilemedi: ${response.body}');
      }

      // Bildirimi veritabanına kaydet
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Bildirim gönderme hatası: $e');
      throw e;
    }
  }
}

// Arka plan mesaj işleyici
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Arka planda mesaj alındı: ${message.data}');
}