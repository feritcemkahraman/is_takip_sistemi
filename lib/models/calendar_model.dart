import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String type; // meeting, task
  final String sourceId; // meeting_id veya task_id
  final String userId;
  final bool isAllDay;
  final String color;
  final bool isSynced; // Google Calendar veya Outlook ile senkronize edildi mi
  final String? externalEventId; // Dış takvim sistemindeki ID
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.sourceId,
    required this.userId,
    this.isAllDay = false,
    required this.color,
    this.isSynced = false,
    this.externalEventId,
    DateTime? createdAt,
    this.lastUpdatedAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  // Event tipleri
  static const String typeMeeting = 'meeting';
  static const String typeTask = 'task';

  // Renk kodları
  static const String colorMeeting = '#4CAF50'; // Yeşil
  static const String colorTask = '#2196F3'; // Mavi
  static const String colorDeadline = '#F44336'; // Kırmızı
  static const String colorReminder = '#FF9800'; // Turuncu

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'type': type,
      'sourceId': sourceId,
      'userId': userId,
      'isAllDay': isAllDay,
      'color': color,
      'isSynced': isSynced,
      'externalEventId': externalEventId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': lastUpdatedAt != null ? Timestamp.fromDate(lastUpdatedAt!) : null,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      type: map['type'] as String,
      sourceId: map['sourceId'] as String,
      userId: map['userId'] as String,
      isAllDay: map['isAllDay'] as bool,
      color: map['color'] as String,
      isSynced: map['isSynced'] as bool,
      externalEventId: map['externalEventId'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? type,
    String? sourceId,
    String? userId,
    bool? isAllDay,
    String? color,
    bool? isSynced,
    String? externalEventId,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      sourceId: sourceId ?? this.sourceId,
      userId: userId ?? this.userId,
      isAllDay: isAllDay ?? this.isAllDay,
      color: color ?? this.color,
      isSynced: isSynced ?? this.isSynced,
      externalEventId: externalEventId ?? this.externalEventId,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

class CalendarSettings {
  final String userId;
  final bool isGoogleCalendarEnabled;
  final bool isOutlookEnabled;
  final String? googleCalendarId;
  final String? outlookCalendarId;
  final List<String> hiddenEventTypes;
  final DateTime? lastSyncTime;
  final String defaultView; // month, week, day
  final String firstDayOfWeek; // monday, sunday
  final bool showWeekends;
  final String defaultEventDuration; // 30m, 1h, 2h

  CalendarSettings({
    required this.userId,
    this.isGoogleCalendarEnabled = false,
    this.isOutlookEnabled = false,
    this.googleCalendarId,
    this.outlookCalendarId,
    this.hiddenEventTypes = const [],
    this.lastSyncTime,
    this.defaultView = 'month',
    this.firstDayOfWeek = 'monday',
    this.showWeekends = true,
    this.defaultEventDuration = '1h',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'isGoogleCalendarEnabled': isGoogleCalendarEnabled,
      'isOutlookEnabled': isOutlookEnabled,
      'googleCalendarId': googleCalendarId,
      'outlookCalendarId': outlookCalendarId,
      'hiddenEventTypes': hiddenEventTypes,
      'lastSyncTime': lastSyncTime != null ? Timestamp.fromDate(lastSyncTime!) : null,
      'defaultView': defaultView,
      'firstDayOfWeek': firstDayOfWeek,
      'showWeekends': showWeekends,
      'defaultEventDuration': defaultEventDuration,
    };
  }

  factory CalendarSettings.fromMap(Map<String, dynamic> map) {
    return CalendarSettings(
      userId: map['userId'] as String,
      isGoogleCalendarEnabled: map['isGoogleCalendarEnabled'] as bool,
      isOutlookEnabled: map['isOutlookEnabled'] as bool,
      googleCalendarId: map['googleCalendarId'] as String?,
      outlookCalendarId: map['outlookCalendarId'] as String?,
      hiddenEventTypes: List<String>.from(map['hiddenEventTypes'] ?? []),
      lastSyncTime: (map['lastSyncTime'] as Timestamp?)?.toDate(),
      defaultView: map['defaultView'] as String? ?? 'month',
      firstDayOfWeek: map['firstDayOfWeek'] as String? ?? 'monday',
      showWeekends: map['showWeekends'] as bool? ?? true,
      defaultEventDuration: map['defaultEventDuration'] as String? ?? '1h',
    );
  }

  CalendarSettings copyWith({
    String? userId,
    bool? isGoogleCalendarEnabled,
    bool? isOutlookEnabled,
    String? googleCalendarId,
    String? outlookCalendarId,
    List<String>? hiddenEventTypes,
    DateTime? lastSyncTime,
    String? defaultView,
    String? firstDayOfWeek,
    bool? showWeekends,
    String? defaultEventDuration,
  }) {
    return CalendarSettings(
      userId: userId ?? this.userId,
      isGoogleCalendarEnabled: isGoogleCalendarEnabled ?? this.isGoogleCalendarEnabled,
      isOutlookEnabled: isOutlookEnabled ?? this.isOutlookEnabled,
      googleCalendarId: googleCalendarId ?? this.googleCalendarId,
      outlookCalendarId: outlookCalendarId ?? this.outlookCalendarId,
      hiddenEventTypes: hiddenEventTypes ?? this.hiddenEventTypes,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      defaultView: defaultView ?? this.defaultView,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      showWeekends: showWeekends ?? this.showWeekends,
      defaultEventDuration: defaultEventDuration ?? this.defaultEventDuration,
    );
  }
} 