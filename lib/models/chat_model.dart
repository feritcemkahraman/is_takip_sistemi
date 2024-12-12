import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart';

class ChatModel {
  final String id;
  final String type;
  final List<String> participants;
  final MessageModel? lastMessage;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? name;
  final String? description;
  final String? avatar;
  final String? createdBy;
  final Map<String, String> participantNames;

  ChatModel({
    required this.id,
    required this.type,
    required this.participants,
    this.lastMessage,
    Map<String, int>? unreadCount,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    this.description,
    this.avatar,
    this.createdBy,
    Map<String, String>? participantNames,
  })  : this.unreadCount = unreadCount ?? {},
        this.participantNames = participantNames ?? {};

  // Sohbet tipleri
  static const String typePrivate = 'private';
  static const String typeGroup = 'group';
  static const String typeTask = 'task';
  static const String typeMeeting = 'meeting';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'participants': participants,
      'lastMessage': lastMessage?.toMap(),
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'name': name,
      'description': description,
      'avatar': avatar,
      'createdBy': createdBy,
      'participantNames': participantNames,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] as String,
      type: map['type'] as String,
      participants: List<String>.from(map['participants']),
      lastMessage: map['lastMessage'] != null
          ? MessageModel.fromMap(map['lastMessage'])
          : null,
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      name: map['name'] as String?,
      description: map['description'] as String?,
      avatar: map['avatar'] as String?,
      createdBy: map['createdBy'] as String?,
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
    );
  }

  ChatModel copyWith({
    String? id,
    String? type,
    List<String>? participants,
    MessageModel? lastMessage,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? description,
    String? avatar,
    String? createdBy,
    Map<String, String>? participantNames,
  }) {
    return ChatModel(
      id: id ?? this.id,
      type: type ?? this.type,
      participants: participants ?? List.from(this.participants),
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? Map.from(this.unreadCount),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      createdBy: createdBy ?? this.createdBy,
      participantNames: participantNames ?? Map.from(this.participantNames),
    );
  }

  // Yardımcı metodlar
  bool get isPrivateChat => type == typePrivate;
  bool get isGroupChat => type == typeGroup;
  bool get isTaskChat => type == typeTask;
  bool get isMeetingChat => type == typeMeeting;

  String getChatName(String currentUserId) {
    if (isPrivateChat) {
      final otherUserId = participants.firstWhere((id) => id != currentUserId);
      return participantNames[otherUserId] ?? 'Bilinmeyen Kullanıcı';
    }
    return name ?? 'İsimsiz Sohbet';
  }

  String getChatAvatar(String currentUserId) {
    if (isPrivateChat) {
      final otherUserId = participants.firstWhere((id) => id != currentUserId);
      return avatar ?? 'assets/images/default_avatar.png';
    }
    return avatar ?? 'assets/images/default_group.png';
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  bool hasUnreadMessages(String userId) {
    return getUnreadCount(userId) > 0;
  }

  List<String> getOtherParticipants(String currentUserId) {
    return participants.where((id) => id != currentUserId).toList();
  }
} 