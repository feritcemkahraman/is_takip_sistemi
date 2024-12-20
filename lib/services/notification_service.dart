import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Bildirim sunucusu URL'i (Render.com'dan alacağınız URL'i buraya yazın)
  final String _serverUrl = 'https://is-takip-bildirim-sunucusu.onrender.com';

  Future<void> initialize() async {
    // FCM izinlerini al
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // FCM token'ı al ve kaydet
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await saveFcmToken(token);
    }

    // Token yenilendiğinde
    _firebaseMessaging.onTokenRefresh.listen((token) async {
      await saveFcmToken(token);
    });

    // Yerel bildirimleri ayarla
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);

    // Ön planda bildirim gösterme
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  Future<void> saveFcmToken(String token) async {
    await _firestore.collection('fcm_tokens').doc(token).set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Varsayılan Kanal',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: json.encode(message.data),
    );
  }

  Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/send-notification'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': token,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Bildirim gönderilirken hata oluştu: ${response.body}');
      }
    } catch (e) {
      print('Bildirim gönderme hatası: $e');
      rethrow;
    }
  }
}