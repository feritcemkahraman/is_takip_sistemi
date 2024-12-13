import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String type;
  final bool isAllDay;
  final String? meetingPlatform;
  final String? location;
  final Color? color;
  final String userId;
  final bool isSynced;
  final String? externalEventId;
  final Map<String, dynamic>? metadata;
  final String sourceId; // Kaynak ID'si (toplantı veya görev ID'si)

  static const String typeMeeting = 'meeting';
  static const String typeTask = 'task';
  static const String typeReminder = 'reminder';
  static const String typeHoliday = 'holiday';

  static const Color colorMeeting = Colors.blue;
  static const Color colorTask = Colors.green;
  static const Color colorReminder = Colors.orange;
  static const Color colorHoliday = Colors.red;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.userId,
    required this.sourceId,
    this.isAllDay = false,
    this.meetingPlatform,
    this.location,
    this.color,
    this.isSynced = false,
    this.externalEventId,
    this.metadata,
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      type: map['type'] as String,
      isAllDay: map['isAllDay'] as bool? ?? false,
      meetingPlatform: map['meetingPlatform'] as String?,
      location: map['location'] as String?,
      color: map['color'] != null ? Color(map['color'] as int) : null,
      userId: map['userId'] as String,
      isSynced: map['isSynced'] as bool? ?? false,
      externalEventId: map['externalEventId'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
      sourceId: map['sourceId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'type': type,
      'isAllDay': isAllDay,
      'meetingPlatform': meetingPlatform,
      'location': location,
      'color': color?.value,
      'userId': userId,
      'isSynced': isSynced,
      'externalEventId': externalEventId,
      'metadata': metadata,
      'sourceId': sourceId,
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? type,
    bool? isAllDay,
    String? meetingPlatform,
    String? location,
    Color? color,
    String? userId,
    bool? isSynced,
    String? externalEventId,
    Map<String, dynamic>? metadata,
    String? sourceId,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      isAllDay: isAllDay ?? this.isAllDay,
      meetingPlatform: meetingPlatform ?? this.meetingPlatform,
      location: location ?? this.location,
      color: color ?? this.color,
      userId: userId ?? this.userId,
      isSynced: isSynced ?? this.isSynced,
      externalEventId: externalEventId ?? this.externalEventId,
      metadata: metadata ?? this.metadata,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  // Type check methods
  bool isMeeting() => type == typeMeeting;
  bool isTask() => type == typeTask;
  bool isReminder() => type == typeReminder;
  bool isHoliday() => type == typeHoliday;
}

class CalendarSettings {
  final String userId;
  final bool isGoogleCalendarEnabled;
  final String? googleCalendarId;
  final bool showWeekends;
  final bool showDeclinedEvents;
  final String defaultView;
  final String firstDayOfWeek;
  final Map<String, dynamic>? preferences;

  CalendarSettings({
    required this.userId,
    this.isGoogleCalendarEnabled = false,
    this.googleCalendarId,
    this.showWeekends = true,
    this.showDeclinedEvents = false,
    this.defaultView = 'month',
    this.firstDayOfWeek = 'monday',
    this.preferences,
  });

  factory CalendarSettings.fromMap(Map<String, dynamic> map) {
    return CalendarSettings(
      userId: map['userId'] as String,
      isGoogleCalendarEnabled: map['isGoogleCalendarEnabled'] as bool? ?? false,
      googleCalendarId: map['googleCalendarId'] as String?,
      showWeekends: map['showWeekends'] as bool? ?? true,
      showDeclinedEvents: map['showDeclinedEvents'] as bool? ?? false,
      defaultView: map['defaultView'] as String? ?? 'month',
      firstDayOfWeek: map['firstDayOfWeek'] as String? ?? 'monday',
      preferences: map['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'isGoogleCalendarEnabled': isGoogleCalendarEnabled,
      'googleCalendarId': googleCalendarId,
      'showWeekends': showWeekends,
      'showDeclinedEvents': showDeclinedEvents,
      'defaultView': defaultView,
      'firstDayOfWeek': firstDayOfWeek,
      'preferences': preferences,
    };
  }

  CalendarSettings copyWith({
    String? userId,
    bool? isGoogleCalendarEnabled,
    String? googleCalendarId,
    bool? showWeekends,
    bool? showDeclinedEvents,
    String? defaultView,
    String? firstDayOfWeek,
    Map<String, dynamic>? preferences,
  }) {
    return CalendarSettings(
      userId: userId ?? this.userId,
      isGoogleCalendarEnabled: isGoogleCalendarEnabled ?? this.isGoogleCalendarEnabled,
      googleCalendarId: googleCalendarId ?? this.googleCalendarId,
      showWeekends: showWeekends ?? this.showWeekends,
      showDeclinedEvents: showDeclinedEvents ?? this.showDeclinedEvents,
      defaultView: defaultView ?? this.defaultView,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      preferences: preferences ?? this.preferences,
    );
  }
}
