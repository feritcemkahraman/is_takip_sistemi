import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../services/user_service.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final String _serverUrl = 'https://is-takip-notification.onrender.com';
  final UserService? userService;

  NotificationService({this.userService}) {
    _initNotifications();
  }

  Future<void> initialize() async {
    await _initNotifications();
  }

  Future<void> _initNotifications() async {
    // FCM için izinleri al
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // FCM token'ı al
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Ön plandaki mesajları dinle
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Ön planda mesaj alındı: ${message.notification?.title}');
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
          'data': data,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Bildirim gönderilemedi: ${response.body}');
      }
    } catch (e) {
      print('Bildirim gönderme hatası: $e');
      rethrow;
    }
  }
}