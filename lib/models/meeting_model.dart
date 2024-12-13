import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MeetingModel {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String organizerId;
  final List<MeetingParticipant> participants;
  final String status;
  final bool isOnline;
  final String? meetingPlatform;
  final String? meetingLink;
  final String? location;
  final bool isRecurring;
  final int? recurrenceType;
  final List<int>? weekDays;
  final int? endType;
  final int? occurrences;
  final DateTime? endDate;
  final String? parentMeetingId;
  final MeetingMinutes? minutes;
  final List<MeetingDecision>? decisions;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;
  final int reminderType;
  final List<int> reminderTimes;
  final List<String> departments;
  final List<String> agenda;
  final int? recurrenceInterval;
  final List<int>? recurrenceWeekDays;
  final int? recurrenceEndType;
  final int? recurrenceOccurrences;
  final DateTime? recurrenceEndDate;
  final bool reminderEnabled;
  final List<int> reminderMinutes;

  MeetingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.organizerId,
    required this.participants,
    required this.status,
    this.isOnline = false,
    this.meetingPlatform,
    this.meetingLink,
    this.location,
    this.isRecurring = false,
    this.recurrenceType,
    this.weekDays = const [],
    this.endType,
    this.occurrences,
    this.endDate,
    this.parentMeetingId,
    this.minutes,
    this.decisions,
    this.attachments = const [],
    DateTime? createdAt,
    this.lastUpdatedAt,
    this.reminderType = reminderTypeApp,
    this.reminderTimes = const [15, 30, 60],
    this.departments = const [],
    this.agenda = const [],
    this.recurrenceInterval = 1,
    this.recurrenceWeekDays = const [],
    this.recurrenceEndType,
    this.recurrenceOccurrences,
    this.recurrenceEndDate,
    this.reminderEnabled = true,
    this.reminderMinutes = const [15, 30, 60],
  }) : this.createdAt = createdAt ?? DateTime.now();

  // Platform tipleri
  static const int platformZoom = 0;
  static const int platformMeet = 1;
  static const int platformTeams = 2;
  static const int platformSkype = 3;

  // Tekrarlama tipleri
  static const int recurrenceNone = 0;
  static const int recurrenceDaily = 1;
  static const int recurrenceWeekly = 2;
  static const int recurrenceMonthly = 3;

  // Bitiş tipleri
  static const int endNever = 0;
  static const int endAfterOccurrences = 1;
  static const int endOnDate = 2;

  // Hatırlatıcı tipleri
  static const int reminderTypeApp = 0;
  static const int reminderTypeEmail = 1;
  static const int reminderTypeBoth = 2;

  // Durum tipleri
  static const String statusScheduled = 'scheduled';
  static const String statusOngoing = 'ongoing';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Haftanın günleri
  static const List<String> weekDayNames = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];

  // Hatırlatıcı süreleri (dakika)
  static const List<int> defaultReminderTimes = [5, 15, 30, 60, 120, 1440];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'organizerId': organizerId,
      'participants': participants.map((p) => p.toMap()).toList(),
      'status': status,
      'isOnline': isOnline,
      'meetingPlatform': meetingPlatform,
      'meetingLink': meetingLink,
      'location': location,
      'isRecurring': isRecurring,
      'recurrenceType': recurrenceType,
      'weekDays': weekDays,
      'endType': endType,
      'occurrences': occurrences,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'parentMeetingId': parentMeetingId,
      'minutes': minutes?.toMap(),
      'decisions': decisions?.map((d) => d.toMap()).toList(),
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': lastUpdatedAt != null ? Timestamp.fromDate(lastUpdatedAt!) : null,
      'reminderType': reminderType,
      'reminderTimes': reminderTimes,
      'departments': departments,
      'agenda': agenda,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceWeekDays': recurrenceWeekDays,
      'recurrenceEndType': recurrenceEndType,
      'recurrenceOccurrences': recurrenceOccurrences,
      'recurrenceEndDate': recurrenceEndDate != null ? Timestamp.fromDate(recurrenceEndDate!) : null,
      'reminderEnabled': reminderEnabled,
      'reminderMinutes': reminderMinutes,
    };
  }

  factory MeetingModel.fromMap(Map<String, dynamic> map) {
    return MeetingModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      organizerId: map['organizerId'] as String,
      participants: (map['participants'] as List<dynamic>)
          .map((p) => MeetingParticipant.fromMap(p as Map<String, dynamic>))
          .toList(),
      status: map['status'] as String,
      isOnline: map['isOnline'] as bool? ?? false,
      meetingPlatform: map['meetingPlatform'] as String?,
      meetingLink: map['meetingLink'] as String?,
      location: map['location'] as String?,
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrenceType: map['recurrenceType'] as int?,
      weekDays: (map['weekDays'] as List<dynamic>?)?.cast<int>() ?? [],
      endType: map['endType'] as int?,
      occurrences: map['occurrences'] as int?,
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      parentMeetingId: map['parentMeetingId'] as String?,
      minutes: map['minutes'] != null
          ? MeetingMinutes.fromMap(map['minutes'] as Map<String, dynamic>)
          : null,
      decisions: (map['decisions'] as List<dynamic>?)
          ?.map((d) => MeetingDecision.fromMap(d as Map<String, dynamic>))
          .toList(),
      attachments: (map['attachments'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUpdatedAt: map['lastUpdatedAt'] != null
          ? (map['lastUpdatedAt'] as Timestamp).toDate()
          : null,
      reminderType: map['reminderType'] as int? ?? reminderTypeApp,
      reminderTimes: (map['reminderTimes'] as List<dynamic>?)?.cast<int>() ??
          [15, 30, 60],
      departments: (map['departments'] as List<dynamic>?)?.cast<String>() ?? [],
      agenda: (map['agenda'] as List<dynamic>?)?.cast<String>() ?? [],
      recurrenceInterval: map['recurrenceInterval'] as int? ?? 1,
      recurrenceWeekDays: (map['recurrenceWeekDays'] as List<dynamic>?)?.cast<int>() ?? [],
      recurrenceEndType: map['recurrenceEndType'] as int?,
      recurrenceOccurrences: map['recurrenceOccurrences'] as int?,
      recurrenceEndDate: map['recurrenceEndDate'] != null
          ? (map['recurrenceEndDate'] as Timestamp).toDate()
          : null,
      reminderEnabled: map['reminderEnabled'] as bool? ?? true,
      reminderMinutes: (map['reminderMinutes'] as List<dynamic>?)?.cast<int>() ??
          [15, 30, 60],
    );
  }

  MeetingModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? organizerId,
    List<MeetingParticipant>? participants,
    String? status,
    bool? isOnline,
    String? meetingPlatform,
    String? meetingLink,
    String? location,
    bool? isRecurring,
    int? recurrenceType,
    List<int>? weekDays,
    int? endType,
    int? occurrences,
    DateTime? endDate,
    String? parentMeetingId,
    MeetingMinutes? minutes,
    List<MeetingDecision>? decisions,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    int? reminderType,
    List<int>? reminderTimes,
    List<String>? departments,
    List<String>? agenda,
    int? recurrenceInterval,
    List<int>? recurrenceWeekDays,
    int? recurrenceEndType,
    int? recurrenceOccurrences,
    DateTime? recurrenceEndDate,
    bool? reminderEnabled,
    List<int>? reminderMinutes,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      organizerId: organizerId ?? this.organizerId,
      participants: participants ?? List.from(this.participants),
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      meetingPlatform: meetingPlatform ?? this.meetingPlatform,
      meetingLink: meetingLink ?? this.meetingLink,
      location: location ?? this.location,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      weekDays: weekDays ?? List.from(this.weekDays ?? []),
      endType: endType ?? this.endType,
      occurrences: occurrences ?? this.occurrences,
      endDate: endDate ?? this.endDate,
      parentMeetingId: parentMeetingId ?? this.parentMeetingId,
      minutes: minutes ?? this.minutes,
      decisions: decisions ?? this.decisions,
      attachments: attachments ?? List.from(this.attachments),
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      reminderType: reminderType ?? this.reminderType,
      reminderTimes: reminderTimes ?? List.from(this.reminderTimes),
      departments: departments ?? List.from(this.departments),
      agenda: agenda ?? List.from(this.agenda),
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceWeekDays: recurrenceWeekDays ?? List.from(this.recurrenceWeekDays ?? []),
      recurrenceEndType: recurrenceEndType ?? this.recurrenceEndType,
      recurrenceOccurrences: recurrenceOccurrences ?? this.recurrenceOccurrences,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutes: reminderMinutes ?? List.from(this.reminderMinutes),
    );
  }

  static String getPlatformTitle(int platform) {
    switch (platform) {
      case platformZoom:
        return 'Zoom';
      case platformMeet:
        return 'Google Meet';
      case platformTeams:
        return 'Microsoft Teams';
      case platformSkype:
        return 'Skype';
      default:
        return 'Bilinmeyen Platform';
    }
  }

  static String getRecurrenceTitle(int recurrence) {
    switch (recurrence) {
      case recurrenceNone:
        return 'Tekrar Yok';
      case recurrenceDaily:
        return 'Günlük';
      case recurrenceWeekly:
        return 'Haftalık';
      case recurrenceMonthly:
        return 'Aylık';
      default:
        return 'Bilinmeyen Tekrar';
    }
  }

  static String getEndTypeTitle(int endType) {
    switch (endType) {
      case endNever:
        return 'Asla';
      case endAfterOccurrences:
        return 'Tekrar Sayısı Sonra';
      case endOnDate:
        return 'Belirli Bir Tarihte';
      default:
        return 'Bilinmeyen Bitiş Tipi';
    }
  }

  static String getReminderTypeTitle(int type) {
    switch (type) {
      case reminderTypeApp:
        return 'Uygulama Bildirimi';
      case reminderTypeEmail:
        return 'E-posta';
      case reminderTypeBoth:
        return 'Uygulama ve E-posta';
      default:
        return 'Bilinmeyen Hatırlatıcı Tipi';
    }
  }

  static String formatReminderTime(int minutes) {
    if (minutes >= 1440) {
      final days = minutes ~/ 1440;
      return '$days gün önce';
    } else if (minutes >= 60) {
      final hours = minutes ~/ 60;
      return '$hours saat önce';
    } else {
      return '$minutes dakika önce';
    }
  }

  static String getStatusTitle(String status) {
    switch (status) {
      case statusScheduled:
        return 'Planlandı';
      case statusOngoing:
        return 'Devam Ediyor';
      case statusCompleted:
        return 'Tamamlandı';
      case statusCancelled:
        return 'İptal Edildi';
      default:
        return 'Bilinmeyen Durum';
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case statusScheduled:
        return Colors.blue;
      case statusOngoing:
        return Colors.green;
      case statusCompleted:
        return Colors.grey;
      case statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool isRecurrenceEnded(DateTime date) {
    if (!isRecurring) return false;
    if (recurrenceEndType == null) return false;

    switch (recurrenceEndType) {
      case endNever:
        return false;
      case endAfterOccurrences:
        return recurrenceOccurrences != null &&
            getOccurrenceCount(date) >= recurrenceOccurrences!;
      case endOnDate:
        return recurrenceEndDate != null && date.isAfter(recurrenceEndDate!);
      default:
        return false;
    }
  }

  int getOccurrenceCount(DateTime date) {
    if (!isRecurring) return 0;
    if (recurrenceType == null) return 0;

    final difference = date.difference(startTime);
    switch (recurrenceType) {
      case recurrenceDaily:
        return difference.inDays ~/ (recurrenceInterval ?? 1);
      case recurrenceWeekly:
        return difference.inDays ~/ (7 * (recurrenceInterval ?? 1));
      case recurrenceMonthly:
        return (date.year * 12 + date.month) -
            (startTime.year * 12 + startTime.month);
      default:
        return 0;
    }
  }

  DateTime? getNextOccurrence(DateTime date) {
    if (!isRecurring) return null;
    if (recurrenceType == null) return null;
    if (isRecurrenceEnded(date)) return null;

    DateTime nextDate;
    switch (recurrenceType) {
      case recurrenceDaily:
        nextDate = startTime.add(Duration(days: recurrenceInterval ?? 1));
        break;
      case recurrenceWeekly:
        nextDate = startTime.add(Duration(days: 7 * (recurrenceInterval ?? 1)));
        break;
      case recurrenceMonthly:
        nextDate = DateTime(startTime.year, startTime.month + (recurrenceInterval ?? 1), startTime.day);
        break;
      default:
        return null;
    }

    if (recurrenceEndType == endOnDate && recurrenceEndDate != null) {
      if (nextDate.isAfter(recurrenceEndDate!)) return null;
    }

    return nextDate;
  }
}

class MeetingParticipant {
  final String userId;
  final String name;
  final String rsvpStatus;
  final DateTime rsvpTime;

  MeetingParticipant({
    required this.userId,
    required this.name,
    required this.rsvpStatus,
    required this.rsvpTime,
  });

  // Katılımcı durumları
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusDeclined = 'declined';
  static const String statusTentative = 'tentative';

  // Katılımcı durumu başlıkları
  static String getStatusTitle(String status) {
    switch (status) {
      case statusPending:
        return 'Yanıt Bekliyor';
      case statusAccepted:
        return 'Katılacak';
      case statusDeclined:
        return 'Katılmayacak';
      case statusTentative:
        return 'Belki';
      default:
        return 'Bilinmeyen Durum';
    }
  }

  // Katılımcı durumu renkleri
  static Color getStatusColor(String status) {
    switch (status) {
      case statusPending:
        return Colors.grey;
      case statusAccepted:
        return Colors.green;
      case statusDeclined:
        return Colors.red;
      case statusTentative:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Katılımcı durumu ikonları
  static IconData getStatusIcon(String status) {
    switch (status) {
      case statusPending:
        return Icons.schedule;
      case statusAccepted:
        return Icons.check_circle;
      case statusDeclined:
        return Icons.cancel;
      case statusTentative:
        return Icons.help;
      default:
        return Icons.help;
    }
  }

  factory MeetingParticipant.fromMap(Map<String, dynamic> map) {
    return MeetingParticipant(
      userId: map['userId'] as String,
      name: map['name'] as String,
      rsvpStatus: map['rsvpStatus'] as String,
      rsvpTime: (map['rsvpTime'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'rsvpStatus': rsvpStatus,
      'rsvpTime': Timestamp.fromDate(rsvpTime),
    };
  }

  MeetingParticipant copyWith({
    String? name,
    String? rsvpStatus,
    DateTime? rsvpTime,
  }) {
    return MeetingParticipant(
      userId: userId,
      name: name ?? this.name,
      rsvpStatus: rsvpStatus ?? this.rsvpStatus,
      rsvpTime: rsvpTime ?? this.rsvpTime,
    );
  }

  @override
  String toString() {
    return 'MeetingParticipant(userId: $userId, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MeetingParticipant && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

class MeetingMinutes {
  final String content;
  final List<String> attachments;
  final String createdBy;
  final DateTime createdAt;
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;

  MeetingMinutes({
    required this.content,
    required this.attachments,
    required this.createdBy,
    required this.createdAt,
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
  });

  factory MeetingMinutes.fromMap(Map<String, dynamic> map) {
    return MeetingMinutes(
      content: map['content'] as String,
      attachments: List<String>.from(map['attachments'] as List),
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isApproved: map['isApproved'] as bool? ?? false,
      approvedBy: map['approvedBy'] as String?,
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'attachments': attachments,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isApproved': isApproved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }

  MeetingMinutes copyWith({
    String? content,
    List<String>? attachments,
    bool? isApproved,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return MeetingMinutes(
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      createdBy: createdBy,
      createdAt: createdAt,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  @override
  String toString() {
    return 'MeetingMinutes(content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MeetingMinutes &&
        other.content == content &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => content.hashCode ^ createdBy.hashCode ^ createdAt.hashCode;
}

class MeetingDecision {
  final String id;
  final String content;
  final String assignedTo;
  final DateTime? dueDate;
  final String status;
  final List<String> attachments;
  final List<MeetingDecisionComment> comments;

  MeetingDecision({
    required this.id,
    required this.content,
    required this.assignedTo,
    this.dueDate,
    required this.status,
    required this.attachments,
    required this.comments,
  });

  // Karar durumları
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Karar durumu başlıkları
  static String getStatusTitle(String status) {
    switch (status) {
      case statusPending:
        return 'Beklemede';
      case statusInProgress:
        return 'Devam Ediyor';
      case statusCompleted:
        return 'Tamamlandı';
      case statusCancelled:
        return 'İptal Edildi';
      default:
        return 'Bilinmeyen Durum';
    }
  }

  // Karar durumu renkleri
  static Color getStatusColor(String status) {
    switch (status) {
      case statusPending:
        return Colors.grey;
      case statusInProgress:
        return Colors.blue;
      case statusCompleted:
        return Colors.green;
      case statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Karar durumu ikonları
  static IconData getStatusIcon(String status) {
    switch (status) {
      case statusPending:
        return Icons.schedule;
      case statusInProgress:
        return Icons.play_arrow;
      case statusCompleted:
        return Icons.check_circle;
      case statusCancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  factory MeetingDecision.fromMap(Map<String, dynamic> map) {
    return MeetingDecision(
      id: map['id'] as String,
      content: map['content'] as String,
      assignedTo: map['assignedTo'] as String,
      dueDate:
          map['dueDate'] != null ? (map['dueDate'] as Timestamp).toDate() : null,
      status: map['status'] as String,
      attachments: List<String>.from(map['attachments'] as List),
      comments: (map['comments'] as List)
          .map((c) =>
              MeetingDecisionComment.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'assignedTo': assignedTo,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status,
      'attachments': attachments,
      'comments': comments.map((c) => c.toMap()).toList(),
    };
  }

  MeetingDecision copyWith({
    String? content,
    String? assignedTo,
    DateTime? dueDate,
    String? status,
    List<String>? attachments,
    List<MeetingDecisionComment>? comments,
  }) {
    return MeetingDecision(
      id: id,
      content: content ?? this.content,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      comments: comments ?? this.comments,
    );
  }

  @override
  String toString() {
    return 'MeetingDecision(id: $id, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MeetingDecision && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class MeetingDecisionComment {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final List<String> attachments;

  MeetingDecisionComment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.attachments,
  });

  factory MeetingDecisionComment.fromMap(Map<String, dynamic> map) {
    return MeetingDecisionComment(
      id: map['id'] as String,
      userId: map['userId'] as String,
      content: map['content'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      attachments: List<String>.from(map['attachments'] as List),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'attachments': attachments,
    };
  }

  MeetingDecisionComment copyWith({
    String? content,
    List<String>? attachments,
  }) {
    return MeetingDecisionComment(
      id: id,
      userId: userId,
      content: content ?? this.content,
      createdAt: createdAt,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  String toString() {
    return 'MeetingDecisionComment(id: $id, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MeetingDecisionComment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 