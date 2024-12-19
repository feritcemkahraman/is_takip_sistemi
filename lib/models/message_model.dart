import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  static const String typeText = 'text';
  static const String typeImage = 'image';
  static const String typeFile = 'file';
  static const String typeVoice = 'voice';
  static const String typeVideo = 'video';

  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final String? attachment;
  final bool isDeleted;
  final bool isSystemMessage;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.attachment,
    this.isDeleted = false,
    this.isSystemMessage = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? typeText,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt']))
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      attachment: map['attachment'],
      isDeleted: map['isDeleted'] ?? false,
      isSystemMessage: map['isSystemMessage'] ?? false,
    );
  }

  factory MessageModel.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? typeText,
      createdAt: (data['timestamp'] ?? data['createdAt'])?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      attachment: data['attachment'],
      isDeleted: data['isDeleted'] ?? false,
      isSystemMessage: data['isSystemMessage'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'attachment': attachment,
      'isDeleted': isDeleted,
      'isSystemMessage': isSystemMessage,
    };
  }
} 