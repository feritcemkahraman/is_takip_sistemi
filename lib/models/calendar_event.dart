import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String type;
  final String createdBy;
  final DateTime createdAt;
  final String color;
  final bool isAllDay;
  final String? relatedId;
  final String? meetingPlatform;
  final String? location;
  final bool isOnline;
  final List<String> attendees;
  final Map<String, dynamic>? metadata;

  static const String typeMeeting = 'meeting';
  static const String typeTask = 'task';
  static const String typePersonal = 'personal';

  static const String platformTeams = 'teams';
  static const String platformZoom = 'zoom';
  static const String platformSkype = 'skype';
  static const String platformMeet = 'meet';

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    required this.color,
    this.isAllDay = false,
    this.relatedId,
    this.meetingPlatform,
    this.location,
    this.isOnline = true,
    this.attendees = const [],
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
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      color: map['color'] as String,
      isAllDay: map['isAllDay'] as bool? ?? false,
      relatedId: map['relatedId'] as String?,
      meetingPlatform: map['meetingPlatform'] as String?,
      location: map['location'] as String?,
      isOnline: map['isOnline'] as bool? ?? true,
      attendees: List<String>.from(map['attendees'] as List<dynamic>? ?? []),
      metadata: map['metadata'] as Map<String, dynamic>?,
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
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'color': color,
      'isAllDay': isAllDay,
      'relatedId': relatedId,
      'meetingPlatform': meetingPlatform,
      'location': location,
      'isOnline': isOnline,
      'attendees': attendees,
      'metadata': metadata,
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? type,
    String? createdBy,
    DateTime? createdAt,
    String? color,
    bool? isAllDay,
    String? relatedId,
    String? meetingPlatform,
    String? location,
    bool? isOnline,
    List<String>? attendees,
    Map<String, dynamic>? metadata,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
      relatedId: relatedId ?? this.relatedId,
      meetingPlatform: meetingPlatform ?? this.meetingPlatform,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      attendees: attendees ?? this.attendees,
      metadata: metadata ?? this.metadata,
    );
  }
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
