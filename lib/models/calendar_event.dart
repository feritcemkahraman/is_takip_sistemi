import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;
  final DateTime createdAt;
  final String type;
  final String color;
  final bool isAllDay;
  final List<String> attendees;
  final String? location;
  final String? url;
  final Map<String, dynamic>? metadata;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    required this.createdAt,
    required this.type,
    required this.color,
    this.isAllDay = false,
    this.attendees = const [],
    this.location,
    this.url,
    this.metadata,
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      type: map['type'] as String,
      color: map['color'] as String,
      isAllDay: map['isAllDay'] as bool? ?? false,
      attendees: List<String>.from(map['attendees'] as List<dynamic>? ?? []),
      location: map['location'] as String?,
      url: map['url'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type,
      'color': color,
      'isAllDay': isAllDay,
      'attendees': attendees,
      'location': location,
      'url': url,
      'metadata': metadata,
    };
  }

  Duration getDuration() {
    return endDate.difference(startDate);
  }

  bool isOngoing() {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool isUpcoming() {
    return DateTime.now().isBefore(startDate);
  }

  bool isPast() {
    return DateTime.now().isAfter(endDate);
  }

  bool hasAttendees() => attendees.isNotEmpty;
  bool hasLocation() => location != null && location!.isNotEmpty;
  bool hasUrl() => url != null && url!.isNotEmpty;
  bool hasMetadata() => metadata != null && metadata!.isNotEmpty;

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? createdBy,
    DateTime? createdAt,
    String? type,
    String? color,
    bool? isAllDay,
    List<String>? attendees,
    String? location,
    String? url,
    Map<String, dynamic>? metadata,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
      attendees: attendees ?? this.attendees,
      location: location ?? this.location,
      url: url ?? this.url,
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
