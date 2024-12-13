import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingParticipant {
  final String id;
  final String meetingId;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime? respondedAt;
  final Map<String, dynamic>? metadata;

  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusDeclined = 'declined';
  static const String statusTentative = 'tentative';

  static const String roleOrganizer = 'organizer';
  static const String roleRequired = 'required';
  static const String roleOptional = 'optional';

  MeetingParticipant({
    required this.id,
    required this.meetingId,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.status = statusPending,
    this.respondedAt,
    this.metadata,
  });

  factory MeetingParticipant.fromFirestore(Map<String, dynamic> data) {
    return MeetingParticipant(
      id: data['id'] ?? '',
      meetingId: data['meetingId'] ?? '',
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? roleRequired,
      status: data['status'] ?? statusPending,
      respondedAt: data['respondedAt'] != null ? (data['respondedAt'] as Timestamp).toDate() : null,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meetingId': meetingId,
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'metadata': metadata,
    };
  }

  bool isPending() => status == statusPending;
  bool isAccepted() => status == statusAccepted;
  bool isDeclined() => status == statusDeclined;
  bool isTentative() => status == statusTentative;

  bool isOrganizer() => role == roleOrganizer;
  bool isRequired() => role == roleRequired;
  bool isOptional() => role == roleOptional;
}
