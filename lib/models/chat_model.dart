import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart';

class ChatModel {
  final String id;
  final String name;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isGroup;
  final String createdBy;
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.name,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isGroup = false,
    required this.createdBy,
    required this.createdAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] is Timestamp 
              ? (map['lastMessageTime'] as Timestamp).toDate()
              : DateTime.parse(map['lastMessageTime']))
          : null,
      unreadCount: map['unreadCount'] ?? 0,
      isGroup: map['isGroup'] ?? false,
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt']))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'isGroup': isGroup,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 