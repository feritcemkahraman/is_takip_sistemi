import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String type;
  final DateTime createdAt;
  final List<String>? readBy;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.readBy,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'readBy': readBy,
      'metadata': metadata,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'text',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      readBy: map['readBy'] != null ? List<String>.from(map['readBy']) : null,
      metadata: map['metadata'],
    );
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    String? type,
    DateTime? createdAt,
    List<String>? readBy,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
      metadata: metadata ?? this.metadata,
    );
  }
} 