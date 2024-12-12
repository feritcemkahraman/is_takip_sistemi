import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String userId;
  final Map<String, dynamic> data;
  final int priority;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? actionType;
  final String? actionId;
  final String? groupId;
  final Map<String, dynamic> settings;
  final DateTime? scheduledFor;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.userId,
    required this.data,
    this.priority = 1,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.actionType,
    this.actionId,
    this.groupId,
    this.settings = const {
      'sound': true,
      'vibration': true,
      'badge': true,
      'grouping': true,
    },
    this.scheduledFor,
  });

  // Bildirim tipleri
  static const String typeTask = 'task';
  static const String typeMeeting = 'meeting';
  static const String typeSystem = 'system';
  static const String typeMessage = 'message';
  static const String typeWorkflow = 'workflow';

  // Bildirim öncelikleri
  static const int priorityLow = 0;
  static const int priorityNormal = 1;
  static const int priorityHigh = 2;

  // Bildirim aksiyonları
  static const String actionView = 'view';
  static const String actionApprove = 'approve';
  static const String actionReject = 'reject';
  static const String actionReply = 'reply';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'userId': userId,
      'data': data,
      'priority': priority,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'actionType': actionType,
      'actionId': actionId,
      'groupId': groupId,
      'settings': settings,
      'scheduledFor': scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String,
      userId: map['userId'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      priority: map['priority'] as int? ?? 1,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
      actionType: map['actionType'] as String?,
      actionId: map['actionId'] as String?,
      groupId: map['groupId'] as String?,
      settings: Map<String, dynamic>.from(map['settings'] ?? {
        'sound': true,
        'vibration': true,
        'badge': true,
        'grouping': true,
      }),
      scheduledFor: (map['scheduledFor'] as Timestamp?)?.toDate(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? userId,
    Map<String, dynamic>? data,
    int? priority,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? actionType,
    String? actionId,
    String? groupId,
    Map<String, dynamic>? settings,
    DateTime? scheduledFor,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      actionType: actionType ?? this.actionType,
      actionId: actionId ?? this.actionId,
      groupId: groupId ?? this.groupId,
      settings: settings ?? this.settings,
      scheduledFor: scheduledFor ?? this.scheduledFor,
    );
  }

  // FCM formatına dönüştürme
  Map<String, dynamic> toFCMPayload() {
    return {
      'notification': {
        'title': title,
        'body': body,
        'priority': priority == priorityHigh ? 'high' : 'normal',
        'android_channel_id': 'default_channel',
        'sound': settings['sound'] ? 'default' : null,
        'badge': settings['badge'] ? '1' : null,
      },
      'data': {
        'id': id,
        'type': type,
        'userId': userId,
        'actionType': actionType ?? '',
        'actionId': actionId ?? '',
        'groupId': groupId ?? '',
        ...data,
      },
      'android': {
        'priority': priority == priorityHigh ? 'high' : 'normal',
        'notification': {
          'channel_id': 'default_channel',
          'notification_priority': priority == priorityHigh ? 'PRIORITY_HIGH' : 'PRIORITY_DEFAULT',
          'default_sound': settings['sound'],
          'default_vibrate_timings': settings['vibration'],
        },
      },
      'apns': {
        'payload': {
          'aps': {
            'sound': settings['sound'] ? 'default' : null,
            'badge': settings['badge'] ? 1 : null,
            'content-available': 1,
          },
        },
      },
    };
  }

  // Bildirim önizleme metni
  String get previewText {
    switch (type) {
      case typeTask:
        return 'Görev: $body';
      case typeMeeting:
        return 'Toplantı: $body';
      case typeMessage:
        return 'Mesaj: $body';
      case typeWorkflow:
        return 'İş Akışı: $body';
      default:
        return body;
    }
  }

  // Bildirim ikonunu getir
  String get icon {
    switch (type) {
      case typeTask:
        return 'task';
      case typeMeeting:
        return 'meeting';
      case typeMessage:
        return 'message';
      case typeWorkflow:
        return 'workflow';
      default:
        return 'notification';
    }
  }

  // Bildirim rengini getir
  int get color {
    switch (priority) {
      case priorityHigh:
        return 0xFFFF0000; // Kırmızı
      case priorityNormal:
        return 0xFF2196F3; // Mavi
      case priorityLow:
        return 0xFF4CAF50; // Yeşil
      default:
        return 0xFF9E9E9E; // Gri
    }
  }

  // Bildirim zamanı geldi mi?
  bool get isScheduledTimeReached {
    if (scheduledFor == null) return true;
    return DateTime.now().isAfter(scheduledFor!);
  }

  // Bildirim gruplanabilir mi?
  bool get canBeGrouped {
    return settings['grouping'] == true && groupId != null;
  }
} 