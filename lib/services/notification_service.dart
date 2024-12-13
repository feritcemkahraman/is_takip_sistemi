import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import '../models/notification_model.dart';
import '../models/workflow_model.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'logging_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LoggingService _loggingService;

  NotificationService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required LoggingService loggingService,
  })  : _firestore = firestore,
        _auth = auth,
        _loggingService = loggingService;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final BehaviorSubject<NotificationModel> _notificationSubject = BehaviorSubject<NotificationModel>();
  final BehaviorSubject<bool> _connectionSubject = BehaviorSubject<bool>.seeded(true);
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int maxRetries = 3;

  // E-posta ayarları
  final String _smtpHost = 'smtp.gmail.com';
  final int _smtpPort = 587;
  final String _smtpUsername = 'your-email@gmail.com';
  final String _smtpPassword = 'your-app-password';

  // Bildirim izinleri
  Future<NotificationSettings> requestPermissions() async {
    try {
      // FCM izinleri
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
        announcement: true,
        carPlay: true,
      );

      // Yerel bildirim izinleri
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()?.requestPermission();
        await _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
              critical: true,
            );
      }

      return settings;
    } catch (e) {
      print('Bildirim izinleri alınamadı: $e');
      rethrow;
    }
  }

  // Bildirim servisi başlatma
  Future<void> initialize() async {
    try {
      // FCM token alma ve yönetme
      await _initializeFCM();

      // Yerel bildirim ayarları
      await _initializeLocalNotifications();

      // Bildirim dinleyicileri
      _setupNotificationListeners();

      // Bağlantı durumu kontrolü
      _setupConnectionMonitoring();
    } catch (e) {
      print('Bildirim servisi başlatılamadı: $e');
      rethrow;
    }
  }

  // FCM başlatma
  Future<void> _initializeFCM() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _updateFCMToken(token);
      }

      // Token yenilenme dinleyicisi
      _messaging.onTokenRefresh.listen(_updateFCMToken);
    } catch (e) {
      print('FCM başlatılamadı: $e');
      rethrow;
    }
  }

  // Yerel bildirimleri başlatma
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Android bildirim kanalları
    await _createNotificationChannels();
  }

  // Android bildirim kanalları oluşturma
  Future<void> _createNotificationChannels() async {
    const defaultChannel = AndroidNotificationChannel(
      'default_channel',
      'Varsayılan Kanal',
      description: 'Genel bildirimler için varsayılan kanal',
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
    );

    const highPriorityChannel = AndroidNotificationChannel(
      'high_priority_channel',
      'Yüksek Öncelikli Bildirimler',
      description: 'Önemli bildirimler için kanal',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannels([defaultChannel, highPriorityChannel]);
  }

  // Bildirim dinleyicileri
  void _setupNotificationListeners() {
    // Ön planda bildirim dinleyicisi
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Arka planda bildirim dinleyicisi
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Bildirime tıklama dinleyicisi
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
  }

  // Bağlantı durumu kontrolü
  void _setupConnectionMonitoring() {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        await _firestore.runTransaction((transaction) async {});
        _connectionSubject.add(true);
      } catch (e) {
        _connectionSubject.add(false);
      }
    });
  }

  // FCM token güncelleme
  Future<void> _updateFCMToken(String token) async {
    try {
      final userId = await getCurrentUserId();
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayUnion([token])
        });
      }
    } catch (e) {
      print('FCM token güncellenemedi: $e');
      _retryOperation(() => _updateFCMToken(token));
    }
  }

  // Bildirim oluşturma
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      // FCM token'ı al ve push bildirim gönder
      final token = await _getUserFCMToken(notification.userId);
      if (token != null) {
        await _sendPushNotification(
          token,
          notification.title,
          notification.body,
          notification.data,
        );
      }

      // E-posta bildirimi gönder
      await _sendEmailNotification(
        notification.userId,
        notification.title,
        notification.body,
      );
    } catch (e) {
      print('Bildirim oluşturma hatası: $e');
      rethrow;
    }
  }

  // İş akışı bildirimleri
  Future<void> sendWorkflowNotification({
    required String workflowId,
    required String title,
    required String message,
    required String type,
    required List<String> recipients,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    Duration? expiration,
  }) async {
    try {
      final notification = NotificationModel(
        id: const Uuid().v4(),
        title: title,
        message: message,
        type: type,
        priority: priority,
        recipients: recipients,
        data: {
          ...?data,
          'workflowId': workflowId,
        },
        createdAt: DateTime.now(),
        expiresAt: expiration != null
            ? DateTime.now().add(expiration)
            : null,
        status: NotificationStatus.unread,
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      // FCM bildirimi gönder
      await _sendPushNotification(notification);

      await _loggingService.info(
        'İş akışı bildirimi gönderildi',
        module: 'notification',
        data: {
          'notificationId': notification.id,
          'workflowId': workflowId,
          'type': type,
          'recipientCount': recipients.length,
        },
      );
    } catch (e, stackTrace) {
      await _loggingService.error(
        'İş akışı bildirimi gönderme hatası',
        module: 'notification',
        error: e,
        stackTrace: stackTrace,
        data: {
          'workflowId': workflowId,
          'type': type,
          'recipientCount': recipients.length,
        },
      );
      rethrow;
    }
  }

  // İş akışı ilerleme bildirimleri
  Future<void> sendProgressNotification({
    required String workflowId,
    required String stepId,
    required double progress,
    required List<String> recipients,
  }) async {
    try {
      final step = await _getWorkflowStep(workflowId, stepId);
      if (step == null) return;

      final message = _generateProgressMessage(progress, step);
      final type = _getProgressNotificationType(progress);

      await sendWorkflowNotification(
        workflowId: workflowId,
        title: 'İş Akışı İlerlemesi',
        message: message,
        type: type,
        recipients: recipients,
        data: {
          'stepId': stepId,
          'progress': progress,
          'stepTitle': step.title,
        },
        priority: _getProgressPriority(progress),
      );
    } catch (e, stackTrace) {
      await _loggingService.error(
        'İlerleme bildirimi gönderme hatası',
        module: 'notification',
        error: e,
        stackTrace: stackTrace,
        data: {
          'workflowId': workflowId,
          'stepId': stepId,
          'progress': progress,
        },
      );
      rethrow;
    }
  }

  // Gecikme bildirimleri
  Future<void> sendDelayNotification({
    required String workflowId,
    required String stepId,
    required Duration delay,
    required List<String> recipients,
  }) async {
    try {
      final step = await _getWorkflowStep(workflowId, stepId);
      if (step == null) return;

      final message = _generateDelayMessage(delay, step);

      await sendWorkflowNotification(
        workflowId: workflowId,
        title: 'İş Akışı Gecikmesi',
        message: message,
        type: NotificationType.delay,
        recipients: recipients,
        data: {
          'stepId': stepId,
          'delay': delay.inMinutes,
          'stepTitle': step.title,
        },
        priority: NotificationPriority.high,
      );
    } catch (e, stackTrace) {
      await _loggingService.error(
        'Gecikme bildirimi gönderme hatası',
        module: 'notification',
        error: e,
        stackTrace: stackTrace,
        data: {
          'workflowId': workflowId,
          'stepId': stepId,
          'delay': delay.inMinutes,
        },
      );
      rethrow;
    }
  }

  // Kritik durum bildirimleri
  Future<void> sendCriticalNotification({
    required String workflowId,
    required String title,
    required String message,
    required List<String> recipients,
    Map<String, dynamic>? data,
  }) async {
    await sendWorkflowNotification(
      workflowId: workflowId,
      title: '⚠️ $title',
      message: message,
      type: NotificationType.critical,
      recipients: recipients,
      data: data,
      priority: NotificationPriority.critical,
      expiration: const Duration(hours: 24),
    );
  }

  // Bildirim durumu güncelleme
  Future<void> updateNotificationStatus(
    String notificationId,
    String status,
  ) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'status': status});

      await _loggingService.info(
        'Bildirim durumu güncellendi',
        module: 'notification',
        data: {
          'notificationId': notificationId,
          'status': status,
        },
      );
    } catch (e, stackTrace) {
      await _loggingService.error(
        'Bildirim durumu güncelleme hatası',
        module: 'notification',
        error: e,
        stackTrace: stackTrace,
        data: {
          'notificationId': notificationId,
          'status': status,
        },
      );
      rethrow;
    }
  }

  // Yardımcı metodlar
  Future<WorkflowStep?> _getWorkflowStep(
    String workflowId,
    String stepId,
  ) async {
    try {
      final doc = await _firestore
          .collection('workflows')
          .doc(workflowId)
          .get();

      if (!doc.exists) return null;

      final workflow = WorkflowModel.fromMap(doc.data()!);
      return workflow.steps.firstWhere(
        (step) => step.id == stepId,
        orElse: () => throw Exception('Adım bulunamadı'),
      );
    } catch (e) {
      await _loggingService.error(
        'İş akışı adımı getirme hatası',
        module: 'notification',
        error: e,
        data: {
          'workflowId': workflowId,
          'stepId': stepId,
        },
      );
      return null;
    }
  }

  String _generateProgressMessage(double progress, WorkflowStep step) {
    if (progress >= 100) {
      return '${step.title} tamamlandı! 🎉';
    } else if (progress >= 75) {
      return '${step.title} son aşamada (${progress.toStringAsFixed(0)}%)';
    } else if (progress >= 50) {
      return '${step.title} yarıyı geçti (${progress.toStringAsFixed(0)}%)';
    } else if (progress >= 25) {
      return '${step.title} ilerliyor (${progress.toStringAsFixed(0)}%)';
    } else {
      return '${step.title} başladı (${progress.toStringAsFixed(0)}%)';
    }
  }

  String _generateDelayMessage(Duration delay, WorkflowStep step) {
    final hours = delay.inHours;
    final minutes = delay.inMinutes % 60;

    if (hours > 0) {
      return '${step.title} $hours saat ${minutes > 0 ? '$minutes dakika' : ''} gecikti!';
    } else {
      return '${step.title} $minutes dakika gecikti!';
    }
  }

  String _getProgressNotificationType(double progress) {
    if (progress >= 100) return NotificationType.completion;
    if (progress >= 75) return NotificationType.majorProgress;
    if (progress >= 50) return NotificationType.progress;
    if (progress >= 25) return NotificationType.minorProgress;
    return NotificationType.start;
  }

  NotificationPriority _getProgressPriority(double progress) {
    if (progress >= 100) return NotificationPriority.high;
    if (progress >= 75) return NotificationPriority.normal;
    return NotificationPriority.low;
  }

  Future<void> _sendPushNotification(NotificationModel notification) async {
    try {
      // FCM token'larını getir
      final tokens = await _getRecipientTokens(notification.recipients);
      if (tokens.isEmpty) return;

      // FCM mesajını oluştur
      final message = {
        'notification': {
          'title': notification.title,
          'body': notification.message,
        },
        'data': {
          'type': notification.type,
          'id': notification.id,
          ...notification.data,
        },
        'android': {
          'priority': notification.priority == NotificationPriority.critical
              ? 'high'
              : 'normal',
          'notification': {
            'channel_id': 'workflow_notifications',
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'sound': notification.priority == NotificationPriority.critical
                  ? 'critical.wav'
                  : 'default',
            },
          },
        },
        'tokens': tokens,
      };

      // FCM isteği gönder
      await FirebaseMessaging.instance.sendMulticast(
        MulticastMessage.fromMap(message),
      );
    } catch (e, stackTrace) {
      await _loggingService.error(
        'Push bildirimi gönderme hatası',
        module: 'notification',
        error: e,
        stackTrace: stackTrace,
        data: {
          'notificationId': notification.id,
          'recipientCount': notification.recipients.length,
        },
      );
    }
  }

  Future<List<String>> _getRecipientTokens(List<String> userIds) async {
    try {
      final tokens = <String>[];
      for (final userId in userIds) {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('tokens')
            .get();

        tokens.addAll(doc.docs.map((d) => d.id));
      }
      return tokens;
    } catch (e) {
      await _loggingService.error(
        'FCM token getirme hatası',
        module: 'notification',
        error: e,
        data: {
          'userCount': userIds.length,
        },
      );
      return [];
    }
  }

  // İş akışı bildirim metni oluştur
  String _getWorkflowNotificationBody(WorkflowModel workflow, String action) {
    switch (action) {
      case 'created':
        return '${workflow.title} iş akışı oluşturuldu';
      case 'updated':
        return '${workflow.title} iş akışı güncellendi';
      case 'completed':
        return '${workflow.title} iş akışı tamamlandı';
      case 'cancelled':
        return '${workflow.title} iş akışı iptal edildi';
      case 'step_assigned':
        final currentStep = workflow.currentStep;
        if (currentStep != null) {
          return '${workflow.title} iş akışında size yeni bir görev atandı: ${currentStep.title}';
        }
        return '${workflow.title} iş akışında size yeni bir görev atandı';
      case 'step_completed':
        return '${workflow.title} iş akışında bir adım tamamlandı';
      case 'step_rejected':
        return '${workflow.title} iş akışında bir adım reddedildi';
      case 'comment_added':
        return '${workflow.title} iş akışına yeni bir yorum eklendi';
      case 'file_added':
        return '${workflow.title} iş akışına yeni bir dosya eklendi';
      default:
        return '${workflow.title} iş akışında bir güncelleme yapıldı';
    }
  }

  // Süre formatla
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} gün';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours} saat';
    }
    return '${duration.inMinutes} dakika';
  }

  // Zamanlanmış bildirim
  Future<void> _scheduleNotification(NotificationModel notification) async {
    if (notification.scheduledFor == null) return;

    final scheduledTime = notification.scheduledFor!;
    final now = DateTime.now();
    final delay = scheduledTime.difference(now);

    if (delay.isNegative) return;

    await _localNotifications.zonedSchedule(
      notification.hashCode,
      notification.title,
      notification.body,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Varsayılan Kanal',
          channelDescription: 'Genel bildirimler için varsayılan kanal',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(notification.color),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: notification.id,
    );
  }

  // Push bildirim gönderme
  Future<void> _sendPushNotification(NotificationModel notification) async {
    try {
      // Kullanıcının FCM tokenlarını al
      final userDoc = await _firestore
          .collection('users')
          .doc(notification.userId)
          .get();
      
      final tokens = List<String>.from(userDoc.data()?['fcmTokens'] ?? []);

      if (tokens.isEmpty) {
        await _showLocalNotification(notification);
        return;
      }

      // Bildirim gruplaması
      final payload = notification.toFCMPayload();
      if (notification.canBeGrouped) {
        final groupedNotifications = await _getGroupedNotifications(notification);
        if (groupedNotifications.length > 1) {
          payload['notification']['tag'] = notification.groupId;
          payload['notification']['group'] = notification.groupId;
          payload['notification']['group_summary'] = true;
        }
      }

      // Her token için bildirim gönder
      for (var token in tokens) {
        try {
          await _messaging.sendMessage(
            to: token,
            data: payload['data'],
            messageId: notification.id,
            messageType: notification.type,
          );
        } catch (e) {
          print('Token için bildirim gönderilemedi: $e');
          continue;
        }
      }
    } catch (e) {
      print('Push bildirim gönderilemedi: $e');
      _retryOperation(() => _sendPushNotification(notification));
    }
  }

  // Gruplanmış bildirimleri getir
  Future<List<NotificationModel>> _getGroupedNotifications(
      NotificationModel notification) async {
    if (!notification.canBeGrouped) return [notification];

    final snapshot = await _firestore
        .collection('notifications')
        .where('groupId', isEqualTo: notification.groupId)
        .where('userId', isEqualTo: notification.userId)
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data()))
        .toList();
  }

  // Yerel bildirim gösterme
  Future<void> _showLocalNotification(NotificationModel notification) async {
    final androidDetails = AndroidNotificationDetails(
      notification.priority == NotificationModel.priorityHigh
          ? 'high_priority_channel'
          : 'default_channel',
      notification.priority == NotificationModel.priorityHigh
          ? 'Yüksek Öncelikli Bildirimler'
          : 'Varsayılan Kanal',
      channelDescription: 'Bildirimler için kanal',
      importance: notification.priority == NotificationModel.priorityHigh
          ? Importance.max
          : Importance.high,
      priority: notification.priority == NotificationModel.priorityHigh
          ? Priority.max
          : Priority.high,
      color: Color(notification.color),
      enableVibration: notification.settings['vibration'] ?? true,
      enableLights: true,
      groupKey: notification.groupId,
      setAsGroupSummary: notification.canBeGrouped,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: notification.settings['badge'] ?? true,
      presentSound: notification.settings['sound'] ?? true,
      threadIdentifier: notification.groupId,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: notification.id,
    );
  }

  // İşlem yeniden deneme
  void _retryOperation(Future<void> Function() operation) {
    if (_retryCount >= maxRetries) {
      _retryCount = 0;
      _retryTimer?.cancel();
      return;
    }

    _retryTimer?.cancel();
    _retryTimer = Timer(
      Duration(seconds: pow(2, _retryCount).toInt()),
      () async {
        _retryCount++;
        await operation();
      },
    );
  }

  // Bildirimleri getirme
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data()))
            .toList());
  }

  // Okunmamış bildirim sayısı
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Bildirimi sil
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Tüm bildirimleri sil
  Future<void> deleteAllNotifications(String userId) async {
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Bildirim dinleyicileri
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = NotificationModel.fromMap({
      ...message.data,
      'title': message.notification?.title,
      'body': message.notification?.body,
    });

    _showLocalNotification(notification);
    _notificationSubject.add(notification);
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Arka plan mesaj işleme
    print('Arka plan mesajı alındı: ${message.messageId}');
  }

  void _handleNotificationOpen(RemoteMessage message) {
    final notification = NotificationModel.fromMap({
      ...message.data,
      'title': message.notification?.title,
      'body': message.notification?.body,
    });

    _notificationSubject.add(notification);
  }

  void _handleNotificationTap(NotificationResponse response) {
    // Bildirime tıklama işleme
    print('Bildirime tıklandı: ${response.payload}');
  }

  // Bildirim stream'i
  Stream<NotificationModel> get notificationStream => _notificationSubject.stream;

  // Servisi temizle
  void dispose() {
    _notificationSubject.close();
    _connectionSubject.close();
    _retryTimer?.cancel();
    super.dispose();
  }

  // Yardımcı metodlar
  Future<String?> getCurrentUserId() async {
    // Auth servisinden kullanıcı ID'si alınacak
    return null;
  }
}

// Bildirim tipleri
class NotificationType {
  static const String start = 'start';
  static const String progress = 'progress';
  static const String minorProgress = 'minor_progress';
  static const String majorProgress = 'major_progress';
  static const String completion = 'completion';
  static const String delay = 'delay';
  static const String critical = 'critical';
  static const String error = 'error';
}

// Bildirim öncelikleri
class NotificationPriority {
  static const String low = 'low';
  static const String normal = 'normal';
  static const String high = 'high';
  static const String critical = 'critical';
}

// Bildirim durumları
class NotificationStatus {
  static const String unread = 'unread';
  static const String read = 'read';
  static const String archived = 'archived';
  static const String deleted = 'deleted';
} 