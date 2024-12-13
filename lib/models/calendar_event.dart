import 'package:flutter/material.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final String type;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final List<EventAttendee> attendees;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.attendees = const [],
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      type: map['type'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      color: Color(int.parse(map['color'] as String)),
      attendees: (map['attendees'] as List<dynamic>?)
              ?.map((e) => EventAttendee.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'color': color.value.toRadixString(16),
      'attendees': attendees.map((e) => e.toMap()).toList(),
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    DateTime? startTime,
    DateTime? endTime,
    Color? color,
    List<EventAttendee>? attendees,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      attendees: attendees ?? this.attendees,
    );
  }
}

class EventAttendee {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isOrganizer;
  final bool hasResponded;
  final String response;

  EventAttendee({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isOrganizer = false,
    this.hasResponded = false,
    this.response = 'pending',
  });

  factory EventAttendee.fromMap(Map<String, dynamic> map) {
    return EventAttendee(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
      isOrganizer: map['isOrganizer'] as bool? ?? false,
      hasResponded: map['hasResponded'] as bool? ?? false,
      response: map['response'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'isOrganizer': isOrganizer,
      'hasResponded': hasResponded,
      'response': response,
    };
  }

  EventAttendee copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    bool? isOrganizer,
    bool? hasResponded,
    String? response,
  }) {
    return EventAttendee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      hasResponded: hasResponded ?? this.hasResponded,
      response: response ?? this.response,
    );
  }
} 