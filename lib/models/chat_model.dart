import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart';

class ChatModel {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final List<String> participants;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;

  ChatModel({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'avatar': avatar,
      'participants': participants,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessageSenderId': lastMessageSenderId,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      avatar: map['avatar'],
      participants: List<String>.from(map['participants'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.parse(map['lastMessageTime'])
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
    );
  }

  ChatModel copyWith({
    String? id,
    String? name,
    String? description,
    String? avatar,
    List<String>? participants,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
  }) {
    return ChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
    );
  }
} 