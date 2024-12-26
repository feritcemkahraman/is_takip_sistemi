import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final payloadData = response.payload!.split(':');
      if (payloadData.length == 2) {
        final type = payloadData[0];
        final id = payloadData[1];

        switch (type) {
          case 'task':
            navigatorKey.currentState?.pushNamed('/task-details', arguments: id);
            break;
          case 'message':
            navigatorKey.currentState?.pushNamed('/chat', arguments: id);
            break;
        }
      }
    }
  }

  static Future<void> showTaskNotification({
    required String title,
    required String body,
    String? taskId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tasks_channel',
      'Görev Bildirimleri',
      channelDescription: 'Görevlerle ilgili bildirimler',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification.aiff',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: taskId != null ? 'task:$taskId' : null,
    );
  }

  static Future<void> showMessageNotification({
    required String title,
    required String body,
    String? messageId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'messages_channel',
      'Mesaj Bildirimleri',
      channelDescription: 'Mesajlarla ilgili bildirimler',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('message'),
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'message.aiff',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: messageId != null ? 'message:$messageId' : null,
    );
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}