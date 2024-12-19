import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';

class ChatModel {
  final String id;
  final String name;
  final List<String> participants;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isGroup;
  final String? avatar;
  final String? description;
  final List<String> mutedBy;
  final UserService _userService;

  bool get isMuted => mutedBy.contains(_userService.currentUser?.id);

  ChatModel({
    required this.id,
    required this.name,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required UserService userService,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isGroup = false,
    this.avatar,
    this.description,
    this.mutedBy = const [],
  }) : _userService = userService;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'participants': participants,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'isGroup': isGroup,
      'avatar': avatar,
      'description': description,
      'mutedBy': mutedBy,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, {required UserService userService}) {
    return ChatModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] is Timestamp
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: map['unreadCount'] ?? 0,
      isGroup: map['isGroup'] ?? false,
      avatar: map['avatar'],
      description: map['description'],
      mutedBy: List<String>.from(map['mutedBy'] ?? []),
      userService: userService,
    );
  }
} 