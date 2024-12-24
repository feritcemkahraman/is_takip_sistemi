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

  Future<bool> checkNotificationPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    print('Bildirim izin durumu: ${settings.authorizationStatus}');
    
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        print('Bildirim izinleri verildi');
        return true;
      case AuthorizationStatus.provisional:
        print('Geçici bildirim izni verildi');
        return true;
      case AuthorizationStatus.denied:
        print('Bildirim izinleri reddedildi');
        return false;
      default:
        print('Bilinmeyen bildirim izin durumu');
        return false;
    }
  }

  Future<void> _initNotifications() async {
    final hasPermission = await checkNotificationPermission();
    if (!hasPermission) {
      print('Bildirim izinleri alınamadı');
      return;
    }

    // FCM token'ı al
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Ön plandaki mesajları dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Ön planda mesaj alındı:');
      print('Başlık: ${message.notification?.title}');
      print('İçerik: ${message.notification?.body}');
      print('Data: ${message.data}');
    });

    // Arka plandaki mesajları dinle
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Arka planda mesaj alındı:');
    print('Başlık: ${message.notification?.title}');
    print('İçerik: ${message.notification?.body}');
    print('Data: ${message.data}');
  }

  Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('Bildirim gönderiliyor - Token: $token, Başlık: $title');
      
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

      if (response.statusCode == 200) {
        print('Bildirim başarıyla gönderildi');
        final responseData = jsonDecode(response.body);
        print('Sunucu yanıtı: $responseData');
      } else {
        print('Bildirim gönderme hatası - Status: ${response.statusCode}');
        print('Hata detayı: ${response.body}');
        throw Exception('Bildirim gönderilemedi (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('Bildirim gönderme hatası: $e');
      if (e is http.ClientException) {
        print('Ağ hatası: ${e.message}');
        throw Exception('Sunucuya bağlanılamadı: ${e.message}');
      } else {
        rethrow;
      }
    }
  }
}