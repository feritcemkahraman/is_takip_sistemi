import 'package:cloud_firestore/cloud_firestore.dart';
import 'meeting_participant.dart';
import 'meeting_decision.dart';
import 'meeting_minutes.dart';

class MeetingModel {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String platform;
  final String meetingUrl;
  final String organizerId;
  final String status;
  final List<String> agenda;
  final List<MeetingParticipant> participants;
  final List<MeetingDecision> decisions;
  final List<MeetingMinutes> minutes;
  final List<String> attachments;
  final Map<String, dynamic>? metadata;
  final bool isRecurring;
  final Map<String, dynamic>? recurrenceRule;

  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  static const String platformTeams = 'teams';
  static const String platformZoom = 'zoom';
  static const String platformMeet = 'meet';
  static const String platformOnsite = 'onsite';

  static const List<int> reminderTimes = [0, 5, 10, 15, 30, 60, 120, 1440]; // dakika cinsinden hatırlatıcılar

  static String formatReminderTime(int minutes) {
    if (minutes == 0) return 'Toplantı başlangıcında';
    if (minutes == 1440) return '1 gün önce';
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      return '$hours saat önce';
    }
    return '$minutes dakika önce';
  }

  MeetingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.platform,
    required this.meetingUrl,
    required this.organizerId,
    required this.status,
    required this.agenda,
    required this.participants,
    required this.decisions,
    required this.minutes,
    this.attachments = const [],
    this.metadata,
    this.isRecurring = false,
    this.recurrenceRule,
  });

  factory MeetingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MeetingModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      platform: data['platform'] ?? platformOnsite,
      meetingUrl: data['meetingUrl'] ?? '',
      organizerId: data['organizerId'] ?? '',
      status: data['status'] ?? statusPending,
      agenda: List<String>.from(data['agenda'] ?? []),
      participants: (data['participants'] as List<dynamic>? ?? [])
          .map((p) => MeetingParticipant.fromFirestore(Map<String, dynamic>.from(p)))
          .toList(),
      decisions: (data['decisions'] as List<dynamic>? ?? [])
          .map((d) => MeetingDecision.fromFirestore(Map<String, dynamic>.from(d)))
          .toList(),
      minutes: (data['minutes'] as List<dynamic>? ?? [])
          .map((m) => MeetingMinutes.fromFirestore(Map<String, dynamic>.from(m)))
          .toList(),
      attachments: List<String>.from(data['attachments'] ?? []),
      metadata: data['metadata'],
      isRecurring: data['isRecurring'] ?? false,
      recurrenceRule: data['recurrenceRule'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'platform': platform,
      'meetingUrl': meetingUrl,
      'organizerId': organizerId,
      'status': status,
      'agenda': agenda,
      'participants': participants.map((participant) => participant.toFirestore()).toList(),
      'decisions': decisions.map((decision) => decision.toFirestore()).toList(),
      'minutes': minutes.map((minute) => minute.toFirestore()).toList(),
      'attachments': attachments,
      'metadata': metadata,
      'isRecurring': isRecurring,
      'recurrenceRule': recurrenceRule,
    };
  }

  bool isPending() => status == statusPending;
  bool isConfirmed() => status == statusConfirmed;
  bool isInProgress() => status == statusInProgress;
  bool isCompleted() => status == statusCompleted;
  bool isCancelled() => status == statusCancelled;

  bool isOnsite() => platform == platformOnsite;
  bool isOnline() => platform != platformOnsite;

  bool hasAttachments() => attachments.isNotEmpty;
  bool hasDecisions() => decisions.isNotEmpty;
  bool hasMinutes() => minutes.isNotEmpty;

  Duration getDuration() => endTime.difference(startTime);
  bool isOverdue() => DateTime.now().isAfter(endTime) && status != statusCompleted;

  String getParticipantStatus(String userId) {
    final participant = participants.firstWhere(
      (p) => p.userId == userId,
      orElse: () => MeetingParticipant(
        id: '',
        meetingId: id,
        userId: userId,
        name: '',
        email: '',
        role: MeetingParticipant.roleRequired,
      ),
    );
    return participant.status;
  }

  bool canEdit(String userId) {
    return organizerId == userId || participants.any((p) => p.userId == userId && p.isOrganizer());
  }

  bool canDelete(String userId) {
    return organizerId == userId;
  }

  bool canAddParticipant(String userId) {
    return canEdit(userId);
  }

  bool canRemoveParticipant(String userId) {
    return canEdit(userId);
  }

  bool canAddDecision(String userId) {
    return participants.any((p) => p.userId == userId && p.isAccepted());
  }

  bool canAddMinutes(String userId) {
    return participants.any((p) => p.userId == userId && p.isAccepted());
  }

  bool canAddAttachment(String userId) {
    return participants.any((p) => p.userId == userId && p.isAccepted());
  }

  MeetingParticipant? get organizer {
    try {
      return participants.firstWhere(
        (p) => p.userId == organizerId,
      );
    } catch (e) {
      return null;
    }
  }
}