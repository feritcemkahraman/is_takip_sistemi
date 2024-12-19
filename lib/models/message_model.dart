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
  final String? attachment;
  final DateTime createdAt;
  final bool isRead;
  final String type;
  final bool isDeleted;
  final bool isSystemMessage;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.attachment,
    required this.createdAt,
    this.isRead = false,
    this.type = 'text',
    this.isDeleted = false,
    this.isSystemMessage = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'attachment': attachment,
      'createdAt': createdAt,
      'isRead': isRead,
      'type': type,
      'isDeleted': isDeleted,
      'isSystemMessage': isSystemMessage,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      attachment: map['attachment'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'text',
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
} 