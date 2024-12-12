import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MeetingParticipant {
  final String userId;
  final String name;
  final String rsvpStatus; // attending, declined, pending
  final DateTime? respondedAt;

  MeetingParticipant({
    required this.userId,
    required this.name,
    this.rsvpStatus = 'pending',
    this.respondedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'rsvpStatus': rsvpStatus,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  factory MeetingParticipant.fromMap(Map<String, dynamic> map) {
    return MeetingParticipant(
      userId: map['userId'] as String,
      name: map['name'] as String,
      rsvpStatus: map['rsvpStatus'] as String? ?? 'pending',
      respondedAt: (map['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  static const String statusAttending = 'attending';
  static const String statusDeclined = 'declined';
  static const String statusPending = 'pending';

  static String getStatusTitle(String status) {
    switch (status) {
      case statusAttending:
        return 'Katılıyor';
      case statusDeclined:
        return 'Katılmıyor';
      case statusPending:
        return 'Yanıt Bekleniyor';
      default:
        return 'Bilinmiyor';
    }
  }
}

class MeetingNote {
  final String content;
  final String createdBy;
  final DateTime createdAt;

  MeetingNote({
    required this.content,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MeetingNote.fromMap(Map<String, dynamic> map) {
    return MeetingNote(
      content: map['content'] as String,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class MeetingDecision {
  final String id;
  final String content;
  final String? assignedTo;
  final DateTime dueDate;
  final String status; // pending, completed, cancelled
  final String createdBy;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<String> attachments;
  final List<MeetingNote> notes;

  MeetingDecision({
    required this.id,
    required this.content,
    this.assignedTo,
    required this.dueDate,
    this.status = 'pending',
    required this.createdBy,
    required this.createdAt,
    this.completedAt,
    this.attachments = const [],
    this.notes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'assignedTo': assignedTo,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'attachments': attachments,
      'notes': notes.map((n) => n.toMap()).toList(),
    };
  }

  factory MeetingDecision.fromMap(Map<String, dynamic> map) {
    return MeetingDecision(
      id: map['id'] as String,
      content: map['content'] as String,
      assignedTo: map['assignedTo'] as String?,
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      status: map['status'] as String? ?? 'pending',
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      attachments: List<String>.from(map['attachments'] as List<dynamic>? ?? []),
      notes: List<MeetingNote>.from(
        (map['notes'] as List<dynamic>? ?? []).map(
          (x) => MeetingNote.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  static const String statusPending = 'pending';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  static String getStatusTitle(String status) {
    switch (status) {
      case statusPending:
        return 'Beklemede';
      case statusCompleted:
        return 'Tamamlandı';
      case statusCancelled:
        return 'İptal Edildi';
      default:
        return 'Bilinmiyor';
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case statusPending:
        return Colors.orange;
      case statusCompleted:
        return Colors.green;
      case statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class MeetingMinutes {
  final String content;
  final List<String> attendees;
  final List<String> absentees;
  final List<MeetingDecision> decisions;
  final List<String> attachments;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final bool isApproved;

  MeetingMinutes({
    required this.content,
    required this.attendees,
    required this.absentees,
    required this.decisions,
    this.attachments = const [],
    required this.createdBy,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.isApproved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'attendees': attendees,
      'absentees': absentees,
      'decisions': decisions.map((d) => d.toMap()).toList(),
      'attachments': attachments,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'isApproved': isApproved,
    };
  }

  factory MeetingMinutes.fromMap(Map<String, dynamic> map) {
    return MeetingMinutes(
      content: map['content'] as String,
      attendees: List<String>.from(map['attendees'] as List<dynamic>),
      absentees: List<String>.from(map['absentees'] as List<dynamic>),
      decisions: List<MeetingDecision>.from(
        (map['decisions'] as List<dynamic>).map(
          (x) => MeetingDecision.fromMap(x as Map<String, dynamic>),
        ),
      ),
      attachments: List<String>.from(map['attachments'] as List<dynamic>? ?? []),
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      approvedBy: map['approvedBy'] as String?,
      isApproved: map['isApproved'] as bool? ?? false,
    );
  }
}

class MeetingModel {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String organizerId;
  final List<MeetingParticipant> participants;
  final List<String> departments;
  final List<String> agenda;
  final List<String> attachments;
  final List<MeetingNote> notes;
  final List<MeetingDecision> decisions;
  final MeetingMinutes? minutes;
  final String status;
  final bool isOnline;
  final String? meetingPlatform;
  final String? meetingLink;
  final String location;
  final bool isRecurring;
  final String? recurrencePattern;
  final int? recurrenceInterval;
  final List<int>? recurrenceWeekDays;
  final String? recurrenceEndType;
  final int? recurrenceOccurrences;
  final DateTime? recurrenceEndDate;
  final String? parentMeetingId;
  final List<int> reminderMinutes;
  final String reminderType;
  final bool reminderEnabled;
  final List<String>? lastReminderSentTo;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;

  MeetingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.organizerId,
    required this.participants,
    required this.departments,
    this.agenda = const [],
    this.attachments = const [],
    this.notes = const [],
    this.decisions = const [],
    this.minutes,
    this.status = statusScheduled,
    this.isOnline = false,
    this.meetingPlatform,
    this.meetingLink,
    this.location = '',
    this.isRecurring = false,
    this.recurrencePattern,
    this.recurrenceInterval,
    this.recurrenceWeekDays,
    this.recurrenceEndType,
    this.recurrenceOccurrences,
    this.recurrenceEndDate,
    this.parentMeetingId,
    this.reminderMinutes = const [30],
    this.reminderType = reminderTypeApp,
    this.reminderEnabled = true,
    this.lastReminderSentTo,
    required this.createdAt,
    this.lastUpdatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'organizerId': organizerId,
      'participants': participants.map((p) => p.toMap()).toList(),
      'departments': departments,
      'agenda': agenda,
      'attachments': attachments,
      'notes': notes.map((n) => n.toMap()).toList(),
      'decisions': decisions.map((d) => d.toMap()).toList(),
      'minutes': minutes?.toMap(),
      'status': status,
      'isOnline': isOnline,
      'meetingPlatform': meetingPlatform,
      'meetingLink': meetingLink,
      'location': location,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceWeekDays': recurrenceWeekDays,
      'recurrenceEndType': recurrenceEndType,
      'recurrenceOccurrences': recurrenceOccurrences,
      'recurrenceEndDate':
          recurrenceEndDate != null ? Timestamp.fromDate(recurrenceEndDate!) : null,
      'parentMeetingId': parentMeetingId,
      'reminderMinutes': reminderMinutes,
      'reminderType': reminderType,
      'reminderEnabled': reminderEnabled,
      'lastReminderSentTo': lastReminderSentTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt':
          lastUpdatedAt != null ? Timestamp.fromDate(lastUpdatedAt!) : null,
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
      participants: List<MeetingParticipant>.from(
        (map['participants'] as List<dynamic>).map(
          (x) => MeetingParticipant.fromMap(x as Map<String, dynamic>),
        ),
      ),
      departments: List<String>.from(map['departments'] as List<dynamic>),
      agenda: List<String>.from(map['agenda'] as List<dynamic>? ?? []),
      attachments: List<String>.from(map['attachments'] as List<dynamic>? ?? []),
      notes: List<MeetingNote>.from(
        (map['notes'] as List<dynamic>? ?? []).map(
          (x) => MeetingNote.fromMap(x as Map<String, dynamic>),
        ),
      ),
      decisions: List<MeetingDecision>.from(
        (map['decisions'] as List<dynamic>? ?? []).map(
          (x) => MeetingDecision.fromMap(x as Map<String, dynamic>),
        ),
      ),
      minutes: map['minutes'] != null
          ? MeetingMinutes.fromMap(map['minutes'] as Map<String, dynamic>)
          : null,
      status: map['status'] as String? ?? statusScheduled,
      isOnline: map['isOnline'] as bool? ?? false,
      meetingPlatform: map['meetingPlatform'] as String?,
      meetingLink: map['meetingLink'] as String?,
      location: map['location'] as String? ?? '',
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrencePattern: map['recurrencePattern'] as String?,
      recurrenceInterval: map['recurrenceInterval'] as int?,
      recurrenceWeekDays: map['recurrenceWeekDays'] != null
          ? List<int>.from(map['recurrenceWeekDays'] as List<dynamic>)
          : null,
      recurrenceEndType: map['recurrenceEndType'] as String?,
      recurrenceOccurrences: map['recurrenceOccurrences'] as int?,
      recurrenceEndDate:
          (map['recurrenceEndDate'] as Timestamp?)?.toDate(),
      parentMeetingId: map['parentMeetingId'] as String?,
      reminderMinutes: List<int>.from(map['reminderMinutes'] as List<dynamic>? ?? [30]),
      reminderType: map['reminderType'] as String? ?? reminderTypeApp,
      reminderEnabled: map['reminderEnabled'] as bool? ?? true,
      lastReminderSentTo: map['lastReminderSentTo'] != null
          ? List<String>.from(map['lastReminderSentTo'] as List<dynamic>)
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp?)?.toDate(),
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
    List<String>? departments,
    List<String>? agenda,
    List<String>? attachments,
    List<MeetingNote>? notes,
    List<MeetingDecision>? decisions,
    MeetingMinutes? minutes,
    String? status,
    bool? isOnline,
    String? meetingPlatform,
    String? meetingLink,
    String? location,
    bool? isRecurring,
    String? recurrencePattern,
    int? recurrenceInterval,
    List<int>? recurrenceWeekDays,
    String? recurrenceEndType,
    int? recurrenceOccurrences,
    DateTime? recurrenceEndDate,
    String? parentMeetingId,
    List<int>? reminderMinutes,
    String? reminderType,
    bool? reminderEnabled,
    List<String>? lastReminderSentTo,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      organizerId: organizerId ?? this.organizerId,
      participants: participants ?? this.participants,
      departments: departments ?? this.departments,
      agenda: agenda ?? this.agenda,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      decisions: decisions ?? this.decisions,
      minutes: minutes ?? this.minutes,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      meetingPlatform: meetingPlatform ?? this.meetingPlatform,
      meetingLink: meetingLink ?? this.meetingLink,
      location: location ?? this.location,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceWeekDays: recurrenceWeekDays ?? this.recurrenceWeekDays,
      recurrenceEndType: recurrenceEndType ?? this.recurrenceEndType,
      recurrenceOccurrences: recurrenceOccurrences ?? this.recurrenceOccurrences,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      parentMeetingId: parentMeetingId ?? this.parentMeetingId,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      reminderType: reminderType ?? this.reminderType,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      lastReminderSentTo: lastReminderSentTo ?? this.lastReminderSentTo,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  // Toplantı durumları
  static const String statusScheduled = 'scheduled';
  static const String statusOngoing = 'ongoing';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

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
        return 'Bilinmiyor';
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case statusScheduled:
        return Colors.blue;
      case statusOngoing:
        return Colors.green;
      case statusCompleted:
        return Colors.purple;
      case statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Toplantı platformları
  static const String platformZoom = 'zoom';
  static const String platformMeet = 'meet';
  static const String platformTeams = 'teams';
  static const String platformSkype = 'skype';

  static String getPlatformTitle(String platform) {
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
        return 'Diğer';
    }
  }

  // Tekrarlama desenleri
  static const String recurrenceDaily = 'daily';
  static const String recurrenceWeekly = 'weekly';
  static const String recurrenceMonthly = 'monthly';
  static const String recurrenceCustom = 'custom';

  // Haftanın günleri
  static const List<String> weekDays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];

  // Tekrarlama sonu tipleri
  static const String endNever = 'never';
  static const String endAfterOccurrences = 'after_occurrences';
  static const String endOnDate = 'on_date';

  // Tekrarlama başlıkları
  static String getRecurrenceTitle(String pattern) {
    switch (pattern) {
      case recurrenceDaily:
        return 'Her Gün';
      case recurrenceWeekly:
        return 'Her Hafta';
      case recurrenceMonthly:
        return 'Her Ay';
      case recurrenceCustom:
        return 'Özel';
      default:
        return 'Tekrarlama Yok';
    }
  }

  // Sonraki tekrarlama tarihini hesapla
  DateTime? getNextOccurrence(DateTime currentDate) {
    if (!isRecurring) return null;

    switch (recurrencePattern) {
      case recurrenceDaily:
        return currentDate.add(Duration(days: recurrenceInterval ?? 1));
      
      case recurrenceWeekly:
        if (recurrenceWeekDays == null || recurrenceWeekDays!.isEmpty) {
          return currentDate.add(Duration(days: (recurrenceInterval ?? 1) * 7));
        }

        // Sonraki uygun günü bul
        var nextDate = currentDate.add(const Duration(days: 1));
        while (!recurrenceWeekDays!.contains(nextDate.weekday)) {
          nextDate = nextDate.add(const Duration(days: 1));
        }
        return nextDate;
      
      case recurrenceMonthly:
        var nextDate = DateTime(
          currentDate.year,
          currentDate.month + (recurrenceInterval ?? 1),
          currentDate.day,
        );
        
        // Ay sonunu kontrol et
        while (nextDate.month > currentDate.month + (recurrenceInterval ?? 1)) {
          nextDate = nextDate.subtract(const Duration(days: 1));
        }
        return nextDate;
      
      default:
        return null;
    }
  }

  // Tekrarlama sonu kontrolü
  bool isRecurrenceEnded(DateTime date) {
    if (!isRecurring) return true;

    switch (recurrenceEndType) {
      case endNever:
        return false;
      
      case endAfterOccurrences:
        if (recurrenceOccurrences == null) return true;
        final occurrenceCount = getOccurrenceCount(date);
        return occurrenceCount >= recurrenceOccurrences!;
      
      case endOnDate:
        if (recurrenceEndDate == null) return true;
        return date.isAfter(recurrenceEndDate!);
      
      default:
        return true;
    }
  }

  // Tekrarlama sayısını hesapla
  int getOccurrenceCount(DateTime date) {
    if (!isRecurring) return 1;

    final difference = date.difference(startTime);
    switch (recurrencePattern) {
      case recurrenceDaily:
        return (difference.inDays / (recurrenceInterval ?? 1)).ceil();
      
      case recurrenceWeekly:
        if (recurrenceWeekDays == null || recurrenceWeekDays!.isEmpty) {
          return (difference.inDays / ((recurrenceInterval ?? 1) * 7)).ceil();
        }
        
        var count = 0;
        var currentDate = startTime;
        while (currentDate.isBefore(date)) {
          if (recurrenceWeekDays!.contains(currentDate.weekday)) {
            count++;
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }
        return count;
      
      case recurrenceMonthly:
        return (difference.inDays / (30 * (recurrenceInterval ?? 1))).ceil();
      
      default:
        return 1;
    }
  }

  // Tekrarlama açıklaması
  String getRecurrenceDescription() {
    if (!isRecurring) return 'Tekrarlanmıyor';

    final pattern = getRecurrenceTitle(recurrencePattern ?? '');
    final interval = recurrenceInterval ?? 1;

    String description = '';
    switch (recurrencePattern) {
      case recurrenceDaily:
        description = interval == 1 ? 'Her gün' : 'Her $interval günde bir';
        break;
      
      case recurrenceWeekly:
        if (recurrenceWeekDays == null || recurrenceWeekDays!.isEmpty) {
          description = interval == 1 ? 'Her hafta' : 'Her $interval haftada bir';
        } else {
          final days = recurrenceWeekDays!
              .map((day) => weekDays[day - 1])
              .join(', ');
          description = interval == 1
              ? 'Her hafta: $days'
              : 'Her $interval haftada bir: $days';
        }
        break;
      
      case recurrenceMonthly:
        description = interval == 1 ? 'Her ay' : 'Her $interval ayda bir';
        break;
      
      default:
        description = pattern;
    }

    switch (recurrenceEndType) {
      case endAfterOccurrences:
        description += ' (${recurrenceOccurrences ?? 0} kez)';
        break;
      
      case endOnDate:
        if (recurrenceEndDate != null) {
          description += ' (${recurrenceEndDate!.day}/${recurrenceEndDate!.month}/${recurrenceEndDate!.year} tarihine kadar)';
        }
        break;
    }

    return description;
  }

  // Hatırlatma süreleri (dakika)
  static const List<int> reminderTimes = [5, 15, 30, 60, 1440]; // 5dk, 15dk, 30dk, 1sa, 1gün

  // Hatırlatma türleri
  static const String reminderTypeApp = 'app';
  static const String reminderTypeEmail = 'email';
  static const String reminderTypeBoth = 'both';

  // Hatırlatma ayarları
  final List<int> reminderMinutes; // Toplantıdan kaç dakika önce hatırlatılacak
  final String reminderType; // app, email, both
  final bool reminderEnabled; // Hatırlatma aktif mi?
  final List<String>? lastReminderSentTo; // Son hatırlatma gönderilen kullanıcılar

  MeetingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.organizerId,
    required this.participants,
    required this.departments,
    this.agenda = const [],
    this.attachments = const [],
    this.notes = const [],
    this.decisions = const [],
    this.minutes,
    this.status = statusScheduled,
    this.isOnline = false,
    this.meetingPlatform,
    this.meetingLink,
    this.location = '',
    this.isRecurring = false,
    this.recurrencePattern,
    this.recurrenceInterval,
    this.recurrenceWeekDays,
    this.recurrenceEndType,
    this.recurrenceOccurrences,
    this.recurrenceEndDate,
    this.parentMeetingId,
    this.reminderMinutes = const [30], // Varsayılan olarak 30 dakika önce
    this.reminderType = reminderTypeApp,
    this.reminderEnabled = true,
    this.lastReminderSentTo,
    required this.createdAt,
    this.lastUpdatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'organizerId': organizerId,
      'participants': participants.map((p) => p.toMap()).toList(),
      'departments': departments,
      'agenda': agenda,
      'attachments': attachments,
      'notes': notes.map((n) => n.toMap()).toList(),
      'decisions': decisions.map((d) => d.toMap()).toList(),
      'minutes': minutes?.toMap(),
      'status': status,
      'isOnline': isOnline,
      'meetingPlatform': meetingPlatform,
      'meetingLink': meetingLink,
      'location': location,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceWeekDays': recurrenceWeekDays,
      'recurrenceEndType': recurrenceEndType,
      'recurrenceOccurrences': recurrenceOccurrences,
      'recurrenceEndDate':
          recurrenceEndDate != null ? Timestamp.fromDate(recurrenceEndDate!) : null,
      'parentMeetingId': parentMeetingId,
      'reminderMinutes': reminderMinutes,
      'reminderType': reminderType,
      'reminderEnabled': reminderEnabled,
      'lastReminderSentTo': lastReminderSentTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt':
          lastUpdatedAt != null ? Timestamp.fromDate(lastUpdatedAt!) : null,
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
      participants: List<MeetingParticipant>.from(
        (map['participants'] as List<dynamic>).map(
          (x) => MeetingParticipant.fromMap(x as Map<String, dynamic>),
        ),
      ),
      departments: List<String>.from(map['departments'] as List<dynamic>),
      agenda: List<String>.from(map['agenda'] as List<dynamic>? ?? []),
      attachments: List<String>.from(map['attachments'] as List<dynamic>? ?? []),
      notes: List<MeetingNote>.from(
        (map['notes'] as List<dynamic>? ?? []).map(
          (x) => MeetingNote.fromMap(x as Map<String, dynamic>),
        ),
      ),
      decisions: List<MeetingDecision>.from(
        (map['decisions'] as List<dynamic>? ?? []).map(
          (x) => MeetingDecision.fromMap(x as Map<String, dynamic>),
        ),
      ),
      minutes: map['minutes'] != null
          ? MeetingMinutes.fromMap(map['minutes'] as Map<String, dynamic>)
          : null,
      status: map['status'] as String? ?? statusScheduled,
      isOnline: map['isOnline'] as bool? ?? false,
      meetingPlatform: map['meetingPlatform'] as String?,
      meetingLink: map['meetingLink'] as String?,
      location: map['location'] as String? ?? '',
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrencePattern: map['recurrencePattern'] as String?,
      recurrenceInterval: map['recurrenceInterval'] as int?,
      recurrenceWeekDays: map['recurrenceWeekDays'] != null
          ? List<int>.from(map['recurrenceWeekDays'] as List<dynamic>)
          : null,
      recurrenceEndType: map['recurrenceEndType'] as String?,
      recurrenceOccurrences: map['recurrenceOccurrences'] as int?,
      recurrenceEndDate:
          (map['recurrenceEndDate'] as Timestamp?)?.toDate(),
      parentMeetingId: map['parentMeetingId'] as String?,
      reminderMinutes: List<int>.from(map['reminderMinutes'] as List<dynamic>? ?? [30]),
      reminderType: map['reminderType'] as String? ?? reminderTypeApp,
      reminderEnabled: map['reminderEnabled'] as bool? ?? true,
      lastReminderSentTo: map['lastReminderSentTo'] != null
          ? List<String>.from(map['lastReminderSentTo'] as List<dynamic>)
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp?)?.toDate(),
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
    List<String>? departments,
    List<String>? agenda,
    List<String>? attachments,
    List<MeetingNote>? notes,
    List<MeetingDecision>? decisions,
    MeetingMinutes? minutes,
    String? status,
    bool? isOnline,
    String? meetingPlatform,
    String? meetingLink,
    String? location,
    bool? isRecurring,
    String? recurrencePattern,
    int? recurrenceInterval,
    List<int>? recurrenceWeekDays,
    String? recurrenceEndType,
    int? recurrenceOccurrences,
    DateTime? recurrenceEndDate,
    String? parentMeetingId,
    List<int>? reminderMinutes,
    String? reminderType,
    bool? reminderEnabled,
    List<String>? lastReminderSentTo,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      organizerId: organizerId ?? this.organizerId,
      participants: participants ?? this.participants,
      departments: departments ?? this.departments,
      agenda: agenda ?? this.agenda,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      decisions: decisions ?? this.decisions,
      minutes: minutes ?? this.minutes,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      meetingPlatform: meetingPlatform ?? this.meetingPlatform,
      meetingLink: meetingLink ?? this.meetingLink,
      location: location ?? this.location,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceWeekDays: recurrenceWeekDays ?? this.recurrenceWeekDays,
      recurrenceEndType: recurrenceEndType ?? this.recurrenceEndType,
      recurrenceOccurrences: recurrenceOccurrences ?? this.recurrenceOccurrences,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      parentMeetingId: parentMeetingId ?? this.parentMeetingId,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      reminderType: reminderType ?? this.reminderType,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      lastReminderSentTo: lastReminderSentTo ?? this.lastReminderSentTo,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  // Hatırlatma başlıkları
  static String getReminderTypeTitle(String type) {
    switch (type) {
      case reminderTypeApp:
        return 'Uygulama Bildirimi';
      case reminderTypeEmail:
        return 'E-posta';
      case reminderTypeBoth:
        return 'Uygulama ve E-posta';
      default:
        return 'Bilinmeyen';
    }
  }

  // Hatırlatma süresini formatla
  static String formatReminderTime(int minutes) {
    if (minutes >= 1440) {
      final days = minutes ~/ 1440;
      return '$days gün önce';
    }
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      return '$hours saat önce';
    }
    return '$minutes dakika önce';
  }

  // Sonraki hatırlatma zamanını hesapla
  DateTime? getNextReminderTime() {
    if (!reminderEnabled || reminderMinutes.isEmpty) return null;

    final now = DateTime.now();
    if (startTime.isBefore(now)) return null;

    for (final minutes in reminderMinutes) {
      final reminderTime = startTime.subtract(Duration(minutes: minutes));
      if (reminderTime.isAfter(now)) {
        return reminderTime;
      }
    }

    return null;
  }

  // Hatırlatma gönderildi mi kontrol et
  bool isReminderSentTo(String userId) {
    return lastReminderSentTo?.contains(userId) ?? false;
  }
} 
} 