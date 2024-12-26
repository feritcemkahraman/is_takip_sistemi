import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:is_takip_sistemi/config/api_config.dart';
import 'package:is_takip_sistemi/models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final http.Client _client = http.Client();
  late final io.Socket _socket;

  Future<void> initialize() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    await _connectSocket();
  }

  Future<void> _connectSocket() async {
    final token = await _getToken();
    if (token != null) {
      _socket.io.options?['extraHeaders'] = {
        'Authorization': 'Bearer $token'
      };
      _socket.connect();
      _socket.on('notification', _handleNotification);
    }
  }

  void _handleNotification(dynamic data) {
    if (data != null) {
      final notification = NotificationModel.fromJson(data);
      showNotification(
        notification.id,
        notification.title,
        notification.body,
      );
    }
  }

  Future<void> _onNotificationTap(NotificationResponse response) async {
    // TODO: Bildirime tıklandığında yapılacak işlemler
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> showNotification(
    String id,
    String title,
    String body, {
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id.hashCode,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<List<NotificationModel>> getNotifications() async {
    final token = await _getToken();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notifications}'),
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } else {
      throw Exception('Bildirimler alınamadı');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final token = await _getToken();
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.markNotificationRead}$notificationId'),
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode != 200) {
      throw Exception('Bildirim okundu olarak işaretlenemedi');
    }
  }

  Future<void> markAllAsRead() async {
    final token = await _getToken();
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notifications}/read-all'),
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode != 200) {
      throw Exception('Bildirimler okundu olarak işaretlenemedi');
    }
  }

  Stream<NotificationModel> onNewNotification() {
    return _socket.fromEvent('notification').map((data) {
      return NotificationModel.fromJson(data);
    });
  }

  void dispose() {
    _socket.dispose();
    _client.close();
  }
}